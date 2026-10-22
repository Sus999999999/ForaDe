import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Caja de imagen. Por ahora solo visual (sin función).
class ImageUploadBox extends StatelessWidget {
  final VoidCallback? onTap;
  const ImageUploadBox({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.orange.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(10),
          color: AppColors.orange.withValues(alpha: 0.03),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, color: AppColors.orange),
            SizedBox(height: 5),
            Text(
              'Subir imagen del departamento',
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
