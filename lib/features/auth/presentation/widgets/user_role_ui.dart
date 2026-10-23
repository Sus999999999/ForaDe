import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/models/user_role.dart';

/// Datos visuales de cada rol (se mantienen fuera del modelo de dominio).
extension UserRoleUi on UserRole {
  IconData get icon => switch (this) {
        UserRole.rentero => Icons.home_work_outlined,
        UserRole.rentador => Icons.search_rounded,
        UserRole.administrador => Icons.admin_panel_settings_outlined,
      };

  Color get color => switch (this) {
        UserRole.rentero => AppColors.orange,
        UserRole.rentador => AppColors.blue,
        UserRole.administrador => AppColors.navy,
      };
}
