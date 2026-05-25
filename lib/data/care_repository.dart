import 'package:image_picker/image_picker.dart';

import '../models/care_models.dart';

abstract class CareRepository {
  bool get isFirebaseBacked;

  Future<AppUser> signIn(String email, String password);

  Future<void> sendPasswordResetEmail(String email);

  Future<void> signOut();

  Future<AppUser> createStaffAccount({
    required String fullName,
    required String email,
    required String password,
    required String position,
  });

  Future<AppUser> updateCurrentUserProfile({
    required String fullName,
    required String position,
    required String facilityId,
  });

  Future<ShiftAssignment?> getTodaysShift(String staffId);

  Future<List<ShiftAssignment>> getStaffShifts({
    required String staffId,
    required DateTime start,
    required DateTime end,
  });

  Future<ClientProfile> getClient(String clientId);

  Future<List<ShiftTask>> getShiftTasks(String shiftId);

  Future<void> addShiftTask(ShiftTask task);

  Future<ShiftTask> updateShiftTask(ShiftTask task);

  Future<List<ProgressNote>> getProgressNotes(String clientId);

  Future<List<ReportSummary>> getReports({String? staffId});

  Future<List<CheckInRecord>> getCheckIns();

  Future<List<StaffDocument>> getStaffDocuments(String staffId);

  Future<String?> uploadStaffDocument(XFile? document, String staffId);

  Future<void> addStaffDocument(StaffDocument document);

  Future<ShiftAssignment> saveCheckIn({
    required ShiftAssignment shift,
    required double latitude,
    required double longitude,
    required double distanceMetres,
    required bool verified,
  });

  Future<void> updateShiftAssignedLocation({
    required String shiftId,
    required double latitude,
    required double longitude,
  });

  Future<ShiftAssignment> endShift(
    ShiftAssignment shift, {
    double? latitude,
    double? longitude,
    double? distanceMetres,
  });

  Future<void> submitProgressNote(ProgressNote note);

  Future<String?> uploadEvidence(XFile? image, String folder);

  Future<void> submitIncidentReport(IncidentReport report);

  Future<void> submitHazardReport(HazardReport report);

  Future<void> submitBehaviourChart(BehaviourChart chart);

  Future<void> updateReportStatus({
    required String collection,
    required String id,
    required ReportStatus status,
  });
}
