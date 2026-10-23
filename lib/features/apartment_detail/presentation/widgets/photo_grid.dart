import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Foto principal a todo el ancho (blanca hasta que haya imágenes reales),
/// con sombra inferior e indicador de páginas.
class PhotoGrid extends StatefulWidget {
  final String seed;
  final double height;
  const PhotoGrid({super.key, required this.seed, this.height = 310});

  @override
  State<PhotoGrid> createState() => _PhotoGridState();
}

class _PhotoGridState extends State<PhotoGrid> {
  static const _pages = 4;
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: _pages,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, __) => const ColoredBox(color: Colors.white),
          ),
          // Sombra suave en la parte baja de la foto.
          const Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.45, 1],
                    colors: [Color(0x00A3A7AD), AppColors.photoShade],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 18,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _pages; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: i == _page ? 22 : 5,
                    height: 5,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: i == _page ? Colors.white : Colors.white54,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
