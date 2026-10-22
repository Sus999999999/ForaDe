import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class LocateButton extends StatelessWidget {
  final VoidCallback? onTap;
  const LocateButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      shadowColor: Colors.black26,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 46,
          height: 46,
          child: Icon(Icons.my_location, size: 20, color: AppColors.navy),
        ),
      ),
    );
  }
}
