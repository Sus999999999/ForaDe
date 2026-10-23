import 'package:flutter/material.dart';

import '../../../apartments/domain/models/apartment.dart';
import 'map_pin.dart';

/// Coloca un pin por departamento sobre el mapa.
///
/// Las posiciones se expresan como proporción del área (0–1), así se ven igual
/// en cualquier pantalla. Los departamentos de ejemplo tienen posición fija
/// (la del diseño); los nuevos reciben una posición estable calculada a partir
/// de su id, dentro de la zona libre entre el buscador y la tarjeta.
class MapPinsLayer extends StatelessWidget {
  /// Los departamentos que se muestran ahora.
  final List<Apartment> visible;
  final String? selectedId;
  final ValueChanged<Apartment> onPinTap;

  const MapPinsLayer({
    super.key,
    required this.visible,
    required this.selectedId,
    required this.onPinTap,
  });

  static const double _pinSize = 33;
  static const double _pinSizeSelected = 49;

  /// Punta del pin (x, y) en proporción del área.
  static const Map<String, Offset> _anchors = {
    'seed-1': Offset(0.536, 0.467),
    'seed-2': Offset(0.736, 0.263),
    'seed-3': Offset(0.250, 0.329),
    'seed-4': Offset(0.329, 0.597),
  };

  static int _hash(String s) {
    var h = 7;
    for (final c in s.codeUnits) {
      h = (h * 31 + c) & 0x7FFFFFFF;
    }
    return h;
  }

  static Offset _anchorOf(String id) {
    final known = _anchors[id];
    if (known != null) return known;
    final h = _hash(id);
    final fx = 0.14 + ((h % 1000) / 1000) * 0.72;
    final fy = 0.27 + (((h ~/ 1000) % 1000) / 1000) * 0.35;
    return Offset(fx, fy);
  }

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
            for (final a in ordered)
              Builder(builder: (_) {
                final selected = a.id == selectedId;
                final size = selected ? _pinSizeSelected : _pinSize;
                final anchor = _anchorOf(a.id);
                return Positioned(
                  left: c.maxWidth * anchor.dx - size / 2,
                  top: c.maxHeight * anchor.dy - size * 1.25,
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
