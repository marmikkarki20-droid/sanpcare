import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum UserRole { staff, admin }

extension UserRoleLabel on UserRole {
  String get label => switch (this) {
    UserRole.staff => 'Staff',
    UserRole.admin => 'Admin',
  };
}

enum ReportStatus { newReport, underReview, actionRequired, resolved }

extension ReportStatusLabel on ReportStatus {
  String get label => switch (this) {
    ReportStatus.newReport => 'New',
    ReportStatus.underReview => 'Under Review',
    ReportStatus.actionRequired => 'Action Required',
    ReportStatus.resolved => 'Resolved',
  };

  String get firestoreValue => switch (this) {
    ReportStatus.newReport => 'new',
    ReportStatus.underReview => 'underReview',
    ReportStatus.actionRequired => 'actionRequired',
    ReportStatus.resolved => 'resolved',
  };

  Color get color => switch (this) {
    ReportStatus.newReport => const Color(0xFF087EA4),
    ReportStatus.underReview => const Color(0xFFD37A18),
    ReportStatus.actionRequired => const Color(0xFFC43D32),
    ReportStatus.resolved => const Color(0xFF327A60),
  };

  static ReportStatus fromValue(String? value) {
    return switch (value) {
      'underReview' || 'Under Review' => ReportStatus.underReview,
      'actionRequired' || 'Action Required' => ReportStatus.actionRequired,
      'resolved' || 'Resolved' => ReportStatus.resolved,
      _ => ReportStatus.newReport,
    };
  }
}

