import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/user_avatar.dart';

class HostInfo extends StatelessWidget {
  final String name;
  final String subtitle;
  final String avatarUrl;

  const HostInfo({
    super.key,
    required this.name,
    required this.subtitle,
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
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Publicado por $name',
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
      ],
    );
  }
}
