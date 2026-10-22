import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class MapPin extends StatelessWidget {
  final double size;
  final bool selected;
  const MapPin({super.key, this.size = 28, this.selected = false});

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.orange : AppColors.blue;
    return SizedBox(
      width: size,
      height: size * 1.25,
      child: CustomPaint(
        painter: _PinPainter(color),
        child: Align(
          alignment: const Alignment(0, -0.45),
          child: Icon(Icons.apartment_rounded,
              size: size * 0.55, color: Colors.white),
        ),
      ),
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
    final paint = Paint()..color = color;

    final path = Path()
      ..addOval(Rect.fromCircle(center: Offset(r, r), radius: r))
      ..moveTo(r - r * 0.78, r + r * 0.62)
      ..lineTo(r, size.height)
      ..lineTo(r + r * 0.78, r + r * 0.62)
      ..close();

    canvas.drawShadow(path, Colors.black38, 3, false);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PinPainter old) => old.color != color;
}
