import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class LocateButton extends StatelessWidget {
  final VoidCallback? onTap;
  const LocateButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(
        side: BorderSide(color: AppColors.border),
      ),
      elevation: 3,
      shadowColor: Colors.black26,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 52,
          height: 52,
          child: Icon(Icons.gps_fixed, size: 22, color: AppColors.navy),
        ),
      ),
    );
  }
}
