import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class NoResultsCard extends StatelessWidget {
  const NoResultsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Material(
        color: Colors.white,
        elevation: 8,
        shadowColor: Colors.black26,
        borderRadius: BorderRadius.circular(18),
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(Icons.search_off, size: 32, color: AppColors.muted),
              SizedBox(width: 14),
              Expanded(
                child: Text(
                  'No encontramos departamentos con esa búsqueda.',
                  style: TextStyle(color: AppColors.text, height: 1.3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
