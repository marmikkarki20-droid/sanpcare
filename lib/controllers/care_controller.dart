import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../core/error_messages.dart';
import '../core/ids.dart';
import '../data/care_repository.dart';
import '../models/care_models.dart';
import '../services/address_geocoding_service.dart';
import '../services/location_service.dart';

class CareController extends ChangeNotifier {
  CareController(this.repository);

  static const double locationVerificationRadiusMetres = 200;
  static const Duration attendanceGracePeriod = Duration(minutes: 30);

  final CareRepository repository;
  AppUser? user;
  ShiftAssignment? shift;
  ClientProfile? client;
  List<ShiftAssignment> scheduleShifts = [];
  Map<String, ClientProfile> scheduleClients = {};
  List<ShiftTask> shiftTasks = [];
  List<ProgressNote> progressNotes = [];
  List<ReportSummary> reports = [];
  List<CheckInRecord> checkIns = [];
  List<StaffDocument> staffDocuments = [];
  bool isBusy = false;
  String? error;

  bool get isSignedIn => user != null;
  bool get isStaff => user?.role == UserRole.staff;
  bool get isAdmin => user?.role == UserRole.admin;

  Future<void> signIn(String email, String password) async {
    await _guard(() async {
      user = await repository.signIn(email, password);
      if (isStaff) {
        await _loadStaffWorkspace();
      } else {
        reports = await repository.getReports();
        checkIns = await repository.getCheckIns();
      }
    });
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _guard(() async {
      await repository.sendPasswordResetEmail(email);
    });
  }

  Future<void> updateCurrentUserProfile({
    required String fullName,
    required String position,
    required String facilityId,
  }) async {
    await _guard(() async {
      user = await repository.updateCurrentUserProfile(
        fullName: fullName,
        position: position,
        facilityId: facilityId,
      );
    });
  }

  Future<void> signOut() async {
    await repository.signOut();
    user = null;
    shift = null;
    client = null;
    scheduleShifts = [];
    scheduleClients = {};
    shiftTasks = [];
    progressNotes = [];
    reports = [];
    checkIns = [];
    staffDocuments = [];
    error = null;
    notifyListeners();
  }

  Future<void> refresh() async {
    if (user == null) return;
    await _guard(() async {
      if (isStaff) {
        await _loadStaffWorkspace();
      } else {
        reports = await repository.getReports();
        checkIns = await repository.getCheckIns();
      }
    });
  }

  Future<void> _loadStaffWorkspace() async {
    final staffId = user!.id;
    final today = DateTime.now();
    final start = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(const Duration(days: 75));
    final end = DateTime(
      today.year,
      today.month,
      today.day,
    ).add(const Duration(days: 210));

    scheduleShifts = await repository.getStaffShifts(
      staffId: staffId,
      start: start,
      end: end,
    );
    shift = _bestCurrentShift(scheduleShifts);
    shift ??= await repository.getTodaysShift(staffId);
    if (shift != null && !scheduleShifts.any((item) => item.id == shift!.id)) {
      scheduleShifts = [...scheduleShifts, shift!]
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
    }

    scheduleClients = await _clientsFor(scheduleShifts);
    await _loadSelectedShiftDetails();
    reports = await repository.getReports(staffId: staffId);
    staffDocuments = await repository.getStaffDocuments(staffId);
  }

