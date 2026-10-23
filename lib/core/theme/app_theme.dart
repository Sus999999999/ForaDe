import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorSchemeSeed: AppColors.navy,
        scaffoldBackgroundColor: Colors.white,
        dividerColor: AppColors.divider,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: IconThemeData(color: AppColors.navy),
          titleTextStyle: TextStyle(
            fontFamily: AppColors.serif,
            color: AppColors.navy,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.all(Colors.white),
          trackColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? AppColors.orange
                : AppColors.border,
          ),
          trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.navy,
          contentTextStyle: const TextStyle(color: Colors.white),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      );
}
