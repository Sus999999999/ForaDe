import 'package:flutter/material.dart';

import '../../../../core/geo/geo_point.dart';
import '../../../../core/geo/map_viewport.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../apartments/domain/models/apartment.dart';
import 'map_pin.dart';

/// Coloca un pin por departamento sobre el mapa usando su ubicación
/// APROXIMADA (nunca la exacta) y, si se permitió, un punto azul con la
/// ubicación del usuario.
class MapPinsLayer extends StatelessWidget {
  /// Los departamentos que se muestran ahora.
  final List<Apartment> visible;
  final MapViewport viewport;
  final GeoPoint? userLocation;
  final String? selectedId;
  final ValueChanged<Apartment> onPinTap;

  const MapPinsLayer({
    super.key,
    required this.visible,
    required this.viewport,
    required this.selectedId,
    required this.onPinTap,
    this.userLocation,
  });

  static const double _pinSize = 33;
  static const double _pinSizeSelected = 49;
  static const double _userDot = 18;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        // El seleccionado al final para que quede encima.
        final ordered = [...visible]
          ..sort((a, b) =>
              (a.id == selectedId ? 1 : 0) - (b.id == selectedId ? 1 : 0));

        return Stack(
          children: [
            if (userLocation != null)
              Builder(builder: (_) {
                final at = viewport.project(userLocation!);
                return Positioned(
                  left: c.maxWidth * at.dx - _userDot / 2,
                  top: c.maxHeight * at.dy - _userDot / 2,
                  child: IgnorePointer(
                    child: Container(
                      width: _userDot,
                      height: _userDot,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2F80ED),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 4),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            for (final a in ordered)
              Builder(builder: (_) {
                final selected = a.id == selectedId;
                final size = selected ? _pinSizeSelected : _pinSize;
                final at = viewport.project(a.approxPoint);
                return Positioned(
                  left: c.maxWidth * at.dx - size / 2,
                  top: c.maxHeight * at.dy - size * 1.25,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onPinTap(a),
                    child: MapPin(size: size, selected: selected),
                  ),
                );
              }),
          ],
        );
      },
    );
  }
}

/// Aviso corto sobre el mapa (p. ej. "Ubicación aproximada").
class MapNote extends StatelessWidget {
  final String text;
  const MapNote(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: AppColors.navy,
        ),
      ),
    );
  }
}
