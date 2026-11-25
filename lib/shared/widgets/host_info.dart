import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'user_avatar.dart';

class HostInfo extends StatelessWidget {
  final String name;
  final String subtitle;
  final String prefix;
  final String avatarUrl;

  const HostInfo({
    super.key,
    required this.name,
    required this.subtitle,
    this.prefix = 'Publicado por ',
    this.avatarUrl = '',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        UserAvatar(
          avatarUrl: avatarUrl,
          name: name,
          size: 54,
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
