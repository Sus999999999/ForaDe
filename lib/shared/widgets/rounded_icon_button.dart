import 'package:flutter/material.dart';

class RoundedIconButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  const RoundedIconButton({super.key, required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      shadowColor: Colors.black12,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(width: 46, height: 46, child: child),
      ),
    );
  }
}
