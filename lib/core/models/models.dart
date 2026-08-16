// lib/core/models/models.dart
import 'package:intl/intl.dart';
import 'enums.dart';

class RegisteredUser {
  final String uid;
  final String name;
  final String email;
  final String? password;
  final UserRole role;

  const RegisteredUser({
    required this.uid,
    required this.name,
    required this.email,
    this.password,
    required this.role,
  });

  factory RegisteredUser.fromJson(Map<String, dynamic> json) {
    return RegisteredUser(
      uid: json['uid'] ?? json['Id'] ?? '',
      name: json['name'] ?? json['FullName'] ?? '',
      email: json['email'] ?? json['Email'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name.toLowerCase() == (json['role'] ?? json['Role'] ?? 'family').toString().toLowerCase(),
        orElse: () => UserRole.family,
      ),
    );
  }
}

class Reminder {
  final String id;
  final String elderlyId;
  final String title;
  final ReminderCategory category;
  final String time;
  final String date;
  final ReminderFrequency frequency;
  final String? dosageOrLocation;
  final String? notes;
  bool isCompleted;
  String? completedAt;
  final String? createdBy;
  final DateTime? datetimeCreated;

  Reminder({
    required this.id,
    required this.elderlyId,
    required this.title,
    required this.category,
    required this.time,
    this.date = 'Today',
    required this.frequency,
    this.dosageOrLocation,
    this.notes,
    this.isCompleted = false,
    this.completedAt,
    this.createdBy,
    this.datetimeCreated,
  });

  Reminder copyWith({
    String? id,
    String? elderlyId,
    String? title,
    ReminderCategory? category,
    String? time,
    String? date,
    ReminderFrequency? frequency,
    String? dosageOrLocation,
    String? notes,
    bool? isCompleted,
    String? completedAt,
    String? createdBy,
    DateTime? datetimeCreated,
  }) {
    return Reminder(
      id: id ?? this.id,
      elderlyId: elderlyId ?? this.elderlyId,
      title: title ?? this.title,
      category: category ?? this.category,
      time: time ?? this.time,
      date: date ?? this.date,
      frequency: frequency ?? this.frequency,
      dosageOrLocation: dosageOrLocation ?? this.dosageOrLocation,
      notes: notes ?? this.notes,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      createdBy: createdBy ?? this.createdBy,
      datetimeCreated: datetimeCreated ?? this.datetimeCreated,
    );
  }

  factory Reminder.fromJson(Map<String, dynamic> json) {
    String? parsedCompletedAt;
    if (json['CompletedAt'] != null) {
      try {
        parsedCompletedAt = DateFormat('hh:mm a').format(DateTime.parse(json['CompletedAt']).toLocal());
      } catch (_) {}
    }
    return Reminder(
      id: json['Id'] ?? json['id'] ?? '',
      elderlyId: json['ElderlyId'] ?? json['PatientId'] ?? json['elderlyId'] ?? '',
      title: json['MedicationName'] ?? json['title'] ?? '',
      category: ReminderCategory.values.firstWhere(
        (e) => e.name.toLowerCase() == (json['Category'] ?? '').toString().toLowerCase(),
        orElse: () => ReminderCategory.medication,
      ),
      time: json['ScheduledTime'] ?? json['time'] ?? '08:00 AM',
      date: json['ScheduledDate'] ?? json['date'] ?? 'Today',
      frequency: ReminderFrequency.values.firstWhere(
        (e) => e.name.toLowerCase() == (json['Frequency'] ?? '').toString().toLowerCase(),
        orElse: () => ReminderFrequency.daily,
      ),
      dosageOrLocation: json['Dosage'] ?? json['dosageOrLocation'],
      notes: json['Notes'] ?? json['notes'],
      isCompleted: json['Status'] == 'Taken' || (json['isCompleted'] ?? false),
      completedAt: parsedCompletedAt,
      createdBy: json['CreatorName']?.toString() ?? json['CreatedBy']?.toString(),
      datetimeCreated: json['DatetimeCreated'] != null ? DateTime.tryParse(json['DatetimeCreated']) : null,
    );
  }
}

class CareTask {
  final String id;
  final String elderlyId;
  final String title;
  final String description;
  TaskStatus status;
  final DateTime scheduledTime;
  DateTime? completedAt;
  String? completedBy;
  final String? createdBy;
  final DateTime? datetimeCreated;

