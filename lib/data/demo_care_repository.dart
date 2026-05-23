import 'package:image_picker/image_picker.dart';

import '../core/ids.dart';
import '../models/care_models.dart';
import 'care_repository.dart';

class DemoCareRepository implements CareRepository {
  DemoCareRepository() {
    final now = DateTime.now();
    _shift = ShiftAssignment(
      id: 'shift-1001',
      staffId: staffUser.id,
      clientId: client.id,
      startTime: DateTime(now.year, now.month, now.day, 7),
      endTime: DateTime(now.year, now.month, now.day, 15),
      serviceLocation: 'Harbourview Supported Living, Suite 12',
      assignedLatitude: -33.8688,
      assignedLongitude: 151.2093,
    );
    _progressNotes.add(
      ProgressNote(
        id: 'note-seed',
        staffId: staffUser.id,
        clientId: client.id,
        shiftSummary: 'Morning routine completed with calm engagement.',
        activities: 'Short garden walk and music session.',
        mealsFluids:
            'Breakfast completed. Fluids encouraged throughout morning.',
        personalCare: 'One-person assistance for shower and dressing.',
        moodBehaviour: 'Settled, positive response to quiet prompts.',
        communication: 'Used simple choices and visual schedule.',
        followUp: 'Monitor fatigue after lunch.',
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
    );
    _hazards.add(
      HazardReport(
        id: 'hazard-seed',
        staffId: staffUser.id,
        clientId: client.id,
        hazardType: 'Trip hazard',
        location: 'Hallway near laundry',
        riskLevel: 'Medium',
        description: 'Power cable crossing walking path.',
        actionTaken: 'Moved cable aside and notified maintenance.',
        status: ReportStatus.actionRequired,
        createdAt: now.subtract(const Duration(hours: 1, minutes: 20)),
      ),
    );
  }

  static const staffUser = AppUser(
    id: 'staff-1',
    fullName: 'Mia Thompson',
    email: 'staff@caresnap.test',
    role: UserRole.staff,
    position: 'Disability Support Worker',
    facilityId: 'harbourview-care',
  );

  static const adminUser = AppUser(
    id: 'admin-1',
    fullName: 'Jordan Lee',
    email: 'admin@caresnap.test',
    role: UserRole.admin,
    position: 'Care Coordinator',
    facilityId: 'harbourview-care',
  );

  static const client = ClientProfile(
    id: 'client-1',
    fullName: 'Avery Nguyen',
    roomNumber: 'Room 12',
    address: 'Harbourview Supported Living, Sydney NSW',
    careNeeds:
        'Personal care support, meal prompting, community access, and low-stimulation routines.',
    mobilityStatus:
        'Walks independently indoors. Supervision required on stairs and wet surfaces.',
    communicationNeeds:
        'Prefers short sentences, visual choices, and extra response time.',
    riskNotes:
        'Falls risk during fatigue. Sensory overload can increase agitation in noisy areas.',
    emergencyContact: 'Taylor Nguyen, 0400 111 222',
  );

  late ShiftAssignment _shift;
  final List<ProgressNote> _progressNotes = [];
  final List<IncidentReport> _incidents = [];
  final List<HazardReport> _hazards = [];
  final List<BehaviourChart> _charts = [];
  final List<CheckInRecord> _checkIns = [];
  final List<ShiftTask> _tasks = [];
  final Map<String, _DemoStaffCredential> _createdStaff = {};

  @override
  bool get isFirebaseBacked => false;

  @override
  Future<AppUser> signIn(String email, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    final normalised = email.trim().toLowerCase();
    if (normalised == staffUser.email && password == 'password123') {
      return staffUser;
    }
    if (normalised == adminUser.email && password == 'admin123') {
      return adminUser;
    }
    final createdStaff = _createdStaff[normalised];
    if (createdStaff != null && createdStaff.password == password) {
      return createdStaff.user;
    }
    throw StateError(
      'Use staff@caresnap.test / password123 or admin@caresnap.test / admin123.',
    );
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<AppUser> createStaffAccount({
    required String fullName,
    required String email,
    required String password,
    required String position,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final staff = AppUser(
      id: appUuid.v4(),
      fullName: fullName.trim(),
      email: email.trim().toLowerCase(),
      role: UserRole.staff,
      position: position.trim().isEmpty
          ? 'Disability Support Worker'
          : position.trim(),
      facilityId: 'harbourview-care',
    );
    _createdStaff[staff.email] = _DemoStaffCredential(
      user: staff,
      password: password,
    );
    return staff;
  }

  @override
  Future<ShiftAssignment?> getTodaysShift(String staffId) async {
    if (staffId == staffUser.id) return _shift;
    return null;
  }

  @override
  Future<ClientProfile> getClient(String clientId) async => client;

  @override
  Future<List<ShiftTask>> getShiftTasks(String shiftId) async {
    final tasks = _tasks.where((task) => task.shiftId == shiftId).toList()
      ..sort((a, b) {
        if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
        return a.createdAt.compareTo(b.createdAt);
      });
    return tasks;
  }

  @override
  Future<void> addShiftTask(ShiftTask task) async {
    _tasks.add(task);
  }

  @override
  Future<ShiftTask> updateShiftTask(ShiftTask task) async {
    final index = _tasks.indexWhere((item) => item.id == task.id);
    if (index == -1) {
      _tasks.add(task);
    } else {
      _tasks[index] = task;
    }
    return task;
  }

  @override
  Future<List<ProgressNote>> getProgressNotes(String clientId) async {
    final notes = _progressNotes
        .where((note) => note.clientId == clientId)
        .toList();
    notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return notes;
  }

  @override
  Future<List<ReportSummary>> getReports({String? staffId}) async {
    final reports = <ReportSummary>[
      ..._incidents.map(
        (report) => ReportSummary(
          id: report.id,
          collection: 'incidentReports',
          title: 'Incident: ${report.incidentType}',
          subtitle: report.description,
          staffId: report.staffId,
          clientId: report.clientId,
          status: report.status,
          createdAt: report.createdAt,
          staffName: _staffName(report.staffId),
          clientName: _clientName(report.clientId),
          details: {
            'Report type': report.incidentType,
            'Description': report.description,
            'Injury observed': report.injuryObserved,
            'Action taken': report.actionTaken,
            'Person informed': report.informedPerson,
            if (report.witnessDetails.isNotEmpty)
              'Witness details': report.witnessDetails,
            if (report.followUp.isNotEmpty) 'Follow-up': report.followUp,
          },
          imageUrl: report.imageUrl,
        ),
      ),
      ..._hazards.map(
        (report) => ReportSummary(
          id: report.id,
          collection: 'hazardReports',
          title: 'Hazard: ${report.hazardType}',
          subtitle: report.location,
          staffId: report.staffId,
          clientId: report.clientId,
          status: report.status,
          createdAt: report.createdAt,
          staffName: _staffName(report.staffId),
          clientName: _clientName(report.clientId),
          details: {
            'Report type': report.hazardType,
            'Location': report.location,
            'Risk level': report.riskLevel,
            'Description': report.description,
            'Action taken': report.actionTaken,
          },
          imageUrl: report.imageUrl,
        ),
      ),
      ..._charts.map(
        (chart) => ReportSummary(
          id: chart.id,
          collection: 'behaviourCharts',
          title: 'Behaviour chart',
          subtitle: chart.behaviourObserved,
          staffId: chart.staffId,
          clientId: chart.clientId,
          status: ReportStatus.newReport,
          createdAt: chart.createdAt,
          staffName: _staffName(chart.staffId),
          clientName: _clientName(chart.clientId),
          details: {
            'Trigger': chart.trigger,
            'Behaviour observed': chart.behaviourObserved,
            'Staff response': chart.staffResponse,
            'De-escalation': chart.deEscalationStrategy,
            'Outcome': chart.outcome,
            'Mood level': chart.moodLevel,
            if (chart.followUp.isNotEmpty) 'Follow-up': chart.followUp,
          },
        ),
      ),
      ..._progressNotes.map(
        (note) => ReportSummary(
          id: note.id,
          collection: 'progressNotes',
          title: 'Progress note',
          subtitle: note.shiftSummary,
          staffId: note.staffId,
          clientId: note.clientId,
          status: ReportStatus.resolved,
          createdAt: note.createdAt,
          staffName: _staffName(note.staffId),
          clientName: _clientName(note.clientId),
          details: {
            'Shift summary': note.shiftSummary,
            'Activities': note.activities,
            'Meals and fluids': note.mealsFluids,
            'Personal care': note.personalCare,
            'Mood and behaviour': note.moodBehaviour,
            'Communication': note.communication,
            if (note.followUp.isNotEmpty) 'Follow-up': note.followUp,
          },
        ),
      ),
    ];

    final filtered = staffId == null
        ? reports
        : reports.where((report) => report.staffId == staffId).toList();
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return filtered;
  }

  @override
  Future<List<CheckInRecord>> getCheckIns() async {
    final records = [..._checkIns]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return records;
  }

  @override
  Future<ShiftAssignment> saveCheckIn({
    required ShiftAssignment shift,
    required double latitude,
    required double longitude,
    required double distanceMetres,
    required bool verified,
  }) async {
    _shift = shift.copyWith(
      checkInLatitude: latitude,
      checkInLongitude: longitude,
      checkInStatus: verified ? 'Verified' : 'Failed',
      shiftStatus: verified ? 'Started' : 'Scheduled',
    );
    _checkIns.add(
      CheckInRecord(
        id: appUuid.v4(),
        staffId: shift.staffId,
        shiftId: shift.id,
        status: _shift.checkInStatus,
        latitude: latitude,
        longitude: longitude,
        distanceMetres: distanceMetres,
        createdAt: DateTime.now(),
      ),
    );
    return _shift;
  }

  @override
  Future<ShiftAssignment> endShift(ShiftAssignment shift) async {
    _shift = shift.copyWith(shiftStatus: 'Ended');
    return _shift;
  }

  @override
  Future<void> submitProgressNote(ProgressNote note) async {
    _progressNotes.add(note);
  }

  @override
  Future<String?> uploadEvidence(XFile? image, String folder) async {
    if (image == null) return null;
    final bytes = await image.readAsBytes();
    return 'demo://$folder/${image.name}?bytes=${bytes.length}';
  }

  @override
  Future<void> submitIncidentReport(IncidentReport report) async {
    _incidents.add(report);
  }

  @override
  Future<void> submitHazardReport(HazardReport report) async {
    _hazards.add(report);
  }

  @override
  Future<void> submitBehaviourChart(BehaviourChart chart) async {
    _charts.add(chart);
  }

  @override
  Future<void> updateReportStatus({
    required String collection,
    required String id,
    required ReportStatus status,
  }) async {
    if (collection == 'incidentReports') {
      final index = _incidents.indexWhere((report) => report.id == id);
      if (index != -1) {
        final report = _incidents[index];
        _incidents[index] = IncidentReport(
          id: report.id,
          staffId: report.staffId,
          clientId: report.clientId,
          incidentType: report.incidentType,
          description: report.description,
          injuryObserved: report.injuryObserved,
          actionTaken: report.actionTaken,
          informedPerson: report.informedPerson,
          witnessDetails: report.witnessDetails,
          followUp: report.followUp,
          status: status,
          createdAt: report.createdAt,
          imageUrl: report.imageUrl,
        );
      }
    }
    if (collection == 'hazardReports') {
      final index = _hazards.indexWhere((report) => report.id == id);
      if (index != -1) {
        final report = _hazards[index];
        _hazards[index] = HazardReport(
          id: report.id,
          staffId: report.staffId,
          clientId: report.clientId,
          hazardType: report.hazardType,
          location: report.location,
          riskLevel: report.riskLevel,
          description: report.description,
          actionTaken: report.actionTaken,
          status: status,
          createdAt: report.createdAt,
          imageUrl: report.imageUrl,
        );
      }
    }
  }

  String _staffName(String staffId) {
    if (staffId == staffUser.id) return staffUser.fullName;
    return _createdStaff.values
            .where((credential) => credential.user.id == staffId)
            .firstOrNull
            ?.user
            .fullName ??
        'Care team member';
  }

  String _clientName(String clientId) {
    return clientId == client.id ? client.fullName : 'Resident';
  }
}

class _DemoStaffCredential {
  const _DemoStaffCredential({required this.user, required this.password});

  final AppUser user;
  final String password;
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
