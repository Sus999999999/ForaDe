import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class ProfileStatsCard extends StatelessWidget {
  final int published;
  final int favorites;
  const ProfileStatsCard({
    super.key,
    required this.published,
    required this.favorites,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _Stat(value: '$published', label: 'PUBLICADOS'),
          Container(height: 25, width: 1, color: AppColors.divider),
          _Stat(value: '$favorites', label: 'FAVORITOS'),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 10),
        ),
      ],
    );
  }
}