  CareTask({
    required this.id,
    required this.elderlyId,
    required this.title,
    required this.description,
    required this.status,
    required this.scheduledTime,
    this.completedAt,
    this.completedBy,
    this.createdBy,
    this.datetimeCreated,
  });

  factory CareTask.fromJson(Map<String, dynamic> json) {
    return CareTask(
      id: json['Id'] ?? json['id'] ?? '',
      elderlyId: json['AssignedTo'] ?? json['elderlyId'] ?? '',
      title: json['Title'] ?? json['title'] ?? '',
      description: json['Description'] ?? json['description'] ?? '',
      status: (json['Status'] == 'Completed' || json['status'] == 'done') ? TaskStatus.done : TaskStatus.pending,
      scheduledTime: DateTime.tryParse(json['DueDate'] ?? '') ?? DateTime.now(),
      createdBy: json['CreatedBy']?.toString(),
      datetimeCreated: json['DatetimeCreated'] != null ? DateTime.tryParse(json['DatetimeCreated']) : null,
    );
  }
}

class HealthVitals {
  final String? id;
  final int heartRate;
  final String bloodPressure;
  final int glucose;
  final DateTime timestamp;
  final String recordedBy;
  final List<String> alerts;

  const HealthVitals({
    this.id,
    required this.heartRate,
    required this.bloodPressure,
    required this.glucose,
    required this.timestamp,
    required this.recordedBy,
    this.alerts = const [],
  });

