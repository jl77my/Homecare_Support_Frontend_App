import 'package:flutter/material.dart';

class AppTheme {
  // High-contrast colors for visibility (cite: 297)
  static const Color primaryBlue = Color(0xFF0056b3); 
  static const Color alertRed = Color(0xFFD32F2F); // For SOS button (cite: 298)
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color textBlack = Color(0xFF000000);

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryBlue,
      scaffoldBackgroundColor: backgroundWhite,
      
      // Defining large text sizes for elderly readability (cite: 304)
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 40, // Range 36-48 as per research (cite: 304)
          fontWeight: FontWeight.bold,
          color: textBlack,
        ),
        bodyLarge: TextStyle(
          fontSize: 22, // Enhanced size for general reading
          color: textBlack,
        ),
      ),

      // Ensuring buttons meet the minimum size requirement (cite: 305)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(150, 60), // Supporting easier tapping (cite: 312)
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}