import 'package:image_picker/image_picker.dart';

import '../models/care_models.dart';

abstract class CareRepository {
  bool get isFirebaseBacked;

  Future<AppUser> signIn(String email, String password);

  Future<void> signOut();

  Future<AppUser> createStaffAccount({
    required String fullName,
    required String email,
    required String password,
    required String position,
  });

  Future<ShiftAssignment> getTodaysShift(String staffId);

  Future<ClientProfile> getClient(String clientId);

  Future<List<ProgressNote>> getProgressNotes(String clientId);

  Future<List<ReportSummary>> getReports({String? staffId});

  Future<List<CheckInRecord>> getCheckIns();

  Future<ShiftAssignment> saveCheckIn({
    required ShiftAssignment shift,
    required double latitude,
    required double longitude,
    required double distanceMetres,
    required bool verified,
  });

  Future<ShiftAssignment> endShift(ShiftAssignment shift);

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
