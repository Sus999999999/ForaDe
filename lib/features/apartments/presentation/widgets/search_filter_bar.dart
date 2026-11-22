import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Caja de búsqueda con botón de filtros (con un contador cuando hay filtros
/// avanzados activos).
class SearchFilterBar extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onFilter;
  final int activeFilters;

  const SearchFilterBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.onFilter,
    this.hint = 'Buscar por título o zona...',
    this.activeFilters = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.only(left: 14, right: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 20, color: AppColors.muted),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              cursorColor: AppColors.navy,
              style: const TextStyle(fontSize: 15, color: AppColors.text),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: hint,
                hintStyle:
                    const TextStyle(fontSize: 15, color: AppColors.muted),
              ),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (_, value, __) => value.text.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Borrar búsqueda',
                    icon: const Icon(Icons.cancel,
                        size: 20, color: AppColors.border),
                    onPressed: onClear,
                  ),
          ),
          FilterButton(count: activeFilters, onPressed: onFilter),
        ],
      ),
    );
  }
}

/// Icono de filtros con un globito que indica cuántos hay activos.
class FilterButton extends StatelessWidget {
  final int count;
  final VoidCallback onPressed;
  const FilterButton({super.key, required this.count, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Filtros',
      onPressed: onPressed,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            Icons.tune,
            size: 24,
            color: count > 0 ? AppColors.orange : AppColors.navy,
          ),
          if (count > 0)
            Positioned(
              right: -6,
              top: -6,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.orange,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
