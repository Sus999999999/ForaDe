import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Caja de imagen con borde punteado y "+" centrado (como en el diseño).
/// Por ahora solo visual (sin función).
class ImageUploadBox extends StatelessWidget {
  final VoidCallback? onTap;
  const ImageUploadBox({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: CustomPaint(
        painter: _DashedBorderPainter(color: AppColors.blue),
        child: Container(
          height: 132,
          width: double.infinity,
          color: AppColors.uploadFill,
          alignment: Alignment.center,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.navy, width: 1.8),
            ),
            child: const Icon(Icons.add, size: 20, color: AppColors.navy),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  _DashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    const dash = 5.0;
    const gap = 4.0;

    final path = Path()
      ..addRect(Rect.fromLTWH(0.8, 0.8, size.width - 1.6, size.height - 1.6));
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + dash), paint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) => old.color != color;
}
