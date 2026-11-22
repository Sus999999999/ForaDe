import 'dart:math' as math;

/// Coordenadas geográficas (grados decimales).
class GeoPoint {
  final double lat;
  final double lng;
  const GeoPoint(this.lat, this.lng);

  /// Centro por defecto (Ciudad de México) cuando no hay otra referencia.
  static const defaultCenter = GeoPoint(19.4270, -99.1677);

  static const _earthRadiusKm = 6371.0;

  static double _rad(double deg) => deg * math.pi / 180;

  /// Distancia en kilómetros (fórmula de haversine).
  double distanceKmTo(GeoPoint other) {
    final dLat = _rad(other.lat - lat);
    final dLng = _rad(other.lng - lng);
    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(_rad(lat)) *
            math.cos(_rad(other.lat)) *
            math.pow(math.sin(dLng / 2), 2);
    return 2 * _earthRadiusKm * math.asin(math.min(1.0, math.sqrt(a)));
  }

  /// Hash de 32 bits con buena dispersión. Los multiplicadores son pequeños
  /// a propósito: así los productos caben en 53 bits y el resultado es el
  /// mismo en móvil y en web.
  static int _hash(String s) {
    const mask = 0xFFFFFFFF;
    var h = 2166136261;
    for (final c in s.codeUnits) {
      h = ((h ^ c) * 40503) & mask;
    }
    h ^= h >> 15;
    h = (h * 11291) & mask;
    h ^= h >> 13;
    h = (h * 27459) & mask;
    h ^= h >> 16;
    return h;
  }

  /// Ubicación aproximada para mostrar en la búsqueda pública: desplaza el
  /// punto entre [minMeters] y [maxMeters] en una dirección que depende de
  /// [seed] (siempre la misma para el mismo departamento).
  ///
  /// OJO: en producción este cálculo debe hacerse en el servidor, de modo que
  /// la app pública nunca reciba las coordenadas exactas.
  GeoPoint fuzzed(String seed,
      {double minMeters = 150, double maxMeters = 350}) {
    final h = _hash(seed);
    final angle = ((h % 3600) / 3600) * 2 * math.pi;
    final dist =
        minMeters + (((h >> 12) % 1000) / 1000) * (maxMeters - minMeters);
    final dLat = (dist * math.cos(angle)) / 111320;
    final dLng = (dist * math.sin(angle)) / (111320 * math.cos(_rad(lat)));
    return GeoPoint(lat + dLat, lng + dLng);
  }

  @override
  bool operator ==(Object other) =>
      other is GeoPoint && other.lat == lat && other.lng == lng;

  @override
  int get hashCode => Object.hash(lat, lng);
}
