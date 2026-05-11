import 'package:flutter/material.dart';

import 'core/widgets/qrmart_branding.dart';

class AppTheme {
  static ThemeData build() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: QrMartPalette.primary,
        brightness: Brightness.light,
      ).copyWith(
        primary: QrMartPalette.primary,
        onPrimary: Colors.white,
        primaryContainer: QrMartPalette.primarySoft,
        onPrimaryContainer: QrMartPalette.ink,
        secondary: QrMartPalette.leaf,
        onSecondary: Colors.white,
        secondaryContainer: const Color(0xFFE8F2EB),
        onSecondaryContainer: QrMartPalette.ink,
        tertiary: QrMartPalette.accentGold,
        onTertiary: Colors.white,
        tertiaryContainer: const Color(0xFFFFF0DB),
        onTertiaryContainer: QrMartPalette.ink,
        surface: QrMartPalette.surface,
        onSurface: QrMartPalette.ink,
        error: const Color(0xFFB9401E),
        onError: Colors.white,
        errorContainer: const Color(0xFFFFE5DD),
        onErrorContainer: QrMartPalette.ink,
        outline: QrMartPalette.border,
        outlineVariant: const Color(0xFFF0E1D3),
        shadow: QrMartPalette.shadow,
      ),
      scaffoldBackgroundColor: QrMartPalette.background,
    );

    final textTheme = base.textTheme
        .apply(
          bodyColor: QrMartPalette.ink,
          displayColor: QrMartPalette.ink,
        )
        .copyWith(
          displaySmall: _titleStyle(40),
          headlineMedium: _titleStyle(30),
          headlineSmall: _titleStyle(24),
          titleLarge: _sectionStyle(20),
          titleMedium: _sectionStyle(17),
          bodyLarge: const TextStyle(
            fontSize: 16,
            height: 1.5,
            color: QrMartPalette.ink,
          ),
          bodyMedium: const TextStyle(
            fontSize: 14,
            height: 1.5,
            color: QrMartPalette.ink,
          ),
          labelLarge: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          labelMedium: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        );

    final colors = base.colorScheme;

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: QrMartPalette.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: QrMartPalette.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: QrMartPalette.border),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: QrMartPalette.border,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(color: QrMartPalette.ink),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: QrMartPalette.primary,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          backgroundColor: QrMartPalette.primary,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          foregroundColor: QrMartPalette.ink,
          backgroundColor: Colors.white.withOpacity(0.7),
          side: const BorderSide(color: QrMartPalette.border),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: QrMartPalette.primary,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.92),
        hintStyle: const TextStyle(color: QrMartPalette.mutedInk),
        labelStyle: const TextStyle(color: QrMartPalette.mutedInk),
        prefixIconColor: QrMartPalette.mutedInk,
        suffixIconColor: QrMartPalette.mutedInk,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        border: _inputBorder(QrMartPalette.border),
        enabledBorder: _inputBorder(QrMartPalette.border),
        focusedBorder: _inputBorder(QrMartPalette.primary, width: 1.6),
        errorBorder: _inputBorder(colors.error),
        focusedErrorBorder: _inputBorder(colors.error, width: 1.6),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: QrMartPalette.ink,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: QrMartPalette.softSurface,
        selectedColor: QrMartPalette.primarySoft,
        disabledColor: QrMartPalette.softSurface,
        secondarySelectedColor: QrMartPalette.primarySoft,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: QrMartPalette.border),
        ),
        labelStyle: const TextStyle(
          color: QrMartPalette.ink,
          fontWeight: FontWeight.w600,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white.withOpacity(0.96),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 78,
        indicatorColor: QrMartPalette.primarySoft,
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          return TextStyle(
            fontSize: 12,
            fontWeight: states.contains(MaterialState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(MaterialState.selected)
                ? QrMartPalette.primaryDark
                : QrMartPalette.mutedInk,
          );
        }),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(MaterialState.selected)
                ? QrMartPalette.primary
                : QrMartPalette.mutedInk,
          );
        }),
      ),
    );
  }

  static TextStyle _titleStyle(double size) {
    return TextStyle(
      fontSize: size,
      height: 1.08,
      fontWeight: FontWeight.w800,
      color: QrMartPalette.ink,
      letterSpacing: -1.1,
    );
  }

  static TextStyle _sectionStyle(double size) {
    return TextStyle(
      fontSize: size,
      height: 1.2,
      fontWeight: FontWeight.w700,
      color: QrMartPalette.ink,
      letterSpacing: -0.5,
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
