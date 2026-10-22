import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class KinColors {
  static const primary = Color(0xFF2A7B7B);
  static const secondary = Color(0xFFF1F5F9);
  static const accent = Color(0xFF3B9B9B);
  static const background = Color(0xFFF8FAFC);

  // Texts - High contrast for light mode
  static const text = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF475569);
  static const textOnPrimary = Color(0xFFFFFFFF); // Only for text inside primary colored buttons

  // Status
  static const success = Color(0xFFA2D9A2);
  static const warning = Color(0xFFFFDCA2);
  static const danger = Color(0xFFFFA2A2);

  // Ambients
  static const freezer = Color(0xFFB0E0E6);
  static const fridge = Color(0xFFB2D3C2);
  static const pantry = Color(0xFFE8D7B5);
}

class AppTheme {
  static ThemeData get lightTheme {
    // Technical: Defining base text theme with Figtree for body text
    final baseTextTheme = GoogleFonts.figtreeTextTheme().apply(
      bodyColor: KinColors.text,
      displayColor: KinColors.text,
    );

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: KinColors.background,
      colorScheme: ColorScheme.light(
        primary: KinColors.primary,
        secondary: KinColors.secondary,
        surface: Colors.white,
        onSurface: KinColors.text,
        onPrimary: KinColors.textOnPrimary,
      ),

      // Technical: Titles with Outfit and body Figtree
      textTheme: baseTextTheme.copyWith(
        // Headline/Titles using Outfit for a modern, geometric look
        displayLarge: GoogleFonts.outfit(
          textStyle: baseTextTheme.displayLarge,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          color: KinColors.text,
        ),
        displayMedium: GoogleFonts.outfit(
          textStyle: baseTextTheme.displayMedium,
          fontWeight: FontWeight.w700,
          color: KinColors.text,
        ),
        // Section titles and major card headings
        titleLarge: GoogleFonts.outfit(
          textStyle: baseTextTheme.titleLarge,
          fontWeight: FontWeight.w700,
          fontSize: 20,
          color: KinColors.text,
        ),
        // Item name inside the card
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: KinColors.text,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: KinColors.textSecondary,
        ),
        labelLarge: baseTextTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: KinColors.text,
        ),
      ),

      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shadowColor: KinColors.primary.withValues(alpha: 0.15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // UI Helper: Centralized Decoration for TextFields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        // Applyig specific font style to labels and hints
        labelStyle: GoogleFonts.figtree(
          color: KinColors.text,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: GoogleFonts.figtree(
          color: KinColors.textSecondary.withValues(alpha: 0.6),
          fontWeight: FontWeight.w500,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: KinColors.secondary, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: KinColors.primary, width: 2),
        ),
      ),
    );
  }

  // Helper method for specific screen adjustments (like hint text)
  static InputDecoration inputDecoration({
    required String hint,
    required BuildContext context,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.figtree(
        color: KinColors.textSecondary.withValues(alpha: 0.6),
        fontWeight: FontWeight.w500,
      ),
    );
  }
}