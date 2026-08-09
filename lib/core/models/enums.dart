enum UserRole {
  elderly,
  caregiver,
  family,
  admin;

  String get label {
    switch (this) {
      case UserRole.elderly:
        return 'Senior / Elderly';
      case UserRole.caregiver:
        return 'Caregiver Specialist';
      case UserRole.family:
        return 'Family Member';
      case UserRole.admin:
        return 'Administrator';
    }
  }
}

enum TaskStatus {
  pending,
  done;

  String get label {
    switch (this) {
      case TaskStatus.pending:
        return 'PENDING';
      case TaskStatus.done:
        return 'DONE';
    }
  }
}

enum ReminderCategory {
  medication,
  appointment,
  careActivity;

  String get label {
    switch (this) {
      case ReminderCategory.medication:
        return 'Medication';
      case ReminderCategory.appointment:
        return 'Appointment';
      case ReminderCategory.careActivity:
        return 'Care Activity';
    }
  }

  String get emoji {
    switch (this) {
      case ReminderCategory.medication:
        return '💊';
      case ReminderCategory.appointment:
        return '📅';
      case ReminderCategory.careActivity:
        return '🏃';
    }
  }
}

enum ReminderFrequency {
  once,
  daily,
  weekly;

  String get label {
    switch (this) {
      case ReminderFrequency.once:
        return 'Once';
      case ReminderFrequency.daily:
        return 'Daily';
      case ReminderFrequency.weekly:
        return 'Weekly';
    }
  }
}

enum ReportCategory {
  dailyLog,
  injuryWound,
  mealNutrition,
  mobilityExercise,
  medicalObservation;

  String get label {
    switch (this) {
      case ReportCategory.dailyLog:
        return 'Daily Care Log';
      case ReportCategory.injuryWound:
        return 'Injury & Wound Care';
      case ReportCategory.mealNutrition:
        return 'Meal & Nutrition';
      case ReportCategory.mobilityExercise:
        return 'Mobility & Exercise';
      case ReportCategory.medicalObservation:
        return 'Medical Observation';
    }
  }

  String get emoji {
    switch (this) {
      case ReportCategory.dailyLog:
        return '📝';
      case ReportCategory.injuryWound:
        return '🩹';
      case ReportCategory.mealNutrition:
        return '🥗';
      case ReportCategory.mobilityExercise:
        return '🚶';
      case ReportCategory.medicalObservation:
        return '🩺';
    }
  }
}

