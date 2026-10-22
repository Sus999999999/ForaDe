import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'map_pin.dart';

/// Mapa de relleno. Se reemplazará por google_maps_flutter / flutter_map.
class MapPlaceholder extends StatelessWidget {
  const MapPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final h = c.maxHeight;
        return Stack(
          children: [
            _block(w * 0.05, h * 0.17, 66, 46),
            _block(w * 0.60, h * 0.30, 52, 76),
            _block(w * 0.27, h * 0.57, 76, 52),
            _block(w * 0.74, h * 0.64, 46, 46),
            Positioned(
                left: w * 0.31, top: h * 0.22, child: const MapPin(size: 28)),
            Positioned(
                left: w * 0.70, top: h * 0.17, child: const MapPin(size: 28)),
            Positioned(
                left: w * 0.50,
                top: h * 0.39,
                child: const MapPin(size: 40, selected: true)),
            Positioned(
                left: w * 0.42, top: h * 0.60, child: const MapPin(size: 24)),
          ],
        );
      },
    );
  }

  static Widget _block(double left, double top, double w, double h) =>
      Positioned(
        left: left,
        top: top,
        child: Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: AppColors.mapBlock.withValues(alpha: 0.7),
            border: Border.all(color: AppColors.mapBlock),
          ),
        ),
      );
}
