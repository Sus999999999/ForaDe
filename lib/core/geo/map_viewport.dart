import 'dart:math' as math;
import 'dart:ui';

import 'geo_point.dart';

/// Relación entre coordenadas geográficas y posiciones proporcionales (0–1)
/// sobre el mapa dibujado. Cuando se integre un mapa real (google_maps_flutter
/// / flutter_map) esta clase deja de ser necesaria.
class MapViewport {
  final GeoPoint center;

  /// Grados de latitud / longitud que abarca toda el área del mapa.
  final double latSpan;
  final double lngSpan;

  const MapViewport({
    required this.center,
    required this.latSpan,
    required this.lngSpan,
  });

  /// Zona libre del mapa principal (entre el buscador y la tarjeta inferior).
  static const mainZone = Rect.fromLTWH(0.14, 0.27, 0.72, 0.35);

  /// Posición proporcional (0–1) de [p].
  Offset project(GeoPoint p) => Offset(
        0.5 + (p.lng - center.lng) / lngSpan,
        0.5 - (p.lat - center.lat) / latSpan,
      );

  /// Operación inversa de [project].
  GeoPoint unproject(Offset f) => GeoPoint(
        center.lat - (f.dy - 0.5) * latSpan,
        center.lng + (f.dx - 0.5) * lngSpan,
      );

  /// Ajusta el área para que todos los [points] caigan dentro de [zone].
  /// [minSpan] evita un zoom exagerado cuando hay un solo punto.
  factory MapViewport.fit(
    Iterable<GeoPoint> points, {
    Rect zone = mainZone,
    double minSpan = 0.02,
  }) {
    final list = points.toList();
    if (list.isEmpty) {
      return MapViewport(
        center: GeoPoint.defaultCenter,
        latSpan: minSpan / zone.height,
        lngSpan: minSpan / zone.width,
      );
    }

    var minLat = list.first.lat, maxLat = list.first.lat;
    var minLng = list.first.lng, maxLng = list.first.lng;
    for (final p in list) {
      minLat = math.min(minLat, p.lat);
      maxLat = math.max(maxLat, p.lat);
      minLng = math.min(minLng, p.lng);
      maxLng = math.max(maxLng, p.lng);
    }

    final latExtent = math.max(maxLat - minLat, minSpan);
    final lngExtent = math.max(maxLng - minLng, minSpan);
    final cLat = (minLat + maxLat) / 2;
    final cLng = (minLng + maxLng) / 2;

    final latSpan = latExtent / zone.height;
    final lngSpan = lngExtent / zone.width;

    // El centro de los puntos debe quedar en el centro de [zone].
    return MapViewport(
      center: GeoPoint(
        cLat + (zone.center.dy - 0.5) * latSpan,
        cLng - (zone.center.dx - 0.5) * lngSpan,
      ),
      latSpan: latSpan,
      lngSpan: lngSpan,
    );
  }
}
