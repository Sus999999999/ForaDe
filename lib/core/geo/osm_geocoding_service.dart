import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'geo_point.dart';

/// Sugerencia de ubicación obtenida de OpenStreetMap Nominatim.
class LocationSuggestion {
  final String displayName;
  final String title;
  final String subtitle;
  final GeoPoint point;
  final String addressLine;
  final String zone;

  const LocationSuggestion({
    required this.displayName,
    required this.title,
    required this.subtitle,
    required this.point,
    required this.addressLine,
    required this.zone,
  });

  factory LocationSuggestion.fromJson(Map<String, dynamic> json) {
    final lat = double.tryParse(json['lat']?.toString() ?? '') ?? 0.0;
    final lon = double.tryParse(json['lon']?.toString() ?? '') ?? 0.0;
    final displayName = (json['display_name'] as String?)?.trim() ?? '';

    final address = (json['address'] as Map<String, dynamic>?) ?? {};
    final road = (address['road'] as String?)?.trim() ?? '';
    final houseNumber = (address['house_number'] as String?)?.trim() ?? '';
    final suburb = (address['suburb'] as String?)?.trim() ??
        (address['neighbourhood'] as String?)?.trim() ??
        (address['residential'] as String?)?.trim() ??
        (address['quarter'] as String?)?.trim() ??
        '';
    final city = (address['city'] as String?)?.trim() ??
        (address['town'] as String?)?.trim() ??
        (address['municipality'] as String?)?.trim() ??
        (address['county'] as String?)?.trim() ??
        '';
    final state = (address['state'] as String?)?.trim() ?? '';

    // Título principal conciso
    String title = '';
    if (road.isNotEmpty) {
      title = houseNumber.isNotEmpty ? '$road $houseNumber' : road;
    } else if (suburb.isNotEmpty) {
      title = suburb;
    } else if (json['name'] != null && (json['name'] as String).trim().isNotEmpty) {
      title = (json['name'] as String).trim();
    } else {
      title = displayName.split(',').first.trim();
    }

    // Subtítulo con contexto geográfico
    final subParts = <String>[];
    if (suburb.isNotEmpty && title != suburb) subParts.add(suburb);
    if (city.isNotEmpty && title != city) subParts.add(city);
    if (state.isNotEmpty) subParts.add(state);
    String subtitle = subParts.join(', ');
    if (subtitle.isEmpty) {
      final parts = displayName.split(',');
      if (parts.length > 1) {
        subtitle = parts.sublist(1).take(3).map((e) => e.trim()).join(', ');
      }
    }

    // Sugerencia para el campo de Zona (visible para todos)
    String zone = '';
    if (suburb.isNotEmpty && city.isNotEmpty) {
      zone = 'Col. $suburb, $city';
    } else if (suburb.isNotEmpty) {
      zone = 'Col. $suburb';
    } else if (city.isNotEmpty) {
      zone = city;
    }

    // Línea de dirección para el campo de Dirección exacta (privada)
    String addressLine = '';
    if (road.isNotEmpty) {
      addressLine = houseNumber.isNotEmpty ? '$road $houseNumber' : road;
      if (suburb.isNotEmpty) addressLine += ', Col. $suburb';
    } else {
      addressLine = title;
      if (suburb.isNotEmpty && !addressLine.contains(suburb)) {
        addressLine += ', $suburb';
      }
    }

    return LocationSuggestion(
      displayName: displayName,
      title: title,
      subtitle: subtitle,
      point: GeoPoint(lat, lon),
      addressLine: addressLine,
      zone: zone,
    );
  }
}

/// Servicio gratuito de geocodificación y autocompletado usando OpenStreetMap Nominatim.
class OsmGeocodingService {
  final http.Client _client;

  OsmGeocodingService({http.Client? client}) : _client = client ?? http.Client();

  /// Busca sugerencias de ubicaciones basadas en el texto [query].
  Future<List<LocationSuggestion>> search(
    String query, {
    String? countryCode = 'mx',
  }) async {
    final clean = query.trim();
    if (clean.length < 3) return const [];

    // Intento 1: filtrado por país si está configurado (por defecto 'mx')
    var results = await _executeRequest(clean, countryCode: countryCode);

    // Si no arrojó resultados y había filtro de país, reintenta de forma global
    if (results.isEmpty && countryCode != null) {
      results = await _executeRequest(clean, countryCode: null);
    }

    return results;
  }

  Future<List<LocationSuggestion>> _executeRequest(
    String query, {
    String? countryCode,
  }) async {
    try {
      final params = <String, String>{
        'q': query,
        'format': 'jsonv2',
        'addressdetails': '1',
        'limit': '5',
      };
      if (countryCode != null && countryCode.isNotEmpty) {
        params['countrycodes'] = countryCode;
      }

      final uri = Uri.https('nominatim.openstreetmap.org', '/search', params);

      final response = await _client.get(
        uri,
        headers: const {
          'User-Agent': 'ForadeApp/1.0 (https://forade.app; contact@forade.app)',
          'Accept-Language': 'es',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) return const [];

      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data is! List) return const [];

      return data
          .map((item) => LocationSuggestion.fromJson(item as Map<String, dynamic>))
          .where((s) => s.point.lat != 0.0 && s.point.lng != 0.0)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// Obtiene la dirección aproximada a partir de coordenadas exactas (geocodificación inversa).
  Future<LocationSuggestion?> reverseGeocode(GeoPoint point) async {
    try {
      final uri = Uri.https(
        'nominatim.openstreetmap.org',
        '/reverse',
        {
          'lat': point.lat.toString(),
          'lon': point.lng.toString(),
          'format': 'jsonv2',
          'addressdetails': '1',
        },
      );

      final response = await _client.get(
        uri,
        headers: const {
          'User-Agent': 'ForadeApp/1.0 (https://forade.app; contact@forade.app)',
          'Accept-Language': 'es',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data is! Map<String, dynamic>) return null;

      return LocationSuggestion.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  void dispose() {
    _client.close();
  }
}