  factory HealthVitals.fromJson(Map<String, dynamic> json) {
    return HealthVitals(
      id: json['Id']?.toString(),
      heartRate: int.tryParse(json['HeartRate']?.toString() ?? '0') ?? 0,
      bloodPressure: json['BloodPressure']?.toString() ?? '120/80',
      glucose: (double.tryParse(json['BloodSugar']?.toString() ?? '0') ?? 0).toInt(),
      timestamp: DateTime.tryParse(json['DatetimeCreated'] ?? '') ?? DateTime.now(),
      recordedBy: json['CreatedBy']?.toString() ?? 'Caregiver',
      alerts: (json['alerts'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

class HealthMetricPrediction {
  final String key;
  final String label;
  final double latest;
  final String unit;
  final double baselineMean;
  final double deviationFromBaseline;
  final String trend;
  final double nextReadingEstimate;
  final bool abnormal;

  const HealthMetricPrediction({
    required this.key,
    required this.label,
    required this.latest,
    required this.unit,
    required this.baselineMean,
    required this.deviationFromBaseline,
    required this.trend,
    required this.nextReadingEstimate,
    required this.abnormal,
  });

  factory HealthMetricPrediction.fromJson(Map<String, dynamic> json) {
    double number(dynamic value) => double.tryParse(value?.toString() ?? '') ?? 0;
    return HealthMetricPrediction(
      key: json['key']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      latest: number(json['latest']),
      unit: json['unit']?.toString() ?? '',
      baselineMean: number(json['baselineMean']),
      deviationFromBaseline: number(json['deviationFromBaseline']),
      trend: json['trend']?.toString() ?? 'stable',
      nextReadingEstimate: number(json['nextReadingEstimate']),
      abnormal: json['abnormal'] == true,
    );
  }
}

class HealthPrediction {
  final bool modelReady;
  final int minimumRecords;
  final int recordsAnalyzed;
  final String riskLevel;
  final int riskScore;
  final int? stabilityScore;
  final bool isAnomaly;
  final String summary;
  final List<String> clinicalAlerts;
  final List<String> recommendations;
  final List<HealthMetricPrediction> metrics;
  final String disclaimer;

  const HealthPrediction({
    required this.modelReady,
    required this.minimumRecords,
    required this.recordsAnalyzed,
    required this.riskLevel,
    required this.riskScore,
    this.stabilityScore,
    required this.isAnomaly,
    required this.summary,
    required this.clinicalAlerts,
    required this.recommendations,
    required this.metrics,
    required this.disclaimer,
  });

  factory HealthPrediction.fromJson(Map<String, dynamic> json) {
    final modelInfo = json['modelInfo'] as Map<String, dynamic>? ?? const {};
    int integer(dynamic value) => int.tryParse(value?.toString() ?? '') ?? 0;
    return HealthPrediction(
      modelReady: modelInfo['modelReady'] == true,
      minimumRecords: integer(modelInfo['minimumRecords']),
      recordsAnalyzed: integer(modelInfo['recordsAnalyzed']),
      riskLevel: json['riskLevel']?.toString() ?? 'insufficient_data',
      riskScore: integer(json['riskScore']),
      stabilityScore: json['stabilityScore'] == null ? null : integer(json['stabilityScore']),
      isAnomaly: json['isAnomaly'] == true,
      summary: json['summary']?.toString() ?? '',
      clinicalAlerts: (json['clinicalAlerts'] as List<dynamic>? ?? const []).map((item) => item.toString()).toList(),
      recommendations: (json['recommendations'] as List<dynamic>? ?? const []).map((item) => item.toString()).toList(),
      metrics: (json['metrics'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(HealthMetricPrediction.fromJson)
          .toList(),
      disclaimer: json['disclaimer']?.toString() ?? 'This screening result is not a medical diagnosis.',
    );
  }
}

class CareAcknowledgement {
  final String id;
  final String familyMemberId;
  final String familyName;
  final String? familyProfilePhoto; // NEW FIELD
  final String relationship;
  final String comment;
  final DateTime timestamp;

  CareAcknowledgement({
    required this.id,
    required this.familyMemberId,
    required this.familyName,
    this.familyProfilePhoto,
    required this.relationship,
    required this.comment,
    required this.timestamp,
  });

  factory CareAcknowledgement.fromJson(Map<String, dynamic> json) {
    return CareAcknowledgement(
      id: json['Id'] ?? '',
      familyMemberId: json['FamilyMemberId']?.toString() ?? json['familyMemberId']?.toString() ?? '',
      familyName: json['FamilyName'] ?? 'Family Member',
      familyProfilePhoto: json['FamilyProfilePhoto']?.toString() ?? json['familyProfilePhoto']?.toString(),
      relationship: json['Relationship'] ?? 'Relative',
      comment: json['Comment'] ?? '',
      timestamp: DateTime.tryParse(json['DatetimeCreated'] ?? '') ?? DateTime.now(),
    );
  }
}

class CareReport {
  final String id;
  final ReportCategory category;
  final String title;
  final String text;
  final DateTime timestamp;
  final String caregiverName;
  final String? caregiverProfilePhoto; 
  final List<String> photoUrls;
  final List<CareAcknowledgement> acknowledgements;

  CareReport({
    required this.id, required this.category, required this.title, 
    required this.text, required this.timestamp, required this.caregiverName, 
    this.caregiverProfilePhoto, required this.photoUrls, required this.acknowledgements
  });

  factory CareReport.fromJson(Map<String, dynamic> json) {
    return CareReport(
      id: json['Id']?.toString() ?? json['id']?.toString() ?? '',
      category: _parseCategory(json['Category']?.toString() ?? json['category']?.toString()),
      title: json['HealthStatusNotes']?.toString() ?? json['healthStatusNotes']?.toString() ?? '',
      text: json['Observations']?.toString() ?? json['observations']?.toString() ?? '',
      timestamp: DateTime.parse(json['DatetimeCreated']?.toString() ?? json['datetimeCreated']?.toString() ?? DateTime.now().toIso8601String()),
      caregiverName: json['CaregiverName']?.toString() ?? json['caregiverName']?.toString() ?? 'Unknown',
      caregiverProfilePhoto: json['CaregiverProfilePhoto']?.toString() ?? json['caregiverProfilePhoto']?.toString(), 
      photoUrls: json['PhotoUrl'] != null ? [json['PhotoUrl'].toString()] : (json['photoUrl'] != null ? [json['photoUrl'].toString()] : []),
      acknowledgements: (json['Acknowledgements'] as List<dynamic>?)?.map((e) => CareAcknowledgement.fromJson(e)).toList() ?? [],
    );
  }

  static ReportCategory _parseCategory(String? val) {
    return ReportCategory.values.firstWhere((e) => e.name == val, orElse: () => ReportCategory.dailyLog);
  }
}

class ChatMessage {
  final String id;
  final String elderlyId;
  final String senderId;
  final String senderName;
  final String senderRole;
  final String text;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.elderlyId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.text,
    required this.timestamp,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      elderlyId: (json['elderlyId'] ?? json['ElderlyId'] ?? '').toString(),
      senderId: (json['senderId'] ?? json['SenderId'] ?? '').toString(),
      senderName: (json['senderName'] ?? json['SenderName'] ?? 'Care Team').toString(),
      senderRole: (json['senderRole'] ?? json['SenderRole'] ?? 'User').toString(),
      text: (json['text'] ?? json['MessageText'] ?? '').toString(),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'].toString())
          : DateTime.now(),
    );
  }
}
