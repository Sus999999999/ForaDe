import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../apartments/domain/models/home_filter.dart';

class _FilterItem {
  final HomeFilter filter;
  final String label;
  final IconData icon;
  const _FilterItem(this.filter, this.label, this.icon);
}

/// Pestañas de categorías con icono y subrayado (como Airbnb).
class FilterTabs extends StatelessWidget {
  final HomeFilter selected;
  final ValueChanged<HomeFilter> onSelected;
  const FilterTabs({super.key, required this.selected, required this.onSelected});

  static const _items = [
    _FilterItem(HomeFilter.all, 'Todos', Icons.home_work_outlined),
    _FilterItem(HomeFilter.available, 'Disponibles', Icons.verified_outlined),
    _FilterItem(HomeFilter.affordable, 'Económicos', Icons.savings_outlined),
    _FilterItem(HomeFilter.newest, 'Nuevos', Icons.auto_awesome_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final item in _items)
          Expanded(
            child: InkWell(
              onTap: () => onSelected(item.filter),
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  children: [
                    Icon(
                      item.icon,
                      size: 26,
                      color: item.filter == selected
                          ? AppColors.navy
                          : AppColors.muted,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: item.filter == selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: item.filter == selected
                            ? AppColors.text
                            : AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 3,
                      width: 34,
                      decoration: BoxDecoration(
                        gradient: item.filter == selected
                            ? AppColors.brandGradient
                            : null,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
