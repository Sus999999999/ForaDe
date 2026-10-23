import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/models/user_profile.dart';

/// Filas de contacto con borde fino, etiqueta en mayúsculas pequeñas y valor.
class ContactInfoList extends StatelessWidget {
  final UserProfile profile;
  const ContactInfoList({super.key, required this.profile});

  String _or(String value) => value.trim().isEmpty ? 'No especificado' : value;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          _InfoTile(
              icon: Icons.phone_outlined,
              label: 'TELÉFONO',
              text: _or(profile.phone)),
          const Divider(height: 1, color: AppColors.divider),
          _InfoTile(
              icon: Icons.email_outlined,
              label: 'CORREO',
              text: _or(profile.email)),
          const Divider(height: 1, color: AppColors.divider),
          _InfoTile(
              icon: Icons.location_on_outlined,
              label: 'CIUDAD',
              text: _or(profile.city)),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String text;
  const _InfoTile(
      {required this.icon, required this.label, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF7C8EA8), size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  text,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
