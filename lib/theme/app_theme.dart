import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color bg = Color(0xFF0B0C0E);
  static const Color surface = Color(0xFF111317);
  static const Color surface2 = Color(0xFF181B20);
  static const Color border = Color(0xFF252930);
  
  static const Color accent = Color(0xFFE8FF47);
  static const Color accent2 = Color(0xFFFF4D6A);
  static const Color accent3 = Color(0xFF47C4FF);
  
  static const Color textMain = Color(0xFFD6DAE2);
  static const Color textDim = Color(0xFF5A6070);
  static const Color textBright = Color(0xFFF0F3F8);
  
  static const double radius = 4.0;
  static const double gap = 24.0;

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      primaryColor: accent,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        secondary: accent3,
        surface: surface,
        error: accent2,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: textMain,
        onError: Colors.white,
      ),
      textTheme: GoogleFonts.dmSansTextTheme(ThemeData.dark().textTheme).copyWith(
        bodyLarge: GoogleFonts.dmSans(color: textMain),
        bodyMedium: GoogleFonts.dmSans(color: textMain),
        bodySmall: GoogleFonts.dmSans(color: textDim),
        titleLarge: GoogleFonts.spaceMono(color: textBright, fontWeight: FontWeight.bold),
        titleMedium: GoogleFonts.spaceMono(color: textBright, fontWeight: FontWeight.bold),
        titleSmall: GoogleFonts.spaceMono(color: textMain, fontWeight: FontWeight.bold),
        labelLarge: GoogleFonts.spaceMono(color: textDim, letterSpacing: 1.2),
        labelMedium: GoogleFonts.spaceMono(color: textDim, letterSpacing: 1.2),
        labelSmall: GoogleFonts.spaceMono(color: textDim, letterSpacing: 1.2),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: textBright),
        titleTextStyle: GoogleFonts.spaceMono(
          color: textBright,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
      cardTheme: CardTheme(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: const BorderSide(color: border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          textStyle: GoogleFonts.spaceMono(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textMain,
          side: const BorderSide(color: border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          textStyle: GoogleFonts.spaceMono(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: GoogleFonts.dmSans(color: textDim.withOpacity(0.6)),
        labelStyle: GoogleFonts.spaceMono(color: textDim, letterSpacing: 1.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: accent),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: accent2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: accent2),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: accent,
        unselectedItemColor: textDim,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: const BorderSide(color: border),
        ),
        titleTextStyle: GoogleFonts.spaceMono(
          color: textBright,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: GoogleFonts.dmSans(color: textMain),
      ),
    );
  }
}
