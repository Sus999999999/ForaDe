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
        // Círculo vacío (espacio de la foto de perfil).
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border, width: 1.4),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$prefix$name',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(color: AppColors.muted, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
