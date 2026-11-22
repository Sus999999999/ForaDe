import 'package:geolocator/geolocator.dart';

import 'geo_point.dart';

/// Origen de la ubicación del usuario.
abstract class LocationService {
  Future<GeoPoint?> currentLocation();
}

/// Ubicación GPS real usando el sensor del dispositivo (Android/iOS).
class RealLocationService implements LocationService {
  const RealLocationService();

  @override
  Future<GeoPoint?> currentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return GeoPoint(pos.latitude, pos.longitude);
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
  Future<GeoPoint?> currentLocation() async => GeoPoint.defaultCenter;
}
