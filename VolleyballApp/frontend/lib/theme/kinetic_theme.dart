import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class KineticTheme {
  // --- Kolory z DESIGN.md ---
  static const Color background = Color(0xFF0B1326);
  static const Color surface = Color(0xFF0B1326);
  static const Color surfaceDim = Color(0xFF0B1326);
  static const Color surfaceBright = Color(0xFF31394D);
  static const Color surfaceContainerLowest = Color(0xFF060E20);
  static const Color surfaceContainerLow = Color(0xFF131B2E);
  static const Color surfaceContainer = Color(0xFF171F33);
  static const Color surfaceContainerHigh = Color(0xFF222A3D);
  static const Color surfaceContainerHighest = Color(0xFF2D3449);
  
  static const Color onSurface = Color(0xFFDAE2FD);
  static const Color onSurfaceVariant = Color(0xFFCFC2D6);
  static const Color inverseSurface = Color(0xFFDAE2FD);
  static const Color inverseOnSurface = Color(0xFF283044);
  
  static const Color outline = Color(0xFF988D9F);
  static const Color outlineVariant = Color(0xFF4D4354);
  
  static const Color primary = Color(0xFFDDB7FF);
  static const Color onPrimary = Color(0xFF490080);
  static const Color primaryContainer = Color(0xFFB76DFF);
  static const Color onPrimaryContainer = Color(0xFF400071);
  static const Color inversePrimary = Color(0xFF842BD2);
  
  static const Color secondary = Color(0xFF4CD7F6);
  static const Color onSecondary = Color(0xFF003640);
  static const Color secondaryContainer = Color(0xFF03B5D3);
  static const Color onSecondaryContainer = Color(0xFF00424E);
  
  static const Color tertiary = Color(0xFFFFB2B7);
  static const Color onTertiary = Color(0xFF67001B);
  static const Color tertiaryContainer = Color(0xFFFF516A);
  static const Color onTertiaryContainer = Color(0xFF5B0017);
  
  static const Color error = Color(0xFFFFB4AB);
  static const Color onError = Color(0xFF690005);
  static const Color errorContainer = Color(0xFF93000A);
  static const Color onErrorContainer = Color(0xFFFFDAD6);

  // --- Czcionki ---
  static TextStyle getDisplayFont({
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    double? letterSpacing,
    double? lineHeight,
  }) {
    return GoogleFonts.hankenGrotesk(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      height: lineHeight,
    );
  }

  static TextStyle getMonoFont({
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    double? letterSpacing,
    double? lineHeight,
  }) {
    return GoogleFonts.jetBrainsMono(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      height: lineHeight,
    );
  }

  // --- Budowa ThemeData ---
  static ThemeData get themeData {
    final baseTheme = ThemeData.dark();
    
    return baseTheme.copyWith(
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: const ColorScheme.dark().copyWith(
        primary: primary,
        onPrimary: onPrimary,
        primaryContainer: primaryContainer,
        onPrimaryContainer: onPrimaryContainer,
        secondary: secondary,
        onSecondary: onSecondary,
        secondaryContainer: secondaryContainer,
        onSecondaryContainer: onSecondaryContainer,
        tertiary: tertiary,
        onTertiary: onTertiary,
        tertiaryContainer: tertiaryContainer,
        onTertiaryContainer: onTertiaryContainer,
        error: error,
        onError: onError,
        errorContainer: errorContainer,
        onErrorContainer: onErrorContainer,
        surface: surface,
        onSurface: onSurface,
        onSurfaceVariant: onSurfaceVariant,
        outline: outline,
        outlineVariant: outlineVariant,
      ),
      
      // Definicje nagłówków i tekstu
      textTheme: baseTheme.textTheme.copyWith(
        displayLarge: GoogleFonts.hankenGrotesk(
          fontSize: 48,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.02 * 48,
          height: 56 / 48,
          color: onSurface,
        ),
        headlineLarge: GoogleFonts.hankenGrotesk(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          height: 40 / 32,
          color: onSurface,
        ),
        headlineMedium: GoogleFonts.hankenGrotesk(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          height: 32 / 24,
          color: onSurface,
        ),
        titleMedium: GoogleFonts.hankenGrotesk(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          height: 24 / 18,
          color: onSurface,
        ),
        bodyMedium: GoogleFonts.hankenGrotesk(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 24 / 16,
          color: onSurface,
        ),
        labelMedium: GoogleFonts.jetBrainsMono(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.05 * 14,
          height: 20 / 14,
          color: onSurfaceVariant,
        ),
      ),
      
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: onSurface),
        titleTextStyle: GoogleFonts.hankenGrotesk(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
        shape: const Border(
          bottom: BorderSide(color: outlineVariant, width: 1.0),
        ),
      ),
      
      cardTheme: CardThemeData(
        color: surfaceContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8), // 0.5rem z DESIGN.md
          side: const BorderSide(color: outlineVariant, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), // 1rem z DESIGN.md
          side: const BorderSide(color: outlineVariant, width: 1),
        ),
        titleTextStyle: GoogleFonts.hankenGrotesk(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: onSurface,
        ),
        contentTextStyle: GoogleFonts.hankenGrotesk(
          fontSize: 16,
          color: onSurfaceVariant,
        ),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryContainer,
          foregroundColor: onPrimaryContainer,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.jetBrainsMono(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.05 * 14,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: onSurface,
          side: const BorderSide(color: outline),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.jetBrainsMono(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.05 * 14,
          ),
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: outlineVariant, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: outlineVariant, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        labelStyle: GoogleFonts.hankenGrotesk(color: onSurfaceVariant),
        hintStyle: GoogleFonts.hankenGrotesk(color: onSurfaceVariant.withAlpha(120)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      
      chipTheme: ChipThemeData(
        backgroundColor: surfaceContainerHighest,
        labelStyle: GoogleFonts.hankenGrotesk(fontSize: 12, color: onSurface),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: outlineVariant, width: 1),
        ),
      ),
    );
  }
}
