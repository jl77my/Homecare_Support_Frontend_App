import 'package:intl/intl.dart';
import 'enums.dart';

// 1. Registered User Profile Entity
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

// 2. Reminder Model (Medications / Appointments)
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
      // Fixed: Mapped to ElderlyId
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

// 3. Care Task Model
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

// 4. Health Vitals Model
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

// 5. Care Report Model
class CareReport {
  final String id;
  final String elderlyId;
  final String caregiverId;
  final String caregiverName;
  final String title;
  final ReportCategory category;
  final ReportSeverity severity;
  final String text;
  final List<String> photoUrls;
  final DateTime timestamp;

  CareReport({
    required this.id,
    required this.elderlyId,
    required this.caregiverId,
    required this.caregiverName,
    required this.title,
    required this.category,
    required this.severity,
    required this.text,
    this.photoUrls = const [],
    required this.timestamp,
  });

  factory CareReport.fromJson(Map<String, dynamic> json) {
    return CareReport(
      id: json['Id'] ?? json['id'] ?? '',
      // Fixed: Mapped to ElderlyId
      elderlyId: json['ElderlyId'] ?? json['PatientId'] ?? json['elderlyId'] ?? '',
      caregiverId: json['CreatedBy'] ?? json['caregiverId'] ?? '',
      caregiverName: json['CaregiverName'] ?? 'Caregiver',
      title: json['HealthStatusNotes'] ?? 'Daily Log',
      category: ReportCategory.dailyLog,
      severity: ReportSeverity.routine,
      text: json['Observations'] ?? json['DailyActivities'] ?? '',
      photoUrls: json['PhotoUrl'] != null ? [json['PhotoUrl']] : [],
      timestamp: DateTime.tryParse(json['DatetimeCreated'] ?? '') ?? DateTime.now(),
    );
  }
}

// 6. Chat Message Model
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