class AppUser {
  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.position,
    required this.facilityId,
    this.isActive = true,
  });

  final String id;
  final String fullName;
  final String email;
  final UserRole role;
  final String position;
  final String facilityId;
  final bool isActive;

  factory AppUser.fromFirestore(String id, Map<String, dynamic> data) {
    return AppUser(
      id: id,
      fullName: data['fullName'] as String? ?? 'Care Team Member',
      email: data['email'] as String? ?? '',
      role: (data['role'] as String?) == 'admin'
          ? UserRole.admin
          : UserRole.staff,
      position: data['position'] as String? ?? 'Support Worker',
      facilityId: data['facilityId'] as String? ?? '',
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  AppUser copyWith({
    String? fullName,
    String? email,
    UserRole? role,
    String? position,
    String? facilityId,
    bool? isActive,
  }) {
    return AppUser(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role ?? this.role,
      position: position ?? this.position,
      facilityId: facilityId ?? this.facilityId,
      isActive: isActive ?? this.isActive,
    );
  }
}

class ClientProfile {
  const ClientProfile({
    required this.id,
    required this.fullName,
    required this.roomNumber,
    required this.address,
    required this.careNeeds,
    required this.mobilityStatus,
    required this.communicationNeeds,
    required this.riskNotes,
    required this.emergencyContact,
  });

  final String id;
  final String fullName;
  final String roomNumber;
  final String address;
  final String careNeeds;
  final String mobilityStatus;
  final String communicationNeeds;
  final String riskNotes;
  final String emergencyContact;

  factory ClientProfile.fromFirestore(String id, Map<String, dynamic> data) {
    return ClientProfile(
      id: id,
      fullName: data['fullName'] as String? ?? 'Resident',
      roomNumber: data['roomNumber'] as String? ?? 'N/A',
      address: data['address'] as String? ?? 'Service location',
      careNeeds: data['careNeeds'] as String? ?? '',
      mobilityStatus: data['mobilityStatus'] as String? ?? '',
      communicationNeeds: data['communicationNeeds'] as String? ?? '',
      riskNotes: data['riskNotes'] as String? ?? '',
      emergencyContact: data['emergencyContact'] as String? ?? '',
    );
  }
}

class ShiftAssignment {
  const ShiftAssignment({
    required this.id,
    required this.staffId,
    required this.clientId,
    required this.startTime,
    required this.endTime,
    required this.serviceLocation,
    required this.assignedLatitude,
    required this.assignedLongitude,
    this.checkInLatitude,
    this.checkInLongitude,
    this.checkInStatus = 'Pending',
    this.shiftStatus = 'Scheduled',
  });

  final String id;
  final String staffId;
  final String clientId;
  final DateTime startTime;
  final DateTime endTime;
  final String serviceLocation;
  final double assignedLatitude;
  final double assignedLongitude;
  final double? checkInLatitude;
  final double? checkInLongitude;
  final String checkInStatus;
  final String shiftStatus;

  bool get isCheckedIn => shiftStatus == 'Started';
  bool get isEnded => shiftStatus == 'Ended';

  ShiftAssignment copyWith({
    double? assignedLatitude,
    double? assignedLongitude,
    double? checkInLatitude,
    double? checkInLongitude,
    String? checkInStatus,
    String? shiftStatus,
  }) {
    return ShiftAssignment(
      id: id,
      staffId: staffId,
      clientId: clientId,
      startTime: startTime,
      endTime: endTime,
      serviceLocation: serviceLocation,
      assignedLatitude: assignedLatitude ?? this.assignedLatitude,
      assignedLongitude: assignedLongitude ?? this.assignedLongitude,
      checkInLatitude: checkInLatitude ?? this.checkInLatitude,
      checkInLongitude: checkInLongitude ?? this.checkInLongitude,
      checkInStatus: checkInStatus ?? this.checkInStatus,
      shiftStatus: shiftStatus ?? this.shiftStatus,
    );
  }

  factory ShiftAssignment.fromFirestore(String id, Map<String, dynamic> data) {
    return ShiftAssignment(
      id: id,
      staffId: data['staffId'] as String? ?? '',
      clientId: data['clientId'] as String? ?? '',
      startTime: dateFromFirestore(data['startTime']) ?? DateTime.now(),
      endTime:
          dateFromFirestore(data['endTime']) ??
          DateTime.now().add(const Duration(hours: 8)),
      serviceLocation:
          data['serviceLocation'] as String? ?? 'Assigned service location',
      assignedLatitude: (data['assignedLatitude'] as num?)?.toDouble() ?? 0,
      assignedLongitude: (data['assignedLongitude'] as num?)?.toDouble() ?? 0,
      checkInLatitude: (data['checkInLatitude'] as num?)?.toDouble(),
      checkInLongitude: (data['checkInLongitude'] as num?)?.toDouble(),
      checkInStatus: data['checkInStatus'] as String? ?? 'Pending',
      shiftStatus: data['shiftStatus'] as String? ?? 'Scheduled',
    );
  }
}

class ProgressNote {
  const ProgressNote({
    required this.id,
    required this.staffId,
    required this.clientId,
    required this.shiftSummary,
    required this.activities,
    required this.mealsFluids,
    required this.personalCare,
    required this.moodBehaviour,
    required this.communication,
    required this.followUp,
    required this.createdAt,
  });

  final String id;
  final String staffId;
  final String clientId;
  final String shiftSummary;
  final String activities;
  final String mealsFluids;
  final String personalCare;
  final String moodBehaviour;
  final String communication;
  final String followUp;
  final DateTime createdAt;

  Map<String, dynamic> toFirestore() => {
    'staffId': staffId,
    'clientId': clientId,
    'shiftSummary': shiftSummary,
    'activities': activities,
    'mealsFluids': mealsFluids,
    'personalCare': personalCare,
    'moodBehaviour': moodBehaviour,
    'communication': communication,
    'followUp': followUp,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  factory ProgressNote.fromFirestore(String id, Map<String, dynamic> data) {
    return ProgressNote(
      id: id,
      staffId: data['staffId'] as String? ?? '',
      clientId: data['clientId'] as String? ?? '',
      shiftSummary: data['shiftSummary'] as String? ?? '',
      activities: data['activities'] as String? ?? '',
      mealsFluids: data['mealsFluids'] as String? ?? '',
      personalCare: data['personalCare'] as String? ?? '',
      moodBehaviour: data['moodBehaviour'] as String? ?? '',
      communication: data['communication'] as String? ?? '',
      followUp: data['followUp'] as String? ?? '',
      createdAt: dateFromFirestore(data['createdAt']) ?? DateTime.now(),
    );
  }
}

class ShiftTask {
  const ShiftTask({
    required this.id,
    required this.shiftId,
    required this.title,
    required this.notes,
    required this.category,
    required this.isCompleted,
    required this.createdAt,
    this.completedAt,
  });

  final String id;
  final String shiftId;
  final String title;
  final String notes;
  final String category;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? completedAt;

  ShiftTask copyWith({
    bool? isCompleted,
    DateTime? completedAt,
    bool clearCompletedAt = false,
  }) {
    return ShiftTask(
      id: id,
      shiftId: shiftId,
      title: title,
      notes: notes,
      category: category,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
      completedAt: clearCompletedAt ? null : completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'shiftId': shiftId,
    'title': title,
    'notes': notes,
    'category': category,
    'isCompleted': isCompleted,
    'createdAt': Timestamp.fromDate(createdAt),
    'completedAt': completedAt == null
        ? null
        : Timestamp.fromDate(completedAt!),
  };

  factory ShiftTask.fromFirestore(String id, Map<String, dynamic> data) {
    return ShiftTask(
      id: id,
      shiftId: data['shiftId'] as String? ?? '',
      title: data['title'] as String? ?? 'Care task',
      notes: data['notes'] as String? ?? '',
      category: data['category'] as String? ?? 'Shift task',
      isCompleted: data['isCompleted'] as bool? ?? false,
      createdAt: dateFromFirestore(data['createdAt']) ?? DateTime.now(),
      completedAt: dateFromFirestore(data['completedAt']),
    );
  }
}

class IncidentReport {
  const IncidentReport({
    required this.id,
    required this.staffId,
    required this.clientId,
    required this.incidentType,
    required this.description,
    required this.injuryObserved,
    required this.actionTaken,
    required this.informedPerson,
    required this.witnessDetails,
    required this.followUp,
    required this.status,
    required this.createdAt,
    this.imageUrl,
  });

  final String id;
  final String staffId;
  final String clientId;
  final String incidentType;
  final String description;
  final String injuryObserved;
  final String actionTaken;
  final String informedPerson;
  final String witnessDetails;
  final String followUp;
  final ReportStatus status;
  final DateTime createdAt;
  final String? imageUrl;

  Map<String, dynamic> toFirestore() => {
    'staffId': staffId,
    'clientId': clientId,
    'incidentType': incidentType,
    'description': description,
    'injuryObserved': injuryObserved,
    'actionTaken': actionTaken,
    'informedPerson': informedPerson,
    'witnessDetails': witnessDetails,
    'followUp': followUp,
    'imageUrl': imageUrl,
    'status': status.firestoreValue,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  factory IncidentReport.fromFirestore(String id, Map<String, dynamic> data) {
    return IncidentReport(
      id: id,
      staffId: data['staffId'] as String? ?? '',
      clientId: data['clientId'] as String? ?? '',
      incidentType: data['incidentType'] as String? ?? '',
      description: data['description'] as String? ?? '',
      injuryObserved: data['injuryObserved'] as String? ?? '',
      actionTaken: data['actionTaken'] as String? ?? '',
      informedPerson: data['informedPerson'] as String? ?? '',
      witnessDetails: data['witnessDetails'] as String? ?? '',
      followUp: data['followUp'] as String? ?? '',
      imageUrl: data['imageUrl'] as String?,
      status: ReportStatusLabel.fromValue(data['status'] as String?),
      createdAt: dateFromFirestore(data['createdAt']) ?? DateTime.now(),
    );
  }
}

class HazardReport {
  const HazardReport({
    required this.id,
    required this.staffId,
    required this.clientId,
    required this.hazardType,
    required this.location,
    required this.riskLevel,
    required this.description,
    required this.actionTaken,
    required this.status,
    required this.createdAt,
    this.imageUrl,
  });

  final String id;
  final String staffId;
  final String clientId;
  final String hazardType;
  final String location;
  final String riskLevel;
  final String description;
  final String actionTaken;
  final ReportStatus status;
  final DateTime createdAt;
  final String? imageUrl;

  Map<String, dynamic> toFirestore() => {
    'staffId': staffId,
    'clientId': clientId,
    'hazardType': hazardType,
    'location': location,
    'riskLevel': riskLevel,
    'description': description,
    'actionTaken': actionTaken,
    'imageUrl': imageUrl,
    'status': status.firestoreValue,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  factory HazardReport.fromFirestore(String id, Map<String, dynamic> data) {
    return HazardReport(
      id: id,
      staffId: data['staffId'] as String? ?? '',
      clientId: data['clientId'] as String? ?? '',
      hazardType: data['hazardType'] as String? ?? '',
      location: data['location'] as String? ?? '',
      riskLevel: data['riskLevel'] as String? ?? '',
      description: data['description'] as String? ?? '',
      actionTaken: data['actionTaken'] as String? ?? '',
      imageUrl: data['imageUrl'] as String?,
      status: ReportStatusLabel.fromValue(data['status'] as String?),
      createdAt: dateFromFirestore(data['createdAt']) ?? DateTime.now(),
    );
  }
}

class BehaviourChart {
  const BehaviourChart({
    required this.id,
    required this.staffId,
    required this.clientId,
    required this.trigger,
    required this.behaviourObserved,
    required this.staffResponse,
    required this.deEscalationStrategy,
    required this.outcome,
    required this.moodLevel,
    required this.followUp,
    required this.createdAt,
  });

  final String id;
  final String staffId;
  final String clientId;
  final String trigger;
  final String behaviourObserved;
  final String staffResponse;
  final String deEscalationStrategy;
  final String outcome;
  final String moodLevel;
  final String followUp;
  final DateTime createdAt;

  Map<String, dynamic> toFirestore() => {
    'staffId': staffId,
    'clientId': clientId,
    'trigger': trigger,
    'behaviourObserved': behaviourObserved,
    'staffResponse': staffResponse,
    'deEscalationStrategy': deEscalationStrategy,
    'outcome': outcome,
    'moodLevel': moodLevel,
    'followUp': followUp,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  factory BehaviourChart.fromFirestore(String id, Map<String, dynamic> data) {
    return BehaviourChart(
      id: id,
      staffId: data['staffId'] as String? ?? '',
      clientId: data['clientId'] as String? ?? '',
      trigger: data['trigger'] as String? ?? '',
      behaviourObserved: data['behaviourObserved'] as String? ?? '',
      staffResponse: data['staffResponse'] as String? ?? '',
      deEscalationStrategy: data['deEscalationStrategy'] as String? ?? '',
      outcome: data['outcome'] as String? ?? '',
      moodLevel: data['moodLevel'] as String? ?? '',
      followUp: data['followUp'] as String? ?? '',
      createdAt: dateFromFirestore(data['createdAt']) ?? DateTime.now(),
    );
  }
}

class CheckInRecord {
  const CheckInRecord({
    required this.id,
    required this.staffId,
    required this.shiftId,
    required this.status,
    required this.latitude,
    required this.longitude,
    required this.distanceMetres,
    required this.createdAt,
  });

  final String id;
  final String staffId;
  final String shiftId;
  final String status;
  final double latitude;
  final double longitude;
  final double distanceMetres;
  final DateTime createdAt;

  Map<String, dynamic> toFirestore() => {
    'staffId': staffId,
    'shiftId': shiftId,
    'status': status,
    'latitude': latitude,
    'longitude': longitude,
    'distanceMetres': distanceMetres,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  factory CheckInRecord.fromFirestore(String id, Map<String, dynamic> data) {
    return CheckInRecord(
      id: id,
      staffId: data['staffId'] as String? ?? '',
      shiftId: data['shiftId'] as String? ?? '',
      status: data['status'] as String? ?? 'Unknown',
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0,
      distanceMetres: (data['distanceMetres'] as num?)?.toDouble() ?? 0,
      createdAt: dateFromFirestore(data['createdAt']) ?? DateTime.now(),
    );
  }
}

class ReportSummary {
  const ReportSummary({
    required this.id,
    required this.collection,
    required this.title,
    required this.subtitle,
    required this.staffId,
    required this.clientId,
    required this.status,
    required this.createdAt,
    this.staffName,
    this.clientName,
    this.details = const {},
    this.imageUrl,
  });

  final String id;
  final String collection;
  final String title;
  final String subtitle;
  final String staffId;
  final String clientId;
  final ReportStatus status;
  final DateTime createdAt;
  final String? staffName;
  final String? clientName;
  final Map<String, String> details;
  final String? imageUrl;

  ReportSummary copyWith({ReportStatus? status}) {
    return ReportSummary(
      id: id,
      collection: collection,
      title: title,
      subtitle: subtitle,
      staffId: staffId,
      clientId: clientId,
      status: status ?? this.status,
      createdAt: createdAt,
      staffName: staffName,
      clientName: clientName,
      details: details,
      imageUrl: imageUrl,
    );
  }
}

class StaffDocument {
  const StaffDocument({
    required this.id,
    required this.staffId,
    required this.title,
    required this.category,
    required this.status,
    required this.createdAt,
    this.notes = '',
    this.fileName,
    this.fileUrl,
    this.expiresAt,
  });

  final String id;
  final String staffId;
  final String title;
  final String category;
  final String status;
  final DateTime createdAt;
  final String notes;
  final String? fileName;
  final String? fileUrl;
  final DateTime? expiresAt;

  Map<String, dynamic> toFirestore() => {
    'staffId': staffId,
    'title': title,
    'category': category,
    'status': status,
    'notes': notes,
    'fileName': fileName,
    'fileUrl': fileUrl,
    'expiresAt': expiresAt == null ? null : Timestamp.fromDate(expiresAt!),
    'createdAt': Timestamp.fromDate(createdAt),
  };

  factory StaffDocument.fromFirestore(String id, Map<String, dynamic> data) {
    return StaffDocument(
      id: id,
      staffId: data['staffId'] as String? ?? '',
      title: data['title'] as String? ?? 'Untitled document',
      category: data['category'] as String? ?? 'General',
      status: data['status'] as String? ?? 'Filed',
      notes: data['notes'] as String? ?? '',
      fileName: data['fileName'] as String?,
      fileUrl: data['fileUrl'] as String?,
      expiresAt: dateFromFirestore(data['expiresAt']),
      createdAt: dateFromFirestore(data['createdAt']) ?? DateTime.now(),
    );
  }
}

DateTime? dateFromFirestore(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}
