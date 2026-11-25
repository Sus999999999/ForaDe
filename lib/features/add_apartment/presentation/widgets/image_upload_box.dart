import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';

/// Selector interactivo de imágenes reales del departamento usando image_picker.
class ImageUploadBox extends StatelessWidget {
  final List<Uint8List> images;
  final ValueChanged<List<Uint8List>> onImagesChanged;

  const ImageUploadBox({
    super.key,
    this.images = const [],
    required this.onImagesChanged,
  });

  Future<void> _pickImages(BuildContext context) async {
    final picker = ImagePicker();

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Seleccionar fotos',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined,
                    color: AppColors.navy),
                title: const Text('Galería de fotos'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              ListTile(
                leading:
                    const Icon(Icons.camera_alt_outlined, color: AppColors.navy),
                title: const Text('Tomar foto con la cámara'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    final newBytesList = <Uint8List>[];
    if (source == ImageSource.gallery) {
      final pickedFiles = await picker.pickMultiImage(imageQuality: 85);
      for (final file in pickedFiles) {
        newBytesList.add(await file.readAsBytes());
      }
    } else {
      final file = await picker.pickImage(source: source, imageQuality: 85);
      if (file != null) {
        newBytesList.add(await file.readAsBytes());
      }
    }

    if (newBytesList.isNotEmpty) {
      onImagesChanged([...images, ...newBytesList]);
    }
  }

  void _removeImage(int index) {
    final updated = List<Uint8List>.from(images)..removeAt(index);
    onImagesChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return InkWell(
        onTap: () => _pickImages(context),
        borderRadius: BorderRadius.circular(8),
        child: CustomPaint(
          painter: _DashedBorderPainter(color: AppColors.blue),
          child: Container(
            height: 132,
            width: double.infinity,
            color: AppColors.uploadFill,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.navy, width: 1.8),
                  ),
                  child: const Icon(Icons.add_a_photo_outlined,
                      size: 22, color: AppColors.navy),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Toca para agregar fotos del departamento',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: images.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              if (index == images.length) {
                return InkWell(
                  onTap: () => _pickImages(context),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 90,
                    decoration: BoxDecoration(
                      color: AppColors.uploadFill,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.blue, width: 1.2),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, color: AppColors.navy, size: 28),
                        SizedBox(height: 4),
                        Text(
                          'Más',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.navy,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final bytes = images[index];
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(
                      bytes,
                      width: 110,
                      height: 110,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removeImage(index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${images.length} ${images.length == 1 ? "foto seleccionada" : "fotos seleccionadas"}',
          style: const TextStyle(fontSize: 12, color: AppColors.muted),
        ),
      ],
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
