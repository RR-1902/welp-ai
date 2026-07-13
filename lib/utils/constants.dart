import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'Welp.Ai';
  static const String apiBaseUrl = 'https://welp-ai.onrender.com';
  static const String chatEndpoint = '/api/chat';
  static const String uploadResumeEndpoint = '/api/upload-resume';

  static const List<String> interviewModes = [
    'Job/Career',
    'Technical',
    'Custom Topic',
  ];

  static const List<String> difficulties = [
    'Beginner',
    'Intermediate',
    'Advanced',
  ];

  static const List<String> personas = [
    'Supportive Coach',
    'Professional Recruiter',
    'Strict Panelist',
  ];

  static const Duration typingDuration = Duration(milliseconds: 18);

  static ThemeData get darkTheme {
    const surface = Colors.black;
    const card = Color(0xFF141414);
    const accent = Color(0xFF00E5FF);
    const secondary = Color(0xFF2B3038);
    const text = Color(0xFFF4FBFF);

    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: surface,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        secondary: secondary,
        surface: card,
      ),
      textTheme: const TextTheme(
        displaySmall: TextStyle(
          color: text,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
        ),
        headlineMedium: TextStyle(
          color: text,
          fontWeight: FontWeight.w800,
          height: 1.1,
          letterSpacing: -0.6,
        ),
        titleLarge: TextStyle(
          color: text,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: Color(0xFFDDE6EB),
          height: 1.45,
        ),
        bodyMedium: TextStyle(
          color: Color(0xFF96A4AF),
          height: 1.4,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        labelStyle: const TextStyle(color: Color(0xFFB7C4CC)),
        hintStyle: const TextStyle(color: Color(0xFF7E8B96)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: accent, width: 1.3),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          backgroundColor: accent,
          foregroundColor: Colors.black,
          elevation: 0,
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        foregroundColor: text,
      ),
    );
  }
}
