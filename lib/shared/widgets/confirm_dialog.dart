import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Aceptar',
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      title: Text(title,
          style: const TextStyle(
            fontFamily: AppColors.serif,
            color: AppColors.navy,
            fontWeight: FontWeight.w700,
            fontSize: 19,
          )),
      content: Text(message, style: const TextStyle(color: AppColors.muted)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancelar',
              style: TextStyle(color: AppColors.text)),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(confirmLabel,
              style: const TextStyle(
                  color: AppColors.orange, fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );
  return ok ?? false;
}
