import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData buildTheme() {
  final baseTheme = ThemeData.light();
  return baseTheme.copyWith(
    scaffoldBackgroundColor: Colors.white,
    textTheme: TextTheme(
      bodyLarge: GoogleFonts.poppins(
        textStyle: const TextStyle(
          color: Color.fromARGB(255, 11, 11, 11),
          fontSize: 16,
        ),
      ),
      bodyMedium: GoogleFonts.poppins(
        textStyle: const TextStyle(
          color: Color.fromARGB(255, 11, 11, 11),
          fontSize: 14,
        ),
      ),
      bodySmall: GoogleFonts.poppins(
        textStyle: const TextStyle(
          color: Color.fromARGB(255, 11, 11, 11),
          fontSize: 12,
        ),
      ),
    ),
    colorScheme: baseTheme.colorScheme.copyWith(
      primary: const Color.fromARGB(255, 37, 99, 235),
      secondary: const Color.fromARGB(255, 37, 99, 235),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color.fromARGB(255, 37, 99, 235),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromARGB(255, 37, 99, 235),
        foregroundColor: Colors.white,
      ),
    ),
    bottomNavigationBarTheme: baseTheme.bottomNavigationBarTheme.copyWith(
      backgroundColor: Colors.white,
      selectedItemColor: const Color.fromARGB(255, 11, 11, 11),
      unselectedItemColor: const Color.fromARGB(255, 156, 163, 175),
      selectedLabelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    ),
    shadowColor: const Color.fromARGB(74, 199, 210, 255),
    inputDecorationTheme: InputDecorationTheme(
      hintStyle: const TextStyle(
        color: Color.fromARGB(255, 190, 190, 190),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: const BorderSide(
          color: Color.fromARGB(255, 37, 99, 235),
        ),
      ),
      labelStyle: const TextStyle(
        color: Color.fromARGB(255, 37, 99, 235),
      ),
    ),
  );
}
