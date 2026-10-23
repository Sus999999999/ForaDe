import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Barra superior del diseño: flecha "<" y título serif alineado a la izquierda.
class TitleAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final PreferredSizeWidget? bottom;
  final List<Widget>? actions;
  const TitleAppBar({
    super.key,
    required this.title,
    this.bottom,
    this.actions,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.chevron_left, size: 28),
        color: AppColors.navy,
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: AppColors.serif,
          color: AppColors.text,
          fontWeight: FontWeight.w700,
          fontSize: 24,
        ),
      ),
      centerTitle: false,
      titleSpacing: 0,
      actions: actions,
      bottom: bottom,
    );
  }
}
