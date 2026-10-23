import 'package:flutter/material.dart';

/// Barra inferior plana con la acción principal (sin línea superior, como en
/// el diseño).
/// [leading] es opcional: si existe va a la izquierda y la acción a la derecha.
class BottomActionBar extends StatelessWidget {
  final Widget? leading;
  final Widget action;
  const BottomActionBar({super.key, this.leading, required this.action});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: leading == null
              ? action
              : Row(
                  children: [
                    Expanded(child: leading!),
                    const SizedBox(width: 8),
                    action,
                  ],
                ),
        ),
      ),
    );
  }
}
