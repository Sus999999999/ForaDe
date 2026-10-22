import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class HostInfo extends StatelessWidget {
  final String name;
  final String subtitle;
  final String prefix;
  const HostInfo({
    super.key,
    required this.name,
    required this.subtitle,
    this.prefix = 'Publicado por ',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.muted,
          child: Icon(Icons.person, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$prefix$name',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
