import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Cinco estrellas: llenas hasta la parte entera de la calificación
/// (4.8 → 4 llenas + 1 vacía), como en el diseño.
class RatingStars extends StatelessWidget {
  final double rating;
  final double size;
  const RatingStars({super.key, required this.rating, this.size = 15});

  @override
  Widget build(BuildContext context) {
    final filled = rating.floor().clamp(0, 5);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 5; i++)
          Icon(
            i < filled ? Icons.star_rounded : Icons.star_outline_rounded,
            size: size,
            color: AppColors.orange,
          ),
      ],
    );
  }
}
