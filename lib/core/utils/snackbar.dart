import 'package:flutter/material.dart';

SnackBar _build(String message, IconData? icon, Duration duration) => SnackBar(
      behavior: SnackBarBehavior.floating,
      duration: duration,
      content: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
          ],
          Expanded(child: Text(message)),
        ],
      ),
    );

void showAppSnackBar(
  BuildContext context,
  String message, {
  IconData? icon,
  Duration duration = const Duration(seconds: 3),
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(_build(message, icon, duration));
}

/// Cierra la pantalla actual y muestra el mensaje en la anterior.
void popAndShowSnackBar(BuildContext context, String message,
    {IconData? icon, Duration duration = const Duration(seconds: 3)}) {
  final messenger = ScaffoldMessenger.of(context);
  Navigator.of(context).pop();
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(_build(message, icon, duration));
}
