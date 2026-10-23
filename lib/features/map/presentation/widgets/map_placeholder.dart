import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Fondo de mapa dibujado con proporciones (no depende de tamaños fijos, así
/// que se ve igual en cualquier pantalla): azul muy claro, calles suaves y
/// unas pocas manzanas. Se reemplazará por un mapa real
/// (google_maps_flutter / flutter_map).
class MapPlaceholder extends StatelessWidget {
  const MapPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.expand(child: CustomPaint(painter: _MapPainter()));
  }
}

class _MapPainter extends CustomPainter {
  const _MapPainter();

  // Manzanas (left, top, right, bottom) en proporción del área.
  static const _blocks = <List<double>>[
    [0.10, 0.20, 0.30, 0.27],
    [0.57, 0.30, 0.73, 0.41],
    [0.21, 0.55, 0.45, 0.63],
    [0.67, 0.61, 0.82, 0.68],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Fondo
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.mapBg);

    // Calles suaves (muy claras y ligeramente difuminadas)
    final road = Paint()
      ..color = const Color(0xB3FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = w * 0.05
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawLine(Offset(w * 0.70, -10), Offset(w * 0.33, h + 10), road);
    canvas.drawLine(Offset(-10, h * 0.36), Offset(w + 10, h * 0.45), road);

    // Manzanas
    final fill = Paint()..color = AppColors.mapBlock;
    final edge = Paint()
      ..color = AppColors.mapBlockBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final b in _blocks) {
      final r = Rect.fromLTRB(w * b[0], h * b[1], w * b[2], h * b[3]);
      canvas.drawRect(r, fill);
      canvas.drawRect(r, edge);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