  ShiftAssignment? _bestCurrentShift(List<ShiftAssignment> shifts) {
    if (shifts.isEmpty) return null;
    final threshold = DateTime.now().subtract(const Duration(hours: 12));
    final available =
        shifts
            .where((item) => !item.isEnded && item.endTime.isAfter(threshold))
            .toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));
    if (available.isNotEmpty) return available.first;
    return shifts.last;
  }

  Future<Map<String, ClientProfile>> _clientsFor(
    List<ShiftAssignment> shifts,
  ) async {
    final clients = <String, ClientProfile>{};
    final ids = shifts
        .map((item) => item.clientId)
        .where((id) => id.isNotEmpty);
    for (final clientId in ids.toSet()) {
      clients[clientId] = await repository.getClient(clientId);
    }
    return clients;
  }

  Future<void> _loadSelectedShiftDetails() async {
    final currentShift = shift;
    if (currentShift == null) {
      client = null;
      shiftTasks = [];
      progressNotes = [];
      return;
    }

    client =
        scheduleClients[currentShift.clientId] ??
        await repository.getClient(currentShift.clientId);
    final selectedClient = client;
    if (selectedClient != null) {
      scheduleClients = {
        ...scheduleClients,
        currentShift.clientId: selectedClient,
      };
    }
    shiftTasks = await repository.getShiftTasks(currentShift.id);
    progressNotes = client == null
        ? []
        : await repository.getProgressNotes(client!.id);
  }

  Future<void> selectStaffShift(ShiftAssignment selectedShift) async {
    await _guard(() async {
      shift = selectedShift;
      await _loadSelectedShiftDetails();
    });
  }

  Future<void> addStaffDocument({
    required String title,
    required String category,
    required String notes,
    required String fileUrl,
    required DateTime? expiresAt,
    required XFile? file,
  }) async {
    final currentUser = user;
    if (currentUser == null) return;

    await _guard(() async {
      final uploadedUrl = await repository.uploadStaffDocument(
        file,
        currentUser.id,
      );
      final documentUrl = fileUrl.trim();
      await repository.addStaffDocument(
        StaffDocument(
          id: appUuid.v4(),
          staffId: currentUser.id,
          title: title.trim(),
          category: category.trim().isEmpty ? 'General' : category.trim(),
          status: 'Filed',
          notes: notes.trim(),
          fileName: file?.name,
          fileUrl: uploadedUrl ?? (documentUrl.isEmpty ? null : documentUrl),
          expiresAt: expiresAt,
          createdAt: DateTime.now(),
        ),
      );
      staffDocuments = await repository.getStaffDocuments(currentUser.id);
    });
  }

  Future<CheckInResult> performLiveCheckIn() async {
    final currentShift = shift;
    if (currentShift == null) {
      throw StateError('No shift loaded.');
    }

    return _guardWithResult(() async {
      final blockReason = clockInBlockReason(currentShift);
      if (blockReason != null) throw StateError(blockReason);

      final position = await LocationService.currentPosition();
      return _completeCheckIn(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
      );
    });
  }

  Future<CheckInResult> _completeCheckIn({
    required double latitude,
    required double longitude,
    required double accuracy,
  }) async {
    final currentShift = await _shiftWithAddressCoordinates(shift!);
    final result = _verifyAssignedLocation(
      shift: currentShift,
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
    );

    shift = await repository.saveCheckIn(
      shift: currentShift,
      latitude: latitude,
      longitude: longitude,
      distanceMetres: result.distanceMetres,
      verified: result.verified,
    );
    reports = await repository.getReports(staffId: user!.id);
    notifyListeners();

    return result;
  }

  Future<ShiftAssignment> _shiftWithAddressCoordinates(
    ShiftAssignment currentShift,
  ) async {
    try {
      final coordinates = await AddressGeocodingService.coordinatesForAddress(
        currentShift.serviceLocation,
      );
      final distanceFromStoredCoordinates = Geolocator.distanceBetween(
        coordinates.latitude,
        coordinates.longitude,
        currentShift.assignedLatitude,
        currentShift.assignedLongitude,
      );
      if (distanceFromStoredCoordinates <= 50) return currentShift;

      final updatedShift = currentShift.copyWith(
        assignedLatitude: coordinates.latitude,
        assignedLongitude: coordinates.longitude,
      );
      shift = updatedShift;
      try {
        await repository.updateShiftAssignedLocation(
          shiftId: currentShift.id,
          latitude: coordinates.latitude,
          longitude: coordinates.longitude,
        );
      } catch (_) {
        // Keep the corrected coordinates locally even if the cached shift
        // document cannot be repaired immediately.
      }
      return updatedShift;
    } catch (_) {
      return currentShift;
    }
  }

  Future<CheckInResult> performLiveCheckOut() async {
    final currentShift = shift;
    if (currentShift == null) {
      throw StateError('No shift loaded.');
    }

    return _guardWithResult(() async {
      final blockReason = clockOutBlockReason(currentShift);
      if (blockReason != null) throw StateError(blockReason);

      final position = await LocationService.currentPosition();
      final updatedShift = await _shiftWithAddressCoordinates(currentShift);
      final result = _verifyAssignedLocation(
        shift: updatedShift,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
      );
      if (result.verified) {
        shift = await repository.endShift(
          updatedShift,
          latitude: position.latitude,
          longitude: position.longitude,
          distanceMetres: result.distanceMetres,
        );
        reports = await repository.getReports(staffId: user!.id);
        notifyListeners();
      }
      return result;
    });
  }

  CheckInResult _verifyAssignedLocation({
    required ShiftAssignment shift,
    required double latitude,
    required double longitude,
    required double accuracy,
  }) {
    final distance = Geolocator.distanceBetween(
      latitude,
      longitude,
      shift.assignedLatitude,
      shift.assignedLongitude,
    );
    return CheckInResult(
      verified: distance <= locationVerificationRadiusMetres,
      distanceMetres: distance,
      accuracyMetres: accuracy,
      latitude: latitude,
      longitude: longitude,
    );
  }

  String? attendanceBlockReason(ShiftAssignment shift, {DateTime? at}) {
    if (shift.isEnded) return null;
    if (shift.isCheckedIn && !shift.isEnded) {
      return clockOutBlockReason(shift, at: at);
    }
    return clockInBlockReason(shift, at: at);
  }

  String? clockInBlockReason(ShiftAssignment shift, {DateTime? at}) {
    if (shift.isEnded) return 'This shift has already ended.';
    if (shift.isCheckedIn) return null;

    final now = at ?? DateTime.now();
    if (_isAfterGracePeriod(now, shift.startTime)) {
      return 'Clock in failed because the 30 minute shift window has closed.';
    }
    return null;
  }

  String? clockOutBlockReason(ShiftAssignment shift, {DateTime? at}) {
    if (shift.isEnded) return 'This shift has already ended.';
    if (!shift.isCheckedIn) return 'Start the shift before ending it.';

    final now = at ?? DateTime.now();
    if (_isAfterGracePeriod(now, shift.endTime)) {
      return 'Clock out failed because the 30 minute shift window has closed.';
    }
    return null;
  }

  bool _isAfterGracePeriod(DateTime now, DateTime reference) {
    return now.isAfter(reference.add(attendanceGracePeriod));
  }

  Future<void> endShift() async {
    await performLiveCheckOut();
  }

  Future<void> setShiftTaskCompleted(ShiftTask task, bool isCompleted) async {
    await _guard(() async {
      final updated = await repository.updateShiftTask(
        task.copyWith(
          isCompleted: isCompleted,
          completedAt: isCompleted ? DateTime.now() : null,
          clearCompletedAt: !isCompleted,
        ),
      );
      final index = shiftTasks.indexWhere((item) => item.id == task.id);
      if (index == -1) {
        shiftTasks = [...shiftTasks, updated];
      } else {
        shiftTasks = [
          ...shiftTasks.take(index),
          updated,
          ...shiftTasks.skip(index + 1),
        ];
      }
    });
  }

  Future<void> submitProgressNote({
    required String shiftSummary,
    required String activities,
    required String mealsFluids,
    required String personalCare,
    required String moodBehaviour,
    required String communication,
    required String followUp,
  }) async {
    final note = ProgressNote(
      id: appUuid.v4(),
      staffId: user!.id,
      clientId: client!.id,
      shiftSummary: shiftSummary,
      activities: activities,
      mealsFluids: mealsFluids,
      personalCare: personalCare,
      moodBehaviour: moodBehaviour,
      communication: communication,
      followUp: followUp,
      createdAt: DateTime.now(),
    );
    await _guard(() async {
      await repository.submitProgressNote(note);
      progressNotes = await repository.getProgressNotes(client!.id);
      reports = await repository.getReports(staffId: user!.id);
    });
  }

  Future<void> submitIncident({
    required String incidentType,
    required String description,
    required String injuryObserved,
    required String actionTaken,
    required String informedPerson,
    required String witnessDetails,
    required String followUp,
    required XFile? image,
  }) async {
    await _guard(() async {
      final imageUrl = await repository.uploadEvidence(
        image,
        'incidentReports',
      );
      await repository.submitIncidentReport(
        IncidentReport(
          id: appUuid.v4(),
          staffId: user!.id,
          clientId: client!.id,
          incidentType: incidentType,
          description: description,
          injuryObserved: injuryObserved,
          actionTaken: actionTaken,
          informedPerson: informedPerson,
          witnessDetails: witnessDetails,
          followUp: followUp,
          status: ReportStatus.newReport,
          createdAt: DateTime.now(),
          imageUrl: imageUrl,
        ),
      );
      reports = await repository.getReports(staffId: user!.id);
    });
  }

  Future<void> submitHazard({
    required String hazardType,
    required String location,
    required String riskLevel,
    required String description,
    required String actionTaken,
    required XFile? image,
  }) async {
    await _guard(() async {
      final imageUrl = await repository.uploadEvidence(image, 'hazardReports');
      await repository.submitHazardReport(
        HazardReport(
          id: appUuid.v4(),
          staffId: user!.id,
          clientId: client!.id,
          hazardType: hazardType,
          location: location,
          riskLevel: riskLevel,
          description: description,
          actionTaken: actionTaken,
          status: ReportStatus.newReport,
          createdAt: DateTime.now(),
          imageUrl: imageUrl,
        ),
      );
      reports = await repository.getReports(staffId: user!.id);
    });
  }

  Future<void> submitBehaviourChart({
    required String trigger,
    required String behaviourObserved,
    required String staffResponse,
    required String deEscalationStrategy,
    required String outcome,
    required String moodLevel,
    required String followUp,
  }) async {
    final chart = BehaviourChart(
      id: appUuid.v4(),
      staffId: user!.id,
      clientId: client!.id,
      trigger: trigger,
      behaviourObserved: behaviourObserved,
      staffResponse: staffResponse,
      deEscalationStrategy: deEscalationStrategy,
      outcome: outcome,
      moodLevel: moodLevel,
      followUp: followUp,
      createdAt: DateTime.now(),
    );
    await _guard(() async {
      await repository.submitBehaviourChart(chart);
      reports = await repository.getReports(staffId: user!.id);
    });
  }

  Future<void> updateReportStatus(
    ReportSummary report,
    ReportStatus status,
  ) async {
    await _guard(() async {
      await repository.updateReportStatus(
        collection: report.collection,
        id: report.id,
        status: status,
      );
      reports = await repository.getReports();
      checkIns = await repository.getCheckIns();
    });
  }

  Future<AppUser> createStaffAccount({
    required String fullName,
    required String email,
    required String password,
    required String position,
  }) async {
    if (!isAdmin) {
      throw StateError('Only admin users can create staff logins.');
    }
    return _guardWithResult(() async {
      final staff = await repository.createStaffAccount(
        fullName: fullName,
        email: email,
        password: password,
        position: position,
      );
      reports = await repository.getReports();
      checkIns = await repository.getCheckIns();
      return staff;
    });
  }

  Future<void> _guard(Future<void> Function() action) async {
    isBusy = true;
    error = null;
    notifyListeners();
    try {
      await action();
    } catch (exception) {
      error = friendlyError(exception);
      rethrow;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<T> _guardWithResult<T>(FutureOr<T> Function() action) async {
    isBusy = true;
    error = null;
    notifyListeners();
    try {
      return await action();
    } catch (exception) {
      error = friendlyError(exception);
      rethrow;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }
}

class CheckInResult {
  const CheckInResult({
    required this.verified,
    required this.distanceMetres,
    required this.accuracyMetres,
    required this.latitude,
    required this.longitude,
  });

  final bool verified;
  final double distanceMetres;
  final double accuracyMetres;
  final double latitude;
  final double longitude;
}
