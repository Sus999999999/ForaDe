import 'package:flutter/foundation.dart';

import '../../features/apartments/domain/models/apartment.dart';
import '../../features/apartments/domain/models/home_filter.dart';
import '../../features/auth/domain/models/user_role.dart';
import '../../features/profile/domain/models/user_profile.dart';

/// Estado global en memoria. Se reinicia al cerrar la app.
/// Más adelante se puede reemplazar por una base de datos / API
/// manteniendo esta misma interfaz pública.
class AppState extends ChangeNotifier {
  /// Precio máximo del filtro "Económicos".
  static const affordableLimit = 10000;

  // ------------------------------------------------------------------
  // Datos de ejemplo
  // ------------------------------------------------------------------
  final List<UserProfile> _users = [
    const UserProfile(
      id: 'u-carlos',
      role: UserRole.rentero,
      name: 'Carlos R.',
      email: 'carlos.r@correo.com',
      phone: '+52 55 1111 2222',
      city: 'Ciudad de México',
    ),
    const UserProfile(
      id: 'u-ana',
      role: UserRole.rentero,
      name: 'Ana M.',
      email: 'ana.m@correo.com',
      phone: '+52 55 3333 4444',
      city: 'Ciudad de México',
    ),
    const UserProfile(
      id: 'u-luis',
      role: UserRole.rentero,
      name: 'Luis G.',
      email: 'luis.g@correo.com',
      phone: '+52 55 5555 6666',
      city: 'Ciudad de México',
    ),
    const UserProfile(
      id: 'u-sofia',
      role: UserRole.rentero,
      name: 'Sofía P.',
      email: 'sofia.p@correo.com',
      phone: '+52 55 7777 8888',
      city: 'Ciudad de México',
    ),
    const UserProfile(
      id: 'u-diego',
      role: UserRole.rentador,
      name: 'Diego Torres',
      email: 'diego.t@correo.com',
      phone: '+52 55 9999 0000',
      city: 'Guadalajara',
    ),
    const UserProfile(
      id: 'u-admin',
      role: UserRole.administrador,
      name: 'Administrador General',
      email: 'admin@forade.com',
      city: 'Ciudad de México',
    ),
  ];

