import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Muestra la foto real del departamento si existe (con caché optimizada),
/// o un degradado suave estético con icono de respaldo.
class ApartmentImage extends StatelessWidget {
  final String seed;
  final String? imageUrl;
  final IconData icon;
  final double iconSize;
  final double radius;
  final Widget? child;

  const ApartmentImage({
    super.key,
    required this.seed,
    this.imageUrl,
    this.icon = Icons.apartment_rounded,
    this.iconSize = 44,
    this.radius = 4,
    this.child,
  });

  static const List<List<Color>> _palettes = [
    [Color(0xFFDCE7F7), Color(0xFFBFD3EE)],
    [Color(0xFFFFE3D3), Color(0xFFFBC9AB)],
    [Color(0xFFD9EAF5), Color(0xFFB7D4E8)],
    [Color(0xFFE6E3F7), Color(0xFFCFCAEE)],
    [Color(0xFFE0F0E8), Color(0xFFBFDFCF)],
  ];

  Widget _buildPlaceholder(BuildContext context) {
    final colors = _palettes[seed.hashCode.abs() % _palettes.length];
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: Icon(
              icon,
              size: iconSize,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          if (child != null) child!,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildPlaceholder(context);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: imageUrl!,
            fit: BoxFit.cover,
            placeholder: (context, url) => _buildPlaceholder(context),
            errorWidget: (context, url, error) => _buildPlaceholder(context),
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}
