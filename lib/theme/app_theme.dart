import 'package:flutter/material.dart';

class AppColors {
  static const Color midnight = Color(0xFF101820);
  static const Color deepNavy = Color(0xFF0B131A);
  static const Color slateSurface = Color(0xFF18232D);
  static const Color raisedSlate = Color(0xFF22303C);
  static const Color softDivider = Color(0xFF33414D);

  static const Color primaryText = Color(0xFFF5F7FA);
  static const Color secondaryText = Color(0xFFAAB7C4);
  static const Color mutedText = Color(0xFF758493);
  static const Color disabledText = Color(0xFF56636E);

  static const Color openGreen = Color(0xFF22C55E);
  static const Color deepGreen = Color(0xFF16A34A);
  static const Color signalBlue = Color(0xFF3B82F6);
  static const Color deepBlue = Color(0xFF2563EB);

  static const Color connectingBlue = Color(0xFF60A5FA);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.midnight,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.slateSurface,
        onSurface: AppColors.primaryText,
        primary: AppColors.openGreen,
        onPrimary: Colors.white,
        secondary: AppColors.signalBlue,
        onSecondary: Colors.white,
        error: AppColors.error,
        onError: Colors.white,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.slateSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          side: BorderSide(color: AppColors.softDivider, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.softDivider,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.raisedSlate,
        hintStyle: const TextStyle(color: AppColors.mutedText),
        prefixIconColor: AppColors.secondaryText,
        suffixIconColor: AppColors.secondaryText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.softDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.softDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.signalBlue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.raisedSlate,
        selectedColor: AppColors.signalBlue,
        secondarySelectedColor: AppColors.openGreen,
        disabledColor: AppColors.disabledText,
        labelStyle: const TextStyle(color: AppColors.primaryText, fontSize: 13),
        secondaryLabelStyle: const TextStyle(color: Colors.white, fontSize: 13),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.softDivider),
        ),
        side: const BorderSide(color: AppColors.softDivider),
      ),
    );
  }
}