  final List<Apartment> _apartments = [
    const Apartment(
      id: 'seed-1',
      ownerId: 'u-carlos',
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
      ownerId: 'u-ana',
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
      ownerId: 'u-luis',
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
      ownerId: 'u-sofia',
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

  /// Favoritos por usuario (userId -> ids de departamentos).
  final Map<String, Set<String>> _favoritesByUser = {};

  UserProfile? _currentUser;
  String _searchQuery = '';
  HomeFilter _homeFilter = HomeFilter.all;

  // ------------------------------------------------------------------
  // Sesión y permisos
  // ------------------------------------------------------------------
  bool get isLoggedIn => _currentUser != null;
  UserProfile get profile => _currentUser ?? UserProfile.guest;
  UserRole? get role => _currentUser?.role;

  bool get isAdmin => role == UserRole.administrador;
  bool get canPublish => role == UserRole.rentero;
  bool get canFavorite =>
      role == UserRole.rentero || role == UserRole.rentador;

  /// Inicio de sesión básico (sin contraseña). La identidad de un usuario es
  /// correo + tipo de usuario: si ya existe, se reutiliza su cuenta (y sus
  /// departamentos); si no, se crea una nueva.
  void login({
    required UserRole role,
    required String name,
    required String email,
    String phone = '',
    String city = '',
  }) {
    final normalized = email.trim().toLowerCase();
    final i = _users.indexWhere(
      (u) => u.role == role && u.email.toLowerCase() == normalized,
    );

    if (i >= 0) {
      final old = _users[i];
      final updated = old.copyWith(
        name: name.trim(),
        phone: phone.trim().isNotEmpty ? phone.trim() : old.phone,
        city: city.trim().isNotEmpty ? city.trim() : old.city,
      );
      _users[i] = updated;
      _currentUser = updated;
      _syncHostName(updated.id, updated.name);
    } else {
      final user = UserProfile(
        id: 'u-${DateTime.now().microsecondsSinceEpoch}',
        role: role,
        name: name.trim(),
        email: email.trim(),
        phone: phone.trim(),
        city: city.trim(),
      );
      _users.add(user);
      _currentUser = user;
    }
    _searchQuery = '';
    _homeFilter = HomeFilter.all;
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    _searchQuery = '';
    _homeFilter = HomeFilter.all;
    notifyListeners();
  }

  // ------------------------------------------------------------------
  // Lectura
  // ------------------------------------------------------------------
  String get searchQuery => _searchQuery;
  HomeFilter get homeFilter => _homeFilter;

  /// true si hay búsqueda o filtro activo en el Home.
  bool get isFiltering =>
      _searchQuery.trim().isNotEmpty || _homeFilter != HomeFilter.all;

  List<UserProfile> get users => List.unmodifiable(_users);
  List<Apartment> get apartments => List.unmodifiable(_apartments);

  Apartment? apartmentById(String id) {
    for (final a in _apartments) {
      if (a.id == id) return a;
    }
    return null;
  }

  List<Apartment> get myApartments =>
      _apartments.where((a) => a.ownerId == _currentUser?.id).toList();

  int apartmentCountOf(String userId) =>
      _apartments.where((a) => a.ownerId == userId).length;

  Set<String> get _myFavoriteIds {
    final user = _currentUser;
    if (user == null) return <String>{};
    return _favoritesByUser[user.id] ?? <String>{};
  }

  List<Apartment> get favorites =>
      _apartments.where((a) => _myFavoriteIds.contains(a.id)).toList();

  bool isFavorite(String id) => _myFavoriteIds.contains(id);

  /// Resultados para el buscador del Home.
  List<Apartment> get searchResults {
    final q = _searchQuery.trim().toLowerCase();
    return _apartments.where((a) {
      switch (_homeFilter) {
        case HomeFilter.all:
          break;
        case HomeFilter.available:
          if (!a.isAvailable) return false;
        case HomeFilter.affordable:
          if (a.price > affordableLimit) return false;
        case HomeFilter.newest:
          if (a.rating > 0) return false;
      }
      if (q.isEmpty) return true;
      return a.title.toLowerCase().contains(q) ||
          a.location.toLowerCase().contains(q);
    }).toList();
  }

  // ------------------------------------------------------------------
  // Búsqueda y favoritos
  // ------------------------------------------------------------------
  void setSearchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  void setHomeFilter(HomeFilter filter) {
    _homeFilter = filter;
    notifyListeners();
  }

  /// Devuelve true si quedó marcado como favorito.
  bool toggleFavorite(String id) {
    final user = _currentUser;
    if (user == null || !canFavorite) return false;
    final set = _favoritesByUser.putIfAbsent(user.id, () => <String>{});
    final added = set.add(id);
    if (!added) set.remove(id);
    notifyListeners();
    return added;
  }

  void clearFavorites() {
    final user = _currentUser;
    if (user == null) return;
    _favoritesByUser[user.id]?.clear();
    notifyListeners();
  }

  // ------------------------------------------------------------------
  // Departamentos
  // ------------------------------------------------------------------
  /// Solo los renteros pueden publicar.
  void addApartment({
    required String title,
    required String description,
    required int price,
    required String location,
    String contact = '',
  }) {
    final user = _currentUser;
    if (user == null || !canPublish) return;
    _apartments.insert(
      0,
      Apartment(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        ownerId: user.id,
        title: title,
        description: description,
        price: price,
        location: location,
        hostName: user.name,
        hostSubtitle: 'Propietario',
        contact: contact,
      ),
    );
    notifyListeners();
  }

  /// Uso: rentero (sus propios departamentos) y administrador (cualquiera).
  void removeApartment(String id) {
    _apartments.removeWhere((a) => a.id == id);
    for (final favs in _favoritesByUser.values) {
      favs.remove(id);
    }
    notifyListeners();
  }

  /// Uso: administrador.
  void updateApartment(Apartment updated) {
    final i = _apartments.indexWhere((a) => a.id == updated.id);
    if (i < 0) return;
    _apartments[i] = updated;
    notifyListeners();
  }

  // ------------------------------------------------------------------
  // Usuarios
  // ------------------------------------------------------------------
  /// Actualiza un usuario (perfil propio o edición del administrador).
  void updateUser(UserProfile updated) {
    final i = _users.indexWhere((u) => u.id == updated.id);
    if (i < 0) return;
    _users[i] = updated;
    if (_currentUser?.id == updated.id) _currentUser = updated;
    _syncHostName(updated.id, updated.name);
    notifyListeners();
  }

  /// Elimina un usuario y todos sus departamentos.
  /// Devuelve false si se intenta borrar la cuenta con la sesión activa.
  bool deleteUser(String id) {
    if (id == _currentUser?.id) return false;
    _purgeUser(id);
    notifyListeners();
    return true;
  }

  /// Elimina la cuenta con la sesión activa (y sus departamentos)
  /// y cierra la sesión.
  void deleteCurrentAccount() {
    final user = _currentUser;
    if (user == null) return;
    _purgeUser(user.id);
    _currentUser = null;
    _searchQuery = '';
    _homeFilter = HomeFilter.all;
    notifyListeners();
  }

  void _purgeUser(String id) {
    final ownedIds =
        _apartments.where((a) => a.ownerId == id).map((a) => a.id).toSet();
    _apartments.removeWhere((a) => a.ownerId == id);
    _users.removeWhere((u) => u.id == id);
    _favoritesByUser.remove(id);
    for (final favs in _favoritesByUser.values) {
      favs.removeAll(ownedIds);
    }
  }

  void _syncHostName(String userId, String name) {
    for (var i = 0; i < _apartments.length; i++) {
      final a = _apartments[i];
      if (a.ownerId == userId && a.hostName != name) {
        _apartments[i] = a.copyWith(hostName: name);
      }
    }
  }
}
