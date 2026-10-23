import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/user_role.dart';
import '../widgets/role_option_button.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: AppColors.navy,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 36, 24, 36),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white70, width: 1.5),
                      ),
                      child: const Icon(Icons.apartment_rounded,
                          color: Colors.white, size: 36),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Forade',
                      style: TextStyle(
                        fontFamily: AppColors.serif,
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Encuentra y publica departamentos',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 26, 20, 24),
              children: [
                const Text(
                  '¿Cómo quieres entrar?',
                  style: TextStyle(
                    fontFamily: AppColors.serif,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Elige tu tipo de usuario para continuar.',
                  style: TextStyle(fontSize: 13, color: AppColors.muted),
                ),
                const SizedBox(height: 20),
                for (final role in UserRole.values)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: RoleOptionButton(
                      role: role,
                      onTap: () => Navigator.of(context)
                          .pushNamed(AppRoutes.login, arguments: role),
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
