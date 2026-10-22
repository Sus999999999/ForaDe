import 'package:flutter/foundation.dart';

import '../../features/apartments/domain/models/apartment.dart';
import '../../features/profile/domain/models/user_profile.dart';

/// Estado global en memoria. Se reinicia al cerrar la app.
/// Más adelante se puede reemplazar por una base de datos / API
/// manteniendo esta misma interfaz pública.
class AppState extends ChangeNotifier {
  final List<Apartment> _apartments = [
    const Apartment(
      id: 'seed-1',
      title: 'Departamento Reforma 204',
      location: 'Col. Juárez, CDMX',
      distanceLabel: 'a 1.2 km',
      description:
          'Departamento amueblado ideal para estudiantes, cerca de vías principales, con servicios incluidos y excelente iluminación.',
      price: 8900,
      rating: 4.8,
      hostName: 'Carlos R.',
    ),
    const Apartment(
      id: 'seed-2',
      title: 'Loft Roma Norte',
      location: 'Col. Roma Norte, CDMX',
      distanceLabel: 'a 2.4 km',
      description:
          'Loft de doble altura con cocina integrada, cerca de cafés y transporte público.',
      price: 12500,
      rating: 4.6,
      hostName: 'Ana M.',
    ),
    const Apartment(
      id: 'seed-3',
      title: 'Estudio Polanco',
      location: 'Col. Polanco, CDMX',
      distanceLabel: 'a 4.1 km',
      description:
          'Estudio compacto y luminoso, ideal para una persona. Edificio con gimnasio y seguridad 24 h.',
      price: 15200,
      rating: 4.9,
      hostName: 'Luis G.',
    ),
    const Apartment(
      id: 'seed-4',
      title: 'Casa Condesa',
      location: 'Col. Condesa, CDMX',
      distanceLabel: 'a 3.0 km',
      description:
          'Casa de dos recámaras con terraza, frente a parque. Actualmente en remodelación.',
      price: 18000,
      rating: 4.4,
      hostName: 'Sofía P.',
      isAvailable: false,
    ),
  ];

  final Set<String> _favoriteIds = {};

  UserProfile _profile = const UserProfile(
    name: 'Marina Costa',
    email: 'marina.costa@correo.com',
    phone: '+52 55 1234 5678',
    city: 'Ciudad de México',
  );

  String _searchQuery = '';
  bool _onlyAvailable = false;
  bool _notificationsEnabled = true;

  // ---------- lectura ----------
  UserProfile get profile => _profile;
  String get searchQuery => _searchQuery;
  bool get onlyAvailable => _onlyAvailable;
  bool get notificationsEnabled => _notificationsEnabled;

  List<Apartment> get apartments => List.unmodifiable(_apartments);

  List<Apartment> get myApartments =>
      _apartments.where((a) => a.isOwn).toList();

  List<Apartment> get favorites =>
      _apartments.where((a) => _favoriteIds.contains(a.id)).toList();

  bool isFavorite(String id) => _favoriteIds.contains(id);

  /// Resultados para el buscador del Home.
  List<Apartment> get searchResults {
    final q = _searchQuery.trim().toLowerCase();
    return _apartments.where((a) {
      if (_onlyAvailable && !a.isAvailable) return false;
      if (q.isEmpty) return true;
      return a.title.toLowerCase().contains(q) ||
          a.location.toLowerCase().contains(q);
    }).toList();
  }

  // ---------- acciones ----------
  void setSearchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  /// Devuelve true si quedó marcado como favorito.
  bool toggleFavorite(String id) {
    final added = _favoriteIds.add(id);
    if (!added) _favoriteIds.remove(id);
    notifyListeners();
    return added;
  }

  void clearFavorites() {
    _favoriteIds.clear();
    notifyListeners();
  }

  void addApartment({
    required String title,
    required String description,
    required int price,
    required String location,
  }) {
    _apartments.insert(
      0,
      Apartment(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: title,
        description: description,
        price: price,
        location: location,
        hostName: _profile.name,
        hostSubtitle: 'Propietario',
        isOwn: true,
      ),
    );
    notifyListeners();
  }

  void removeApartment(String id) {
    _apartments.removeWhere((a) => a.id == id);
    _favoriteIds.remove(id);
    notifyListeners();
  }

  void updateProfile(UserProfile profile) {
    _profile = profile;
    notifyListeners();
  }

  void setOnlyAvailable(bool value) {
    _onlyAvailable = value;
    notifyListeners();
  }

  void setNotificationsEnabled(bool value) {
    _notificationsEnabled = value;
    notifyListeners();
  }
}
