import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/menu_item_data.dart';

class MenuTile extends StatelessWidget {
  final MenuItemData item;
  final VoidCallback onTap;
  const MenuTile({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 46,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 9),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Text(
          item.label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: item.color,
          ),
        ),
      ),
    );
  }
}
