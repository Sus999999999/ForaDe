import 'package:flutter/material.dart';

SnackBar _build(String message, IconData? icon) => SnackBar(
      behavior: SnackBarBehavior.floating,
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

void showAppSnackBar(BuildContext context, String message, {IconData? icon}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(_build(message, icon));
}

/// Cierra la pantalla actual y muestra el mensaje en la anterior.
void popAndShowSnackBar(BuildContext context, String message,
    {IconData? icon}) {
  final messenger = ScaffoldMessenger.of(context);
  Navigator.of(context).pop();
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(_build(message, icon));
}
