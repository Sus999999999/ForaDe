import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Pin en forma de gota con un edificio (azul; el seleccionado va en naranja).
class MapPin extends StatelessWidget {
  final double size;
  final bool selected;
  const MapPin({super.key, this.size = 33, this.selected = false});

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.orange : AppColors.blue;
    return SizedBox(
      width: size,
      height: size * 1.25,
      child: CustomPaint(painter: _PinPainter(color)),
    );
  }
}

class _PinPainter extends CustomPainter {
  final Color color;
  _PinPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final r = w / 2;

    final path = Path()
      ..addOval(Rect.fromCircle(center: Offset(r, r), radius: r))
      ..moveTo(r - r * 0.78, r + r * 0.62)
      ..lineTo(r, size.height)
      ..lineTo(r + r * 0.78, r + r * 0.62)
      ..close();

    canvas.drawShadow(path, Colors.black38, 3, false);
    canvas.drawPath(path, Paint()..color = color);

    // Edificio: cuadro blanco con cuatro ventanas del color del pin.
    final s = w * 0.46;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(r, r), width: s, height: s),
        Radius.circular(s * 0.18),
      ),
      Paint()..color = Colors.white,
    );
    final window = Paint()..color = color;
    final ws = s * 0.2;
    final gap = s * 0.14;
    for (final dx in const [-1, 1]) {
      for (final dy in const [-1, 1]) {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(
              r + dx * (gap / 2 + ws / 2),
              r + dy * (gap / 2 + ws / 2),
            ),
            width: ws,
            height: ws * 1.1,
          ),
          window,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PinPainter old) => old.color != color;
}
