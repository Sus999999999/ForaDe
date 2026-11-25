import 'package:geolocator/geolocator.dart';

import 'geo_point.dart';

/// Origen de la ubicación del usuario.
abstract class LocationService {
  Future<GeoPoint?> currentLocation({bool requestPermissionIfNeeded = true});
}

/// Ubicación GPS real usando el sensor del dispositivo (Android/iOS).
class RealLocationService implements LocationService {
  const RealLocationService();

  @override
  Future<GeoPoint?> currentLocation({bool requestPermissionIfNeeded = true}) async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        if (!requestPermissionIfNeeded) return null;
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      // Obtener rápidamente la última posición conocida para respuesta inmediata
      final last = await Geolocator.getLastKnownPosition();

      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 8),
          ),
        );
        return GeoPoint(pos.latitude, pos.longitude);
      } catch (_) {
        if (last != null) {
          return GeoPoint(last.latitude, last.longitude);
        }
        return null;
      }
    } catch (_) {
      return null;
    }
  }
}

/// Ubicación simulada: siempre devuelve el centro por defecto. Sirve para
/// pruebas sin requerir hardware de GPS.
class SimulatedLocationService implements LocationService {
  const SimulatedLocationService();

  @override
  Future<GeoPoint?> currentLocation({bool requestPermissionIfNeeded = true}) async =>
      GeoPoint.defaultCenter;
}
