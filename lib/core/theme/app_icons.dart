import 'package:flutter/material.dart';

import '../models/enums.dart';

class AppIcons {
  AppIcons._();

  static IconData reminder(ReminderCategory category) {
    switch (category) {
      case ReminderCategory.medication:
        return Icons.medication_outlined;
      case ReminderCategory.appointment:
        return Icons.event_available_outlined;
      case ReminderCategory.careActivity:
        return Icons.directions_walk_rounded;
    }
  }

  static IconData report(ReportCategory category) {
    switch (category) {
      case ReportCategory.dailyLog:
        return Icons.event_note_outlined;
      case ReportCategory.injuryWound:
        return Icons.healing_outlined;
      case ReportCategory.mealNutrition:
        return Icons.restaurant_outlined;
      case ReportCategory.mobilityExercise:
        return Icons.accessibility_new_rounded;
      case ReportCategory.medicalObservation:
        return Icons.monitor_heart_outlined;
    }
  }
}
