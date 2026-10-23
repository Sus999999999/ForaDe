import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class ProfileStat {
  final String value;
  final String label;
  const ProfileStat(this.value, this.label);
}

class ProfileStatsCard extends StatelessWidget {
  final List<ProfileStat> stats;
  const ProfileStatsCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          for (final s in stats) Expanded(child: _Stat(stat: s)),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final ProfileStat stat;
  const _Stat({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          stat.value,
          style: const TextStyle(
            fontFamily: AppColors.serif,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          stat.label,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}
