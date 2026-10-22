import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/models/user_profile.dart';

class ContactInfoList extends StatelessWidget {
  final UserProfile profile;
  const ContactInfoList({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _InfoTile(icon: Icons.phone_outlined, text: profile.phone),
        const Divider(color: AppColors.divider),
        _InfoTile(icon: Icons.email_outlined, text: profile.email),
        const Divider(color: AppColors.divider),
        _InfoTile(icon: Icons.location_on_outlined, text: profile.city),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoTile({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.muted),
      title: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: AppColors.text,
        ),
      ),
    );
  }
}
