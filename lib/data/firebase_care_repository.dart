import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../firebase_options.dart';
import '../models/care_models.dart';
import 'care_repository.dart';

class FirebaseCareRepository implements CareRepository {
  FirebaseCareRepository({
    firebase_auth.FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _auth = auth ?? firebase_auth.FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance;

  final firebase_auth.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  @override
  bool get isFirebaseBacked => true;

  @override
  Future<AppUser> signIn(String email, String password) async {
    final normalisedEmail = email.trim().toLowerCase();
    final credential = await _auth.signInWithEmailAndPassword(
      email: normalisedEmail,
      password: password.trim(),
    );
    final authUser = credential.user;
    final userId = authUser?.uid;
    if (userId == null) {
      throw StateError('Firebase did not return a user account.');
    }

    final snapshot = await _firestore.collection('users').doc(userId).get();
    if (!snapshot.exists) {
      throw StateError(
        'This account has not been onboarded in the admin portal.',
      );
    }

    return AppUser.fromFirestore(userId, snapshot.data() ?? {});
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<AppUser> createStaffAccount({
    required String fullName,
    required String email,
    required String password,
    required String position,
  }) async {
    final staffEmail = email.trim().toLowerCase();
    final secondaryAuth = await _staffProvisioningAuth();
    final credential = await secondaryAuth.createUserWithEmailAndPassword(
      email: staffEmail,
      password: password,
    );
    final staffUser = credential.user;
    if (staffUser == null) {
      throw StateError('Firebase did not return the new staff account.');
    }

    await staffUser.updateDisplayName(fullName.trim());
    await secondaryAuth.signOut();

    final profile = <String, dynamic>{
      'fullName': fullName.trim(),
      'email': staffEmail,
      'role': 'staff',
      'position': position.trim().isEmpty
          ? 'Disability Support Worker'
          : position.trim(),
      'facilityId': '',
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': _auth.currentUser?.uid,
    };

    await _firestore.collection('users').doc(staffUser.uid).set(profile);
    return AppUser.fromFirestore(staffUser.uid, profile);
  }

  Future<firebase_auth.FirebaseAuth> _staffProvisioningAuth() async {
    const appName = 'careSnapStaffProvisioning';
    FirebaseApp app;
    try {
      app = Firebase.app(appName);
    } on FirebaseException {
      app = await Firebase.initializeApp(
        name: appName,
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    return firebase_auth.FirebaseAuth.instanceFor(app: app);
  }

  @override
  Future<ShiftAssignment?> getTodaysShift(String staffId) async {
    final snapshot = await _firestore
        .collection('shifts')
        .where('staffId', isEqualTo: staffId)
        .limit(20)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    final now = DateTime.now().subtract(const Duration(hours: 12));
    final shifts =
        snapshot.docs
            .map((doc) => ShiftAssignment.fromFirestore(doc.id, doc.data()))
            .where((shift) => !shift.isEnded)
            .toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));

    for (final shift in shifts) {
      if (shift.endTime.isAfter(now)) return shift;
    }
    return shifts.firstOrNull;
  }

  @override
  Future<ClientProfile> getClient(String clientId) async {
    final doc = await _firestore.collection('clients').doc(clientId).get();
    if (!doc.exists) {
      throw StateError('Client profile could not be found.');
    }
    return ClientProfile.fromFirestore(doc.id, doc.data() ?? {});
  }

  @override
  Future<List<ShiftTask>> getShiftTasks(String shiftId) async {
    final snapshot = await _firestore
        .collection('shiftTasks')
        .where('shiftId', isEqualTo: shiftId)
        .limit(50)
        .get();
    final tasks = snapshot.docs
        .map((doc) => ShiftTask.fromFirestore(doc.id, doc.data()))
        .toList();
    tasks.sort((a, b) {
      if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
      return a.createdAt.compareTo(b.createdAt);
    });
    return tasks;
  }

  @override
  Future<void> addShiftTask(ShiftTask task) async {
    await _firestore.collection('shiftTasks').add(task.toFirestore());
  }

  @override
  Future<ShiftTask> updateShiftTask(ShiftTask task) async {
    await _firestore.collection('shiftTasks').doc(task.id).update({
      'isCompleted': task.isCompleted,
      'completedAt': task.completedAt == null
          ? null
          : Timestamp.fromDate(task.completedAt!),
    });
    return task;
  }

  @override
  Future<List<ProgressNote>> getProgressNotes(String clientId) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection('progressNotes')
        .where('clientId', isEqualTo: clientId);
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      query = query.where('staffId', isEqualTo: userId);
    }

    final snapshot = await query.limit(8).get();
    final notes = snapshot.docs
        .map((doc) => ProgressNote.fromFirestore(doc.id, doc.data()))
        .toList();
    notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return notes;
  }

  @override
  Future<List<ReportSummary>> getReports({String? staffId}) async {
    final incidents = await _reportCollection(
      collection: 'incidentReports',
      staffId: staffId,
      titleBuilder: (data) =>
          'Incident: ${data['incidentType'] ?? 'Care event'}',
      subtitleBuilder: (data) => data['description'] as String? ?? '',
      detailsBuilder: (data) => {
        'Report type': data['incidentType'] as String? ?? 'Incident',
        'Description': data['description'] as String? ?? '',
        'Injury observed': data['injuryObserved'] as String? ?? '',
        'Action taken': data['actionTaken'] as String? ?? '',
        'Person informed': data['informedPerson'] as String? ?? '',
        if ((data['witnessDetails'] as String? ?? '').isNotEmpty)
          'Witness details': data['witnessDetails'] as String,
        if ((data['followUp'] as String? ?? '').isNotEmpty)
          'Follow-up': data['followUp'] as String,
      },
    );
    final hazards = await _reportCollection(
      collection: 'hazardReports',
      staffId: staffId,
      titleBuilder: (data) => 'Hazard: ${data['hazardType'] ?? 'Safety risk'}',
      subtitleBuilder: (data) => data['location'] as String? ?? '',
      detailsBuilder: (data) => {
        'Report type': data['hazardType'] as String? ?? 'Hazard',
        'Location': data['location'] as String? ?? '',
        'Risk level': data['riskLevel'] as String? ?? '',
        'Description': data['description'] as String? ?? '',
        'Action taken': data['actionTaken'] as String? ?? '',
      },
    );
    final charts = await _reportCollection(
      collection: 'behaviourCharts',
      staffId: staffId,
      titleBuilder: (_) => 'Behaviour chart',
      subtitleBuilder: (data) => data['behaviourObserved'] as String? ?? '',
      detailsBuilder: (data) => {
        'Trigger': data['trigger'] as String? ?? '',
        'Behaviour observed': data['behaviourObserved'] as String? ?? '',
        'Staff response': data['staffResponse'] as String? ?? '',
        'De-escalation': data['deEscalationStrategy'] as String? ?? '',
        'Outcome': data['outcome'] as String? ?? '',
        'Mood level': data['moodLevel'] as String? ?? '',
        if ((data['followUp'] as String? ?? '').isNotEmpty)
          'Follow-up': data['followUp'] as String,
      },
      defaultStatus: ReportStatus.newReport,
    );
    final notes = await _reportCollection(
      collection: 'progressNotes',
      staffId: staffId,
      titleBuilder: (_) => 'Progress note',
      subtitleBuilder: (data) => data['shiftSummary'] as String? ?? '',
      detailsBuilder: (data) => {
        'Shift summary': data['shiftSummary'] as String? ?? '',
        'Activities': data['activities'] as String? ?? '',
        'Meals and fluids': data['mealsFluids'] as String? ?? '',
        'Personal care': data['personalCare'] as String? ?? '',
        'Mood and behaviour': data['moodBehaviour'] as String? ?? '',
        'Communication': data['communication'] as String? ?? '',
        if ((data['followUp'] as String? ?? '').isNotEmpty)
          'Follow-up': data['followUp'] as String,
      },
      defaultStatus: ReportStatus.resolved,
    );

    final reports = [...incidents, ...hazards, ...charts, ...notes];
    reports.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return reports;
  }

  Future<List<ReportSummary>> _reportCollection({
    required String collection,
    required String Function(Map<String, dynamic>) titleBuilder,
    required String Function(Map<String, dynamic>) subtitleBuilder,
    required Map<String, String> Function(Map<String, dynamic>) detailsBuilder,
    String? staffId,
    ReportStatus defaultStatus = ReportStatus.newReport,
  }) async {
    Query<Map<String, dynamic>> query = _firestore.collection(collection);
    if (staffId != null) {
      query = query.where('staffId', isEqualTo: staffId);
    }
    final snapshot = await query.limit(30).get();

    return Future.wait(
      snapshot.docs.map((doc) async {
        final data = doc.data();
        final reportStaffId = data['staffId'] as String? ?? '';
        final reportClientId = data['clientId'] as String? ?? '';
        final statusValue = data['status'] as String?;
        return ReportSummary(
          id: doc.id,
          collection: collection,
          title: titleBuilder(data),
          subtitle: subtitleBuilder(data),
          staffId: reportStaffId,
          clientId: reportClientId,
          status: statusValue == null
              ? defaultStatus
              : ReportStatusLabel.fromValue(statusValue),
          createdAt: dateFromFirestore(data['createdAt']) ?? DateTime.now(),
          staffName: await _userName(reportStaffId),
          clientName: await _clientName(reportClientId),
          details: _cleanDetails(detailsBuilder(data)),
          imageUrl: data['imageUrl'] as String?,
        );
      }),
    );
  }

  Map<String, String> _cleanDetails(Map<String, String> details) {
    return Map.fromEntries(
      details.entries.where((entry) => entry.value.trim().isNotEmpty),
    );
  }

  Future<String?> _userName(String userId) async {
    if (userId.isEmpty) return null;
    final doc = await _firestore.collection('users').doc(userId).get();
    return doc.data()?['fullName'] as String?;
  }

  Future<String?> _clientName(String clientId) async {
    if (clientId.isEmpty) return null;
    final doc = await _firestore.collection('clients').doc(clientId).get();
    return doc.data()?['fullName'] as String?;
  }

  @override
  Future<List<CheckInRecord>> getCheckIns() async {
    final snapshot = await _firestore.collection('checkIns').limit(30).get();
    final records = snapshot.docs
        .map((doc) => CheckInRecord.fromFirestore(doc.id, doc.data()))
        .toList();
    records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
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
    final updated = shift.copyWith(
      checkInLatitude: latitude,
      checkInLongitude: longitude,
      checkInStatus: verified ? 'Verified' : 'Failed',
      shiftStatus: verified ? 'Started' : 'Scheduled',
    );
    await _firestore.collection('shifts').doc(shift.id).update({
      'checkInLatitude': latitude,
      'checkInLongitude': longitude,
      'checkInStatus': updated.checkInStatus,
      'shiftStatus': updated.shiftStatus,
      'checkedInAt': FieldValue.serverTimestamp(),
    });
    await _firestore
        .collection('checkIns')
        .add(
          CheckInRecord(
            id: '',
            staffId: shift.staffId,
            shiftId: shift.id,
            status: updated.checkInStatus,
            latitude: latitude,
            longitude: longitude,
            distanceMetres: distanceMetres,
            createdAt: DateTime.now(),
          ).toFirestore(),
        );
    return updated;
  }

  @override
  Future<ShiftAssignment> endShift(ShiftAssignment shift) async {
    final updated = shift.copyWith(shiftStatus: 'Ended');
    await _firestore.collection('shifts').doc(shift.id).update({
      'shiftStatus': 'Ended',
      'endedAt': FieldValue.serverTimestamp(),
    });
    return updated;
  }

  @override
  Future<void> submitProgressNote(ProgressNote note) async {
    await _firestore.collection('progressNotes').add(note.toFirestore());
  }

  @override
  Future<String?> uploadEvidence(XFile? image, String folder) async {
    if (image == null) return null;
    final bytes = await image.readAsBytes();
    final extension = image.name.split('.').lastOrNull ?? 'jpg';
    final ref = _storage.ref(
      '$folder/${DateTime.now().millisecondsSinceEpoch}.$extension',
    );
    await ref.putData(
      bytes,
      SettableMetadata(contentType: image.mimeType ?? 'image/jpeg'),
    );
    return ref.getDownloadURL();
  }

  @override
  Future<void> submitIncidentReport(IncidentReport report) async {
    await _firestore.collection('incidentReports').add(report.toFirestore());
  }

  @override
  Future<void> submitHazardReport(HazardReport report) async {
    await _firestore.collection('hazardReports').add(report.toFirestore());
  }

  @override
  Future<void> submitBehaviourChart(BehaviourChart chart) async {
    await _firestore.collection('behaviourCharts').add(chart.toFirestore());
  }

  @override
  Future<void> updateReportStatus({
    required String collection,
    required String id,
    required ReportStatus status,
  }) async {
    await _firestore.collection(collection).doc(id).update({
      'status': status.firestoreValue,
    });
  }
}

extension _IterableLastOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;

  T? get lastOrNull => isEmpty ? null : last;
}
