import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../core/error_messages.dart';
import '../core/ids.dart';
import '../data/care_repository.dart';
import '../models/care_models.dart';
import '../services/location_service.dart';

class CareController extends ChangeNotifier {
  CareController(this.repository);

  final CareRepository repository;
  AppUser? user;
  ShiftAssignment? shift;
  ClientProfile? client;
  List<ShiftTask> shiftTasks = [];
  List<ProgressNote> progressNotes = [];
  List<ReportSummary> reports = [];
  List<CheckInRecord> checkIns = [];
  bool isBusy = false;
  String? error;

  bool get isSignedIn => user != null;
  bool get isStaff => user?.role == UserRole.staff;
  bool get isAdmin => user?.role == UserRole.admin;

  Future<void> signIn(String email, String password) async {
    await _guard(() async {
      user = await repository.signIn(email, password);
      if (isStaff) {
        shift = await repository.getTodaysShift(user!.id);
        if (shift != null) {
          client = await repository.getClient(shift!.clientId);
          shiftTasks = await repository.getShiftTasks(shift!.id);
          progressNotes = await repository.getProgressNotes(client!.id);
        } else {
          client = null;
          shiftTasks = [];
          progressNotes = [];
        }
        reports = await repository.getReports(staffId: user!.id);
      } else {
        reports = await repository.getReports();
        checkIns = await repository.getCheckIns();
      }
    });
  }

  Future<void> signOut() async {
    await repository.signOut();
    user = null;
    shift = null;
    client = null;
    shiftTasks = [];
    progressNotes = [];
    reports = [];
    checkIns = [];
    error = null;
    notifyListeners();
  }

  Future<void> refresh() async {
    if (user == null) return;
    await _guard(() async {
      if (isStaff) {
        shift = await repository.getTodaysShift(user!.id);
        if (shift == null) {
          client = null;
          shiftTasks = [];
          progressNotes = [];
        } else {
          client = await repository.getClient(shift!.clientId);
          shiftTasks = await repository.getShiftTasks(shift!.id);
          progressNotes = await repository.getProgressNotes(client!.id);
        }
        reports = await repository.getReports(staffId: user!.id);
      } else {
        reports = await repository.getReports();
        checkIns = await repository.getCheckIns();
      }
    });
  }

  Future<CheckInResult> performLiveCheckIn() async {
    final currentShift = shift;
    if (currentShift == null) {
      throw StateError('No shift loaded.');
    }

    return _guardWithResult(() async {
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
    final currentShift = shift!;
    final distance = Geolocator.distanceBetween(
      latitude,
      longitude,
      currentShift.assignedLatitude,
      currentShift.assignedLongitude,
    );
    final verified = distance <= 200;

    shift = await repository.saveCheckIn(
      shift: currentShift,
      latitude: latitude,
      longitude: longitude,
      distanceMetres: distance,
      verified: verified,
    );
    reports = await repository.getReports(staffId: user!.id);
    notifyListeners();

    return CheckInResult(
      verified: verified,
      distanceMetres: distance,
      accuracyMetres: accuracy,
      latitude: latitude,
      longitude: longitude,
    );
  }

  Future<void> endShift() async {
    final currentShift = shift;
    if (currentShift == null) return;
    await _guard(() async {
      shift = await repository.endShift(currentShift);
    });
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
