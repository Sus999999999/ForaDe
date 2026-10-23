import 'package:flutter/material.dart';

import '../../domain/models/user_role.dart';
import 'user_role_ui.dart';

class RoleBadge extends StatelessWidget {
  final UserRole role;
  final bool onDark;
  const RoleBadge({super.key, required this.role, this.onDark = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: onDark ? Colors.white24 : role.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        role.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: onDark ? Colors.white : role.color,
        ),
      ),
    );
  }
}
