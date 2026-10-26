import 'package:flutter/material.dart';

import 'teranga_colors.dart';
import 'teranga_geometry.dart';
import 'teranga_typography.dart';

/// Construit le [ThemeData] Material 3 de Teranga Immo à partir des
/// tokens du design system. Un seul point d'assemblage : les écrans ne
/// doivent plus déclarer de couleurs ou de styles en dur.
ThemeData buildTerangaTheme() {
  const colorScheme = ColorScheme.light(
    brightness: Brightness.light,
    primary: TerangaColors.gold,
    onPrimary: TerangaColors.white,
    primaryContainer: TerangaColors.beige,
    onPrimaryContainer: TerangaColors.deepBrown,
    secondary: TerangaColors.champagne,
    onSecondary: TerangaColors.deepBrown,
    surface: TerangaColors.white,
    onSurface: TerangaColors.deepBrown,
    surfaceContainerHighest: TerangaColors.beige,
    error: TerangaColors.error,
    onError: TerangaColors.white,
    outline: TerangaColors.border,
    outlineVariant: TerangaColors.border,
    shadow: TerangaColors.shadow,
  );

  final baseText = ThemeData.light().textTheme;

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: TerangaColors.ivory,
    fontFamily: TerangaTypography.interface,

    textTheme: baseText.copyWith(
      displayLarge: TerangaTypography.heroTitle,
      headlineMedium: TerangaTypography.sectionTitle,
      titleLarge: TerangaTypography.editorialCardTitle,
      titleMedium: TerangaTypography.cardTitle,
      bodyLarge: TerangaTypography.body,
      bodyMedium: TerangaTypography.body,
      labelLarge: TerangaTypography.button.copyWith(
        color: TerangaColors.deepBrown,
      ),
      bodySmall: TerangaTypography.meta,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: TerangaColors.ivory,
      foregroundColor: TerangaColors.deepBrown,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TerangaTypography.wordmarkCompact,
      iconTheme: IconThemeData(color: TerangaColors.deepBrown),
    ),

    cardTheme: CardThemeData(
      color: TerangaColors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TerangaRadius.card),
        side: const BorderSide(color: TerangaColors.border),
      ),
    ),

    dividerTheme: const DividerThemeData(
      color: TerangaColors.border,
      thickness: 1,
      space: 1,
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: TerangaColors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: TerangaSpacing.lg,
        vertical: TerangaSpacing.md,
      ),
      hintStyle: TerangaTypography.body.copyWith(color: TerangaColors.taupe),
      labelStyle: TerangaTypography.body.copyWith(color: TerangaColors.taupe),
      helperStyle: TerangaTypography.meta,
      errorStyle: TerangaTypography.meta.copyWith(color: TerangaColors.error),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(TerangaRadius.field),
        borderSide: const BorderSide(color: TerangaColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(TerangaRadius.field),
        borderSide: const BorderSide(color: TerangaColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(TerangaRadius.field),
        borderSide: const BorderSide(
          color: TerangaColors.gold,
          width: 1.4,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(TerangaRadius.field),
        borderSide: const BorderSide(color: TerangaColors.error),
      ),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: TerangaColors.gold,
        foregroundColor: TerangaColors.white,
        disabledBackgroundColor: TerangaColors.gold.withValues(alpha: 0.4),
        minimumSize: const Size.fromHeight(50),
        padding: const EdgeInsets.symmetric(horizontal: TerangaSpacing.xl),
        textStyle: TerangaTypography.button,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TerangaRadius.button),
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: TerangaColors.deepBrown,
        minimumSize: const Size.fromHeight(50),
        padding: const EdgeInsets.symmetric(horizontal: TerangaSpacing.xl),
        textStyle: TerangaTypography.button.copyWith(
          color: TerangaColors.deepBrown,
        ),
        side: const BorderSide(color: TerangaColors.lightBrown),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TerangaRadius.button),
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: TerangaColors.gold,
        textStyle: TerangaTypography.link,
        padding: const EdgeInsets.symmetric(
          horizontal: TerangaSpacing.sm,
          vertical: TerangaSpacing.sm,
        ),
      ),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: TerangaColors.beige,
      labelStyle: TerangaTypography.meta.copyWith(
        color: TerangaColors.deepBrown,
        fontWeight: FontWeight.w600,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TerangaRadius.badge),
      ),
    ),

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: TerangaColors.white,
      indicatorColor: TerangaColors.beige,
      elevation: 0,
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TerangaTypography.navLabel.copyWith(
          color: selected ? TerangaColors.gold : TerangaColors.taupe,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? TerangaColors.gold : TerangaColors.taupe,
          size: 24,
        );
      }),
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: TerangaColors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TerangaRadius.modal),
      ),
      titleTextStyle: TerangaTypography.sectionTitle.copyWith(fontSize: 22),
      contentTextStyle: TerangaTypography.body,
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: TerangaColors.deepBrown,
      contentTextStyle: TerangaTypography.body.copyWith(
        color: TerangaColors.white,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TerangaRadius.button),
      ),
    ),

    dropdownMenuTheme: DropdownMenuThemeData(
      textStyle: TerangaTypography.body,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: TerangaColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: TerangaSpacing.lg,
          vertical: TerangaSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TerangaRadius.field),
          borderSide: const BorderSide(color: TerangaColors.border),
        ),
      ),
    ),
  );
}
