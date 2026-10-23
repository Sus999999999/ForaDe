import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Botón de menú (≡) y buscador "Buscar por zona o ciudad...".
class MapTopBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onMenu;

  const MapTopBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.onMenu,
  });

  static const _radius = 14.0;

  BoxDecoration get _box => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F2E5C),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(_radius),
            onTap: onMenu,
            child: Ink(
              width: 54,
              height: 54,
              decoration: _box,
              child: const Icon(Icons.menu, size: 24, color: AppColors.navy),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Container(
            height: 54,
            padding: const EdgeInsets.only(left: 16, right: 6),
            decoration: _box,
            child: Row(
              children: [
                const Icon(Icons.search, size: 20, color: AppColors.muted),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: controller,
                    onChanged: onChanged,
                    textInputAction: TextInputAction.search,
                    cursorColor: AppColors.navy,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.text,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'Buscar por zona o ciudad...',
                      hintStyle: TextStyle(
                        fontSize: 15,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                ),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller,
                  builder: (_, value, __) {
                    if (value.text.isEmpty) return const SizedBox(width: 10);
                    return IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.cancel,
                          size: 20, color: AppColors.border),
                      onPressed: onClear,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
