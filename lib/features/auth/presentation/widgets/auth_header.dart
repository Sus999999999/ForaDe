import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Cabecera azul con la marca (pantallas de acceso).
class AuthHeader extends StatelessWidget {
  final String subtitle;
  const AuthHeader({super.key, this.subtitle = 'Encuentra y publica departamentos'});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.navy,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white70, width: 1.5),
                ),
                child: const Icon(Icons.apartment_rounded,
                    color: Colors.white, size: 32),
              ),
              const SizedBox(height: 14),
              const Text(
                'Forade',
                style: TextStyle(
                  fontFamily: AppColors.serif,
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
