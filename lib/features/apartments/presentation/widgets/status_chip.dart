import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/models/apartment_status.dart';

/// Etiqueta con el estado del departamento (Disponible, Ocupado...).
class StatusChip extends StatelessWidget {
  final ApartmentStatus status;
  final bool large;
  const StatusChip({super.key, required this.status, this.large = false});

  static Color colorOf(ApartmentStatus s) => switch (s) {
        ApartmentStatus.disponible => AppColors.blue,
        ApartmentStatus.ocupado => AppColors.orange,
        ApartmentStatus.noDisponible => AppColors.muted,
        ApartmentStatus.inactivo => const Color(0xFF9CA3AF),
      };

  @override
  Widget build(BuildContext context) {
    final color = colorOf(status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 12 : 8,
        vertical: large ? 9 : 3,
      ),
      decoration: BoxDecoration(
        color: large ? color : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(large ? 6 : 4),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: large ? 12.5 : 11,
          fontWeight: FontWeight.w700,
          color: large ? Colors.white : color,
        ),
      ),
    );
  }
}
