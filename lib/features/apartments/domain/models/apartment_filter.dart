import '../../../../core/utils/money.dart';
import 'apartment.dart';
import 'apartment_status.dart';

/// Criterios de búsqueda de departamentos (lista y mapa).
class ApartmentFilter {
  String query; // título, descripción o zona
  Money? minPrice;
  Money? maxPrice;
  String zone; // texto dentro de la zona pública
  ApartmentStatus? status; // null = cualquiera
  double? radiusKm; // null = sin límite (requiere ubicación del usuario)

  ApartmentFilter({
    this.query = '',
    this.minPrice,
    this.maxPrice,
    this.zone = '',
    this.status,
    this.radiusKm,
  });

  ApartmentFilter copy() => ApartmentFilter(
        query: query,
        minPrice: minPrice,
        maxPrice: maxPrice,
        zone: zone,
        status: status,
        radiusKm: radiusKm,
      );

  /// Hay algún criterio distinto a la búsqueda de texto.
  bool get hasAdvanced =>
      minPrice != null ||
      maxPrice != null ||
      zone.trim().isNotEmpty ||
      status != null ||
      radiusKm != null;

  bool get isEmpty => query.trim().isEmpty && !hasAdvanced;

  /// Cuántos criterios avanzados hay activos (para el distintivo del botón).
  int get advancedCount =>
      (minPrice != null || maxPrice != null ? 1 : 0) +
      (zone.trim().isNotEmpty ? 1 : 0) +
      (status != null ? 1 : 0) +
      (radiusKm != null ? 1 : 0);

  /// [distanceKm] es la distancia desde el usuario (null si no se conoce:
  /// entonces el radio se ignora).
  bool matches(Apartment a, {double? distanceKm}) {
    if (status != null && a.status != status) return false;
    if (minPrice != null && a.price < minPrice!) return false;
    if (maxPrice != null && a.price > maxPrice!) return false;

    final z = zone.trim().toLowerCase();
    if (z.isNotEmpty && !a.location.toLowerCase().contains(z)) return false;

    final r = radiusKm;
    if (r != null && distanceKm != null && distanceKm > r) return false;

    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return a.title.toLowerCase().contains(q) ||
        a.description.toLowerCase().contains(q) ||
        a.location.toLowerCase().contains(q);
  }
}
