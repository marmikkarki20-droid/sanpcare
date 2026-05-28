import 'package:caresnap/controllers/care_controller.dart';
import 'package:caresnap/data/care_repository.dart';
import 'package:caresnap/models/care_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

class _FakeRepository implements CareRepository {
  @override
  bool get isFirebaseBacked => false;

  @override
  Future<AppUser> signIn(String email, String password) {
    throw UnimplementedError();
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<AppUser> createStaffAccount({
    required String fullName,
    required String email,
    required String password,
    required String position,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppUser> updateCurrentUserProfile({
    required String fullName,
    required String position,
    required String facilityId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ShiftAssignment?> getTodaysShift(String staffId) async => null;

  @override
  Future<List<ShiftAssignment>> getStaffShifts({
    required String staffId,
    required DateTime start,
    required DateTime end,
  }) async => [];

  @override
  Future<ClientProfile> getClient(String clientId) {
    throw UnimplementedError();
  }

  @override
  Future<List<ShiftTask>> getShiftTasks(String shiftId) async => [];

  @override
  Future<void> addShiftTask(ShiftTask task) async {}

  @override
  Future<ShiftTask> updateShiftTask(ShiftTask task) async => task;

  @override
  Future<List<ProgressNote>> getProgressNotes(String clientId) async => [];

  @override
  Future<List<ReportSummary>> getReports({String? staffId}) async => [];

  @override
  Future<List<CheckInRecord>> getCheckIns() async => [];

  @override
  Future<List<StaffDocument>> getStaffDocuments(String staffId) async => [];

  @override
  Future<String?> uploadStaffDocument(XFile? document, String staffId) async =>
      null;

  @override
  Future<void> addStaffDocument(StaffDocument document) async {}

  @override
  Future<ShiftAssignment> saveCheckIn({
    required ShiftAssignment shift,
    required double latitude,
    required double longitude,
    required double distanceMetres,
    required bool verified,
  }) async => shift;

  @override
  Future<void> updateShiftAssignedLocation({
    required String shiftId,
    required double latitude,
    required double longitude,
  }) async {}

  @override
  Future<ShiftAssignment> endShift(
    ShiftAssignment shift, {
    double? latitude,
    double? longitude,
    double? distanceMetres,
  }) async => shift;

  @override
  Future<void> submitProgressNote(ProgressNote note) async {}

  @override
  Future<String?> uploadEvidence(XFile? image, String folder) async => null;

  @override
  Future<void> submitIncidentReport(IncidentReport report) async {}

  @override
  Future<void> submitHazardReport(HazardReport report) async {}

  @override
  Future<void> submitBehaviourChart(BehaviourChart chart) async {}

  @override
  Future<void> updateReportStatus({
    required String collection,
    required String id,
    required ReportStatus status,
  }) async {}
}

void main() {
  late CareController controller;

  setUp(() {
    controller = CareController(_FakeRepository());
  });

  ShiftAssignment shift({
    required DateTime startTime,
    String shiftStatus = 'Scheduled',
  }) {
    return ShiftAssignment(
      id: 'shift-1',
      staffId: 'staff-1',
      clientId: 'client-1',
      startTime: startTime,
      endTime: startTime.add(const Duration(hours: 8)),
      serviceLocation: '1 Test Street',
      assignedLatitude: -33.8688,
      assignedLongitude: 151.2093,
      shiftStatus: shiftStatus,
    );
  }

  test('allows clock in at the 30 minute shift grace period', () {
    final startTime = DateTime(2026, 5, 27, 9);
    final reason = controller.clockInBlockReason(
      shift(startTime: startTime),
      at: startTime.add(CareController.attendanceGracePeriod),
    );

    expect(reason, isNull);
  });

  test('blocks clock in after the 30 minute shift grace period', () {
    final startTime = DateTime(2026, 5, 27, 9);
    final reason = controller.clockInBlockReason(
      shift(startTime: startTime),
      at: startTime.add(const Duration(minutes: 31)),
    );

    expect(reason, contains('Clock in failed'));
  });

  test('blocks clock out after the 30 minute shift grace period', () {
    final startTime = DateTime(2026, 5, 27, 9);
    final currentShift = shift(startTime: startTime, shiftStatus: 'Started');
    final reason = controller.clockOutBlockReason(
      currentShift,
      at: currentShift.endTime.add(const Duration(minutes: 31)),
    );

    expect(reason, contains('Clock out failed'));
  });
}
