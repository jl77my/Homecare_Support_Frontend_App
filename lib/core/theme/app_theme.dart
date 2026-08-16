import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors
  static const Color navy = Color(0xFF081D45);
  static const Color background = Color(0xFFF7FBFF);
  static const Color border = Color(0xFFD4E2F0);
  static const Color primaryDark = navy;
  static const Color primaryBlue = Color(0xFF075DBB);
  static const Color primaryBlueDark = Color(0xFF064D9B);
  static const Color primaryRed = Color(0xFFD20D16);
  static const Color primaryGreen = Color(0xFF118A36);
  static const Color primaryAmber = Color(0xFFF59E0B);
  
  static const Color bgLight = background;
  static const Color surfaceCard = Colors.white;
  static const Color borderLight = Color(0xFFE7F0F8);
  static const Color borderSubtle = border;
  
  static const Color textMain = navy;
  static const Color textMuted = Color(0xFF425775);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: bgLight,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        primary: primaryBlue,
        secondary: primaryBlueDark,
        surface: surfaceCard,
        error: primaryRed,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        iconTheme: IconThemeData(color: primaryDark),
        titleTextStyle: TextStyle(
          color: primaryDark,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardTheme(
        color: surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: const BorderSide(color: borderLight, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFA9C6E3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          foregroundColor: primaryBlue,
          side: const BorderSide(color: primaryBlue, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        hintStyle: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
