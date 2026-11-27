import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../features/apartments/domain/models/apartment.dart';
import '../../features/apartments/domain/models/apartment_filter.dart';
import '../../features/apartments/domain/models/apartment_status.dart';
import '../../features/apartments/domain/models/home_filter.dart';
import '../../features/auth/domain/models/user_role.dart';
import '../../features/chat/domain/models/chat_models.dart';
import '../../features/favorites/domain/models/favorite.dart';
import '../../features/profile/domain/models/user_profile.dart';
import '../../features/stays/domain/models/stay.dart';
import '../geo/geo_point.dart';
import '../geo/location_service.dart';
import '../security/password_hasher.dart';
import '../services/notification_service.dart';
import '../services/supabase_service.dart';
import '../utils/formatters.dart';
import '../utils/money.dart';
import '../utils/validators.dart';

/// Solicitud de recuperación de acceso (código de un solo uso).
class _RecoveryRequest {
  final String code;
  final DateTime expiresAt;
  int attempts = 0;
  _RecoveryRequest(this.code, this.expiresAt);
}

/// Estado global en memoria. Se reinicia al cerrar la app.
/// Más adelante se puede reemplazar por una base de datos / API
/// manteniendo esta misma interfaz pública.
class AppState extends ChangeNotifier {
  AppState({LocationService? locationService})
      : _locationService = locationService ?? const RealLocationService();

  final LocationService _locationService;

  /// Contraseña de las cuentas de demo local (solo para desarrollo):
  /// admin@forade.com (administrador).
  static const demoPassword = 'Forade2026';

  /// Intentos de inicio de sesión fallidos antes de bloquear el correo.
  static const maxFailedLogins = 5;
  static const loginLockDuration = Duration(minutes: 1);
  static const _recoveryCodeLifetime = Duration(minutes: 10);
  static const _maxRecoveryAttempts = 5;

  // ------------------------------------------------------------------
  // Usuarios registrados
  // ------------------------------------------------------------------
  final List<UserProfile> _users = [];

  /// Credenciales: id de usuario -> hash PBKDF2 (nunca la contraseña).
  final Map<String, String> _credentials = {};

  /// Cuentas cuyo hash se calcula la primera vez que se necesita (local demo)
  final Set<String> _seedUserIds = {'u-admin'};

  /// Perfil local del administrador (solo para autenticación local; no aparece
  /// en la lista de usuarios del panel de administración).
  static const _localAdminProfile = UserProfile(
    id: 'u-admin',
    role: UserRole.administrador,
    name: 'Administrador',
    email: 'admin@forade.com',
    city: 'Ciudad de México',
  );

  /// Busca un usuario por correo incluyendo el admin local.
  UserProfile? _findLocalUser(String lowerEmail) {
    if (lowerEmail == 'admin@forade.com') return _localAdminProfile;
    return null;
  }

  final Map<String, int> _failedLogins = {};
  final Map<String, DateTime> _lockedUntil = {};
  final Map<String, _RecoveryRequest> _recovery = {};

  final List<Apartment> _apartments = [];

  final List<Stay> _stays = [];

  /// Conversaciones temporales: solo existen mientras no se finalicen.
  final List<ChatConversation> _chats = [];

  /// Favoritos: a lo más uno por usuario y departamento.
  final List<Favorite> _favorites = [];

  UserProfile? _currentUser;
  ApartmentFilter _mapFilter = ApartmentFilter();
  GeoPoint? _userLocation;
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
      role == UserRole.rentero ||
      role == UserRole.rentador ||
      role == UserRole.administrador;
  bool get canChat => role == UserRole.rentero || role == UserRole.rentador;

  UserProfile? _userByEmail(String lowerEmail) {
    if (lowerEmail.isEmpty) return null;
    for (final u in _users) {
      if (u.email.trim().toLowerCase() == lowerEmail) return u;
    }
    return null;
  }

  String? _credentialOf(String userId) {
    final stored = _credentials[userId];
    if (stored != null) return stored;
    if (_seedUserIds.contains(userId)) {
      return _credentials[userId] = PasswordHasher.hash(demoPassword);
    }
    return null;
  }

  void _resetSession() {
    _mapFilter = ApartmentFilter();
  }

  /// Restaura la sesión activa de Supabase y descarga departamentos.
  Future<void> restoreSession() async {
    try {
      if (SupabaseService.instance.hasSession) {
        final profile = await SupabaseService.instance.getCurrentProfile();
        if (profile != null) {
          _currentUser = profile;
        }
      }
      final remoteApts = await SupabaseService.instance.fetchApartmentsWithRetry();
      if (remoteApts.isNotEmpty) {
        _apartments
          ..clear()
          ..addAll(remoteApts);
      }
      await fetchRemoteProfiles();
      if (_currentUser != null) {
        await _loadFavoritesFromSupabase();
        await _loadChatsFromSupabase();
        await _loadStaysFromSupabase();
      }
      await autoRestoreLocation();
      notifyListeners();
    } catch (_) {}
  }

  /// Busca departamentos en Supabase nuevamente si no se encuentra ninguno,
  /// con un límite de [maxRetries] reintentos (por defecto 5).
  Future<List<Apartment>> fetchApartmentsWithRetry({
    int maxRetries = 5,
    Duration delay = const Duration(milliseconds: 600),
  }) async {
    final remoteApts = await SupabaseService.instance.fetchApartmentsWithRetry(
      maxRetries: maxRetries,
      delay: delay,
    );
    if (remoteApts.isNotEmpty) {
      _apartments
        ..clear()
        ..addAll(remoteApts);
      notifyListeners();
    }
    return List.unmodifiable(_apartments);
  }

  /// Alias de [fetchApartmentsWithRetry] para buscar departamentos con reintentos si no hay ninguno.
  Future<List<Apartment>> buscarDepartamentosConReintentos({
    int maxRetries = 5,
    Duration delay = const Duration(milliseconds: 600),
  }) =>
      fetchApartmentsWithRetry(maxRetries: maxRetries, delay: delay);

  /// Recarga departamentos y usuarios de Supabase para la vista de administración.
  Future<void> refreshAdminData() async {
    try {
      final remoteApts = await SupabaseService.instance.fetchApartments();
      _apartments
        ..clear()
        ..addAll(remoteApts);
      await fetchRemoteProfiles();
      notifyListeners();
    } catch (_) {}
  }

  /// Carga perfiles remotos desde Supabase y los sincroniza con la sesión local.
  Future<void> fetchRemoteProfiles() async {
    try {
      final remote = await SupabaseService.instance.fetchProfiles();
      final current = _currentUser;
      _users
        ..clear()
        ..addAll(remote.map((p) {
          // Si es el usuario actualmente autenticado y su correo remoto está vacío,
          // preservar el correo real provisto por la sesión de Auth.
          if (current != null &&
              p.id == current.id &&
              current.email.isNotEmpty &&
              p.email.isEmpty) {
            return p.copyWith(email: current.email);
          }
          return p;
        }));
      // Si el usuario actual no figura en la lista remota (p. ej. recién registrado o RLS temporal),
      // asegurarnos de incluirlo al inicio.
      if (current != null && !_users.any((u) => u.id == current.id)) {
        _users.insert(0, current);
      }
      notifyListeners();
    } catch (_) {}
  }

  /// Inicia sesión con correo y contraseña. Intenta Supabase primero;
  /// si falla o si es una cuenta de prueba local, recurre a las cuentas demo.
  Future<String?> login({required String email, required String password}) async {
    final key = email.trim().toLowerCase();

    // 1. Intentar inicio de sesión con Supabase
    final supabaseError = await SupabaseService.instance.signIn(
      email: key,
      password: password,
    );

    if (supabaseError == null) {
      final profile = await SupabaseService.instance.getCurrentProfile();
      if (profile != null) {
        _currentUser = profile;
        _resetSession();
        // Cargar departamentos actualizados desde Supabase
        final remoteApts = await SupabaseService.instance.fetchApartmentsWithRetry();
        if (remoteApts.isNotEmpty) {
          _apartments
            ..clear()
            ..addAll(remoteApts);
        }
        await fetchRemoteProfiles();
        await _loadFavoritesFromSupabase();
        await _loadChatsFromSupabase();
        await _loadStaysFromSupabase();
        await autoRestoreLocation();
        notifyListeners();
        return null;
      }
    }

    // 2. Si no es cuenta remota o falla la red, verificar cuentas locales demo
    final lockedUntil = _lockedUntil[key];
    if (lockedUntil != null) {
      if (DateTime.now().isBefore(lockedUntil)) {
        return 'Demasiados intentos fallidos. Intenta de nuevo en un minuto.';
      }
      _lockedUntil.remove(key);
      _failedLogins.remove(key);
    }

    // Buscar primero en los perfiles locales (admin local hardcodeado)
    final user = _findLocalUser(key) ?? _userByEmail(key);
    final credential = user == null ? null : _credentialOf(user.id);
    final ok = user != null &&
        credential != null &&
        PasswordHasher.verify(password, credential);

    if (!ok) {
      final failures = (_failedLogins[key] ?? 0) + 1;
      if (failures >= maxFailedLogins) {
        _lockedUntil[key] = DateTime.now().add(loginLockDuration);
        _failedLogins.remove(key);
      } else {
        _failedLogins[key] = failures;
      }
      return supabaseError ?? 'Correo o contraseña incorrectos.';
    }

    _failedLogins.remove(key);
    _currentUser = user;
    _resetSession();
    // Cargar departamentos y usuarios remotos para el admin
    final remoteApts = await SupabaseService.instance.fetchApartmentsWithRetry();
    if (remoteApts.isNotEmpty) {
      _apartments
        ..clear()
        ..addAll(remoteApts);
    }
    await fetchRemoteProfiles();
    await _loadFavoritesFromSupabase();
    await _loadChatsFromSupabase();
    await _loadStaysFromSupabase();
    await autoRestoreLocation();
    notifyListeners();
    return null;
  }

  /// Crea una cuenta nueva en Supabase e inicia sesión.
  Future<String?> register({
    required String name,
    required String email,
    required String phone,
    required UserRole role,
    required String password,
  }) async {
    if (role == UserRole.administrador) return 'Tipo de usuario no válido.';
    final invalid = Validators.name(name) ??
        Validators.email(email) ??
        Validators.phone(phone) ??
        Validators.password(password);
    if (invalid != null) return invalid;

    // 1. Registro en Supabase
    final err = await SupabaseService.instance.signUp(
      name: name,
      email: email,
      phone: phone,
      role: role,
      password: password,
    );

    if (err != null) {
      return err;
    }

    final profile = await SupabaseService.instance.getCurrentProfile();
    if (profile != null) {
      _currentUser = profile;
    } else {
      final user = UserProfile(
        id: SupabaseService.instance.currentUser?.id ??
            'u-${DateTime.now().microsecondsSinceEpoch}',
        role: role,
        name: name.trim(),
        email: email.trim(),
        phone: phone.trim(),
      );
      _users.add(user);
      _currentUser = user;
    }

    _resetSession();
    // Cargar departamentos con reintentos si no se encuentra ninguno al crear la cuenta
    await fetchApartmentsWithRetry();
    await fetchRemoteProfiles();
    await _loadFavoritesFromSupabase();
    await _loadChatsFromSupabase();
    await _loadStaysFromSupabase();
    await autoRestoreLocation();
    notifyListeners();
    return null;
  }

  Future<void> logout() async {
    await SupabaseService.instance.signOut();
    _currentUser = null;
    _favorites.clear();
    _chats.clear();
    _userLocation = null;
    _resetSession();
    notifyListeners();
  }

  /// Recuperar acceso, paso 1: genera un código de 6 dígitos válido 10 min.
  /// Devuelve el código SOLO si la cuenta existe.
  ///
  /// En producción el código se envía por correo y esta función no lo
  /// devuelve; aquí se devuelve para poder mostrarlo en modo demostración.
  /// La pantalla debe responder lo mismo exista o no el correo.
  String? requestRecoveryCode(String email) {
    final key = email.trim().toLowerCase();
    if (_userByEmail(key) == null) return null;
    final code = (100000 + Random.secure().nextInt(900000)).toString();
    _recovery[key] = _RecoveryRequest(
      code,
      DateTime.now().add(_recoveryCodeLifetime),
    );
    return code;
  }

  /// Recuperar acceso, paso 2: valida el código (un solo uso, 5 intentos) y
  /// guarda la nueva contraseña. Devuelve null o el error.
  String? resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) {
    const invalidCode = 'El código no es válido o ya expiró.';
    final key = email.trim().toLowerCase();
    final request = _recovery[key];
    final user = _userByEmail(key);

    if (request == null ||
        user == null ||
        DateTime.now().isAfter(request.expiresAt) ||
        request.attempts >= _maxRecoveryAttempts) {
      _recovery.remove(key);
      return invalidCode;
    }
    if (!PasswordHasher.constantTimeEquals(
        request.code.codeUnits, code.trim().codeUnits)) {
      request.attempts++;
      return invalidCode;
    }
    final weak = Validators.password(newPassword);
    if (weak != null) return weak;

    _credentials[user.id] = PasswordHasher.hash(newPassword);
    _recovery.remove(key);
    _failedLogins.remove(key);
    _lockedUntil.remove(key);
    return null;
  }

  // ------------------------------------------------------------------
  // Ubicación del usuario
  // ------------------------------------------------------------------
  GeoPoint? get userLocation => _userLocation;
  bool get locationEnabled => _userLocation != null;

  /// Pide la ubicación al [LocationService]. Devuelve false si no se obtuvo.
  Future<bool> enableLocation() async {
    final point = await _locationService.currentLocation();
    if (point == null) return false;
    _userLocation = point;
    notifyListeners();
    return true;
  }

  /// Restaura automáticamente la ubicación si el usuario ya otorgó permisos previamente en el dispositivo.
  Future<bool> autoRestoreLocation() async {
    final point = await _locationService.currentLocation(requestPermissionIfNeeded: false);
    if (point == null) return false;
    _userLocation = point;
    return true;
  }

  void disableLocation() {
    _userLocation = null;
    notifyListeners();
  }

  /// Distancia desde el usuario hasta la ubicación APROXIMADA del
  /// departamento (null si no se permitió la ubicación).
  double? distanceKm(Apartment a) => _userLocation?.distanceKmTo(a.approxPoint);

  String? distanceLabel(Apartment a) {
    final d = distanceKm(a);
    return d == null ? null : formatDistance(d);
  }

  // ------------------------------------------------------------------
  // Lectura
  // ------------------------------------------------------------------
  List<UserProfile> get users => List.unmodifiable(_users);
  List<Apartment> get apartments => List.unmodifiable(_apartments);

  UserProfile? userById(String id) {
    if (_currentUser?.id == id) return _currentUser;
    for (final u in _users) {
      if (u.id == id) return u;
    }
    for (final c in _chats) {
      if (c.ownerId == id) {
        return UserProfile(
          id: id,
          role: UserRole.rentero,
          name: c.ownerName,
          email: '',
          phone: '',
          avatarUrl: c.ownerAvatarUrl,
        );
      }
      if (c.renterId == id) {
        return UserProfile(
          id: id,
          role: UserRole.rentador,
          name: c.renterName,
          email: '',
          phone: '',
          avatarUrl: c.renterAvatarUrl,
        );
      }
    }
    return null;
  }

  Apartment? apartmentById(String id) {
    for (final a in _apartments) {
      if (a.id == id) return a;
    }
    return null;
  }

  /// Departamentos del usuario actual, en cualquier estado.
  List<Apartment> get myApartments =>
      _apartments.where((a) => a.ownerId == _currentUser?.id).toList();

  int apartmentCountOf(String userId) =>
      _apartments.where((a) => a.ownerId == userId).length;

  /// Base de la pantalla "Departamentos":
  /// - quien publica: los suyos (todos los estados);
  /// - administrador: todos;
  /// - quien busca: solo los disponibles.
  List<Apartment> get listableApartments {
    if (isAdmin) return List.of(_apartments);
    if (canPublish) return myApartments;
    return _apartments.where((a) => a.isAvailable).toList();
  }

  // ------------------------------------------------------------------
  // Mapa: filtros compartidos (búsqueda, precio, radio)
  // ------------------------------------------------------------------
  ApartmentFilter get mapFilter => _mapFilter;

  void updateMapFilter(ApartmentFilter filter) {
    _mapFilter = filter.copy();
    notifyListeners();
  }

  void setSearchQuery(String value) {
    _mapFilter = _mapFilter.copy()..query = value;
    notifyListeners();
  }

  String get searchQuery => _mapFilter.query;

  /// Filtro de categoría activo en la pantalla de inicio.
  HomeFilter get homeFilter => _homeFilter;

  void setHomeFilter(HomeFilter filter) {
    if (_homeFilter == filter) return;
    _homeFilter = filter;
    notifyListeners();
  }

  /// true si hay algún criterio de búsqueda o filtro activo en la pantalla de inicio.
  bool get isFiltering =>
      _mapFilter.query.trim().isNotEmpty || _homeFilter != HomeFilter.all;

  /// Departamentos disponibles que cumplen el filtro del mapa y del home.
  List<Apartment> get searchResults {
    var list = _apartments
        .where((a) => a.isAvailable)
        .where((a) => _mapFilter.matches(a, distanceKm: distanceKm(a)));
    switch (_homeFilter) {
      case HomeFilter.available:
        // ya filtrado por isAvailable
        break;
      case HomeFilter.affordable:
        final sorted = list.toList()
          ..sort((a, b) => a.price.compareTo(b.price));
        return sorted;
      case HomeFilter.newest:
        final sorted = list.toList()
          ..sort((a, b) => a.rating == 0 ? -1 : (b.rating == 0 ? 1 : 0));
        return sorted;
      case HomeFilter.all:
        break;
    }
    return list.toList();
  }

  /// Puntos (aproximados) que debe abarcar el mapa: todos los disponibles y
  /// la ubicación del usuario. No dependen del filtro para que el mapa no
  /// "salte" al filtrar.
  List<GeoPoint> get mapPoints => [
        for (final a in _apartments)
          if (a.isAvailable) a.approxPoint,
        if (_userLocation != null) _userLocation!,
      ];

  /// Disponibles más cercanos al usuario (vacío si no hay ubicación).
  List<Apartment> nearbyApartments({double radiusKm = 10, int limit = 6}) {
    if (_userLocation == null) return const [];
    final list = _apartments
        .where((a) => a.isAvailable && a.ownerId != _currentUser?.id)
        .where((a) => (distanceKm(a) ?? double.infinity) <= radiusKm)
        .toList()
      ..sort((a, b) => distanceKm(a)!.compareTo(distanceKm(b)!));
    return list.take(limit).toList();
  }

  // ------------------------------------------------------------------
  // Privacidad de la ubicación exacta
  // ------------------------------------------------------------------
  /// La dirección y coordenadas exactas solo las ve:
  /// - quien publicó el departamento;
  /// - quien lo renta actualmente;
  /// - quien lo contactó, una vez que el publicador respondió.
  bool canSeeExactLocation(Apartment a) {
    final me = _currentUser;
    if (me == null) return false;
    if (a.ownerId == me.id) return true;
    final stay = activeStayOf(a.id);
    if (stay != null && stay.renterId == me.id) return true;
    final chat = chatFor(a);
    return chat != null && chat.messages.any((m) => m.senderId == a.ownerId);
  }

  // ------------------------------------------------------------------
  // Favoritos
  // ------------------------------------------------------------------
  Iterable<Favorite> get _myFavorites {
    final id = _currentUser?.id;
    return _favorites.where((f) => f.userId == id);
  }

  /// Favoritos del usuario, el más reciente primero. Se conservan aunque el
  /// departamento esté inactivo (se muestran con su estado).
  List<Apartment> get favorites => recentFavorites();

  List<Apartment> recentFavorites({int? limit}) {
    final sorted = _myFavorites.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final list = <Apartment>[];
    for (final f in sorted) {
      final apt = apartmentById(f.apartmentId);
      if (apt != null) list.add(apt);
    }
    return limit == null ? list : list.take(limit).toList();
  }

  bool isFavorite(String id) => _myFavorites.any((f) => f.apartmentId == id);

  /// Devuelve true si quedó marcado como favorito. Nunca crea duplicados.
  bool toggleFavorite(String apartmentId) {
    final user = _currentUser;
    if (user == null || !canFavorite) return false;
    if (apartmentById(apartmentId) == null) return false;

    final i = _favorites.indexWhere(
      (f) => f.userId == user.id && f.apartmentId == apartmentId,
    );
    final added = i < 0;
    if (added) {
      _favorites.add(Favorite(
        userId: user.id,
        apartmentId: apartmentId,
        createdAt: DateTime.now(),
      ));
    } else {
      _favorites.removeAt(i);
    }
    notifyListeners();
    SupabaseService.instance.toggleFavorite(apartmentId);
    return added;
  }

  Future<void> _loadFavoritesFromSupabase() async {
    final user = _currentUser;
    if (user == null) return;
    try {
      final favIds = await SupabaseService.instance.fetchFavoriteApartmentIds();
      _favorites
        ..removeWhere((f) => f.userId == user.id)
        ..addAll(favIds.map((id) => Favorite(
              userId: user.id,
              apartmentId: id,
              createdAt: DateTime.now(),
            )));
    } catch (_) {}
  }

  void clearFavorites() {
    final user = _currentUser;
    if (user == null) return;
    _favorites.removeWhere((f) => f.userId == user.id);
    notifyListeners();
    SupabaseService.instance.clearFavorites();
  }

  // ------------------------------------------------------------------
  // Departamentos
  // ------------------------------------------------------------------
  String? _requireOwner(Apartment? apt) {
    final user = _currentUser;
    if (apt == null) return 'Departamento no encontrado.';
    if (isAdmin) return null; // El administrador puede modificar cualquier departamento
    if (user == null || !canPublish || apt.ownerId != user.id) {
      return 'Solo quien publicó el departamento o un administrador puede modificarlo.';
    }
    return null;
  }

  /// Publica un departamento nuevo (solo renteros). Devuelve null o el error.
  Future<String?> addApartment({
    required String title,
    required String description,
    required Money price,
    required String location,
    required String address,
    required GeoPoint point,
    ApartmentStatus status = ApartmentStatus.disponible,
    List<Uint8List>? imageBytes,
  }) async {
    final user = _currentUser;
    if (user == null || !canPublish) {
      return 'Solo los renteros pueden publicar departamentos.';
    }
    if (!price.isPositive) return 'El precio debe ser mayor a cero.';
    if (status == ApartmentStatus.inactivo) {
      return 'Un departamento nuevo no puede estar inactivo.';
    }
    final newApt = Apartment(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      ownerId: user.id,
      title: title.trim(),
      description: description.trim(),
      price: price,
      location: location.trim(),
      address: address.trim(),
      point: point,
      status: status,
      hostName: user.name,
      hostAvatarUrl: user.avatarUrl,
      hostSubtitle: 'Propietario',
    );

    // Subir a Supabase junto con sus fotos
    final error = await SupabaseService.instance.insertApartment(
      newApt,
      newImageBytes: imageBytes,
    );

    if (error != null) {
      return error;
    }

    // Recargar desde Supabase para obtener el ID real y las fotos enlazadas
    final remote = await SupabaseService.instance.fetchApartments();
    if (remote.isNotEmpty) {
      _apartments
        ..clear()
        ..addAll(remote);
    } else {
      _apartments.insert(0, newApt);
    }
    notifyListeners();

    return null;
  }

  /// Edita los datos de un departamento. Solo su publicador puede hacerlo.
  /// Con una renta en curso el estado queda en Ocupado; un departamento
  /// inactivo sigue inactivo (se reactiva con [reactivateApartment]).
  String? updateApartment(Apartment updated) {
    final i = _apartments.indexWhere((a) => a.id == updated.id);
    final current = i < 0 ? null : _apartments[i];
    final denied = _requireOwner(current);
    if (denied != null) return denied;
    if (!updated.price.isPositive) return 'El precio debe ser mayor a cero.';

    var status = updated.status;
    if (current!.isInactive) status = ApartmentStatus.inactivo;

    final updatedApt = current.copyWith(
      title: updated.title.trim(),
      description: updated.description.trim(),
      price: updated.price,
      location: updated.location.trim(),
      address: updated.address.trim(),
      point: updated.point,
      status: status,
    );
    _apartments[i] = updatedApt;
    notifyListeners();
    SupabaseService.instance.updateApartment(updatedApt);
    return null;
  }

  /// Marca como Disponible, Ocupado o No disponible (o Inactivo). Solo el
  /// publicador.
  String? setApartmentStatus(String id, ApartmentStatus status) {
    final i = _apartments.indexWhere((a) => a.id == id);
    final current = i < 0 ? null : _apartments[i];
    final denied = _requireOwner(current);
    if (denied != null) return denied;

    if (current!.status == status) return null;
    _apartments[i] = current.copyWith(status: status);
    notifyListeners();
    return null;
  }

  /// Baja lógica: no se borra nada; contactos y favoritos se conservan.
  String? deactivateApartment(String id) =>
      setApartmentStatus(id, ApartmentStatus.inactivo);

  String? reactivateApartment(String id) =>
      setApartmentStatus(id, ApartmentStatus.disponible);

  /// Elimina definitivamente un departamento de Supabase y localmente.
  /// El administrador puede eliminar cualquiera; el rentero solo los suyos.
  Future<String?> deleteApartment(String id) async {
    final a = apartmentById(id);
    if (a == null) return 'Departamento no encontrado.';
    if (!isAdmin && a.ownerId != _currentUser?.id) {
      return 'Solo quien publicó el departamento o un administrador puede eliminarlo.';
    }
    _apartments.removeWhere((item) => item.id == id);
    _favorites.removeWhere((f) => f.apartmentId == id);
    _chats.removeWhere((c) => c.apartmentId == id);
    notifyListeners();
    final err = await SupabaseService.instance.deleteApartment(id);
    return err;
  }

  // ------------------------------------------------------------------
  // Historial de estancias
  // ------------------------------------------------------------------
  /// Estancias del usuario actual (la más reciente primero).
  List<Stay> get myStays {
    final me = _currentUser;
    if (me == null) return const [];
    if (me.role == UserRole.rentero) {
      final list = _stays
          .where((s) => s.ownerId == me.id || s.renterId == me.id)
          .toList()
        ..sort((a, b) => b.startDate.compareTo(a.startDate));
      return list;
    }
    return staysOf(me.id);
  }

  List<Stay> staysOf(String renterId) {
    final list = _stays.where((s) => s.renterId == renterId).toList()
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
    return list;
  }

  /// Estancia en curso del departamento.
  /// Si se especifica [renterId], busca la estancia activa de ese rentador en particular.
  Stay? activeStayOf(String apartmentId, {String? renterId}) {
    for (final s in _stays) {
      if (s.apartmentId == apartmentId && s.isActive) {
        if (renterId == null || s.renterId == renterId) return s;
      }
    }
    return null;
  }

  /// Todas las estancias activas de un departamento.
  List<Stay> activeStaysOf(String apartmentId) {
    return _stays.where((s) => s.apartmentId == apartmentId && s.isActive).toList();
  }

  /// Indica si un rentador específico tiene una estancia activa en el departamento.
  bool hasActiveStay({required String apartmentId, required String renterId}) {
    return _stays.any((s) =>
        s.apartmentId == apartmentId && s.renterId == renterId && s.isActive);
  }

  /// Registra que [renterId] empezó a rentar el departamento.
  /// Solo el dueño del departamento (o administrador) puede aceptar la renta.
  /// Los departamentos pueden tener más de 1 renta simultánea.
  /// No bloquea ni fuerza el estado a "Ocupado". Devuelve false si no procede.
  bool registerStay({
    required Apartment apartment,
    required String renterId,
    String renterName = '',
  }) {
    final user = _currentUser;
    final fresh = apartmentById(apartment.id) ?? apartment;
    if (user == null || fresh.isInactive) return false;

    // Solo el dueño del departamento (o administrador) puede aceptar la renta.
    final isOwner = fresh.ownerId == user.id || user.role == UserRole.administrador;
    if (!isOwner) return false;

    // Solo se valida que este rentador en particular no tenga ya una renta activa en el departamento.
    if (hasActiveStay(apartmentId: fresh.id, renterId: renterId)) return false;

    final renter = userById(renterId);
    final resolvedRenterName = renter?.name.isNotEmpty == true
        ? renter!.name
        : (renterName.isNotEmpty ? renterName : 'Inquilino');

    final startDate = DateTime.now();
    final newStay = Stay(
      id: 'stay-${startDate.microsecondsSinceEpoch}',
      renterId: renterId,
      renterName: resolvedRenterName,
      ownerId: fresh.ownerId,
      apartmentId: fresh.id,
      apartmentTitle: fresh.title,
      location: fresh.location,
      hostName: fresh.hostName,
      monthlyPrice: fresh.price,
      startDate: startDate,
    );
    _stays.add(newStay);
    notifyListeners();

    // Persistir en Supabase y reemplazar el ID local con el UUID real
    SupabaseService.instance.insertStay(newStay).then((uuid) {
      if (uuid != null) {
        final idx = _stays.indexWhere((s) => s.id == newStay.id);
        if (idx >= 0) {
          _stays[idx] = Stay(
            id: uuid,
            renterId: newStay.renterId,
            renterName: newStay.renterName,
            ownerId: newStay.ownerId,
            apartmentId: newStay.apartmentId,
            apartmentTitle: newStay.apartmentTitle,
            location: newStay.location,
            hostName: newStay.hostName,
            monthlyPrice: newStay.monthlyPrice,
            startDate: newStay.startDate,
          );
          notifyListeners();
        }
      }
    });

    NotificationService.instance.notifyStayConfirmed(
      apartmentTitle: fresh.title,
      tenantName: resolvedRenterName,
    );
    return true;
  }

  /// Da por terminada la estancia en curso del departamento para un rentador.
  /// Puede ser cancelada/finalizada tanto por el dueño (rentero) como por el rentador.
  bool endStay(String apartmentId, {String? renterId}) {
    final user = _currentUser;
    final apt = apartmentById(apartmentId);
    final i = _stays.indexWhere((s) =>
        s.apartmentId == apartmentId &&
        (renterId == null || s.renterId == renterId) &&
        s.isActive);
    if (user == null || apt == null || i < 0) {
      return false;
    }
    final stay = _stays[i];
    final isOwner = apt.ownerId == user.id || user.role == UserRole.administrador;
    final isRenter = stay.renterId == user.id;
    if (!isOwner && !isRenter) {
      return false;
    }

    _stays[i] = stay.ended(DateTime.now());
    notifyListeners();
    NotificationService.instance.notifyStayEnded(
      apartmentTitle: apt.title,
    );

    // Persistir en Supabase
    final endedAt = _stays[i].endDate!;
    SupabaseService.instance.endStayInSupabase(stay.id, endedAt);

    return true;
  }

  /// Alias de [endStay] para cancelar la renta.
  bool cancelRent(String apartmentId, {String? renterId}) =>
      endStay(apartmentId, renterId: renterId);

  // ------------------------------------------------------------------
  // Contactos / chat
  // ------------------------------------------------------------------

  Future<void> _loadChatsFromSupabase() async {
    final user = _currentUser;
    if (user == null) return;
    try {
      final remoteChats = await SupabaseService.instance.fetchConversations();
      if (remoteChats.isNotEmpty) {
        for (final rc in remoteChats) {
          final idx = _chats.indexWhere((c) =>
              c.id == rc.id ||
              (c.apartmentId == rc.apartmentId && c.renterId == rc.renterId));
          if (idx >= 0) {
            // Preservar mensajes locales que aún no estén en el servidor
            final existingMessages = _chats[idx].messages;
            final mergedMessages = <ChatMessage>[...rc.messages];
            for (final em in existingMessages) {
              final exists = mergedMessages.any((m) =>
                  m.id == em.id ||
                  (m.text == em.text &&
                      m.senderId == em.senderId &&
                      m.sentAt.difference(em.sentAt).abs().inSeconds < 5));
              if (!exists) {
                mergedMessages.add(em);
              }
            }
            mergedMessages.sort((a, b) => a.sentAt.compareTo(b.sentAt));
            _chats[idx] = rc.copyWith(messages: mergedMessages);
          } else {
            _chats.add(rc);
          }
        }
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _loadStaysFromSupabase() async {
    if (_currentUser == null) return;
    try {
      final remote = await SupabaseService.instance.fetchStays();
      if (remote.isNotEmpty) {
        _stays
          ..clear()
          ..addAll(remote);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> refreshChats() async {
    await _loadChatsFromSupabase();
    notifyListeners();
  }

  /// Conversaciones del usuario actual (la más reciente primero).
  List<ChatConversation> get myChats {
    final id = _currentUser?.id;
    if (id == null) return const [];
    final list = _chats.where((c) => c.hasParticipant(id)).toList()
      ..sort((a, b) => _activityOf(b).compareTo(_activityOf(a)));
    return list;
  }

  /// Contactos que yo envié (yo escribí primero al publicador).
  List<ChatConversation> get sentChats =>
      myChats.where((c) => c.renterId == _currentUser?.id).toList();

  /// Contactos que recibí como publicador.
  List<ChatConversation> get receivedChats =>
      myChats.where((c) => c.ownerId == _currentUser?.id).toList();

  DateTime _activityOf(ChatConversation c) =>
      c.lastMessage?.sentAt ?? DateTime.fromMillisecondsSinceEpoch(0);

  ChatConversation? chatById(String id) {
    for (final c in _chats) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// Conversación del usuario actual sobre este departamento, si existe.
  ChatConversation? chatFor(Apartment a) {
    final id = _currentUser?.id;
    if (id == null) return null;
    for (final c in _chats) {
      if (c.apartmentId == a.id && c.renterId == id) return c;
    }
    return null;
  }

  /// Devuelve la conversación existente o crea una nueva con el rentero.
  /// Solo se puede iniciar un contacto nuevo sobre un departamento Disponible.
  Future<ChatConversation?> openChat(Apartment a) async {
    final user = _currentUser;
    if (user == null || !canChat || a.ownerId == user.id) return null;
    final existing = chatFor(a);
    if (existing != null && SupabaseService.instance.isUuid(existing.id)) {
      return existing;
    }

    final fresh = apartmentById(a.id);
    if (fresh == null || !fresh.isAvailable) return null;

    final remote = await SupabaseService.instance.openOrCreateConversation(apartment: fresh);
    if (remote != null) {
      final idx = _chats.indexWhere((c) =>
          c.id == remote.id ||
          (c.apartmentId == remote.apartmentId && c.renterId == remote.renterId));
      if (idx >= 0) {
        _chats[idx] = remote;
      } else {
        _chats.add(remote);
      }
      notifyListeners();
      return remote;
    }

    if (existing != null) return existing;

    final chat = ChatConversation(
      id: 'chat-${DateTime.now().microsecondsSinceEpoch}',
      apartmentId: fresh.id,
      apartmentTitle: fresh.title,
      ownerId: fresh.ownerId,
      renterId: user.id,
      ownerName: fresh.hostName,
      renterName: user.name,
      ownerAvatarUrl: fresh.hostAvatarUrl,
    );
    _chats.add(chat);
    notifyListeners();
    return chat;
  }

  Future<void> sendMessage(String chatId, String text) async {
    final user = _currentUser;
    final chat = chatById(chatId);
    final body = text.trim();
    if (user == null || chat == null || body.isEmpty) return;
    if (!chat.hasParticipant(user.id)) return;

    final localMsg = ChatMessage(
      id: 'm-${DateTime.now().microsecondsSinceEpoch}',
      conversationId: chatId,
      senderId: user.id,
      text: body,
      sentAt: DateTime.now(),
    );

    chat.messages.add(localMsg);
    notifyListeners();

    String targetChatId = chatId;

    // Si la conversación tiene un ID temporal no UUID, intentar asegurar
    // primero la conversación remota en Supabase
    if (!SupabaseService.instance.isUuid(targetChatId)) {
      final apt = apartmentById(chat.apartmentId);
      if (apt != null) {
        final remoteChat = await SupabaseService.instance.openOrCreateConversation(apartment: apt);
        if (remoteChat != null && SupabaseService.instance.isUuid(remoteChat.id)) {
          final oldId = chat.id;
          targetChatId = remoteChat.id;
          final idx = _chats.indexWhere((c) => c.id == oldId);
          if (idx >= 0) {
            _chats[idx] = chat.copyWith(id: targetChatId);
          }
          notifyListeners();
        }
      }
    }

    if (SupabaseService.instance.isUuid(targetChatId)) {
      final remoteMsg = await SupabaseService.instance.sendMessage(
        conversationId: targetChatId,
        text: body,
      );

      if (remoteMsg != null) {
        final currentChat = chatById(targetChatId) ?? chat;
        final idx = currentChat.messages.indexWhere((m) => m.id == localMsg.id);
        if (idx >= 0) {
          currentChat.messages[idx] = remoteMsg;
        } else if (!currentChat.messages.any((m) => m.id == remoteMsg.id)) {
          currentChat.messages.add(remoteMsg);
        }
        notifyListeners();
      }
    }
  }

  /// Finaliza la conversación: se elimina para ambas personas.
  Future<void> endChat(String chatId) async {
    final user = _currentUser;
    final chat = chatById(chatId);
    if (user == null || chat == null || !chat.hasParticipant(user.id)) return;
    _chats.remove(chat);
    notifyListeners();
    await SupabaseService.instance.deleteConversation(chatId);
  }

  // ------------------------------------------------------------------
  // Usuarios
  // ------------------------------------------------------------------
  /// Actualiza un usuario: el perfil propio o, si eres administrador, el de
  /// cualquiera. Solo un administrador puede cambiar el tipo de usuario de
  /// otra persona. Devuelve null o el error.
  String? updateUser(UserProfile updated) {
    final i = _users.indexWhere((u) => u.id == updated.id);
    final me = _currentUser;
    if (i < 0) return 'Usuario no encontrado.';
    if (me == null || (me.id != updated.id && !isAdmin)) {
      return 'No tienes permiso para editar este usuario.';
    }
    final invalid = Validators.name(updated.name) ??
        (updated.email.trim().isNotEmpty ? Validators.email(updated.email) : null);
    if (invalid != null) return invalid;
    if (updated.email.trim().isNotEmpty) {
      final dup = _userByEmail(updated.email.trim().toLowerCase());
      if (dup != null && dup.id != updated.id) {
        return 'Ya existe una cuenta con ese correo.';
      }
    }

    final canChangeRole = isAdmin && updated.id != me.id;
    // No se permite otorgar el rol de administrador desde la aplicación
    final nextRole = (updated.role == UserRole.administrador &&
            _users[i].role != UserRole.administrador)
        ? _users[i].role
        : (canChangeRole ? updated.role : _users[i].role);

    final next = updated.copyWith(
      role: nextRole,
    );
    _users[i] = next;
    if (_currentUser?.id == next.id) _currentUser = next;
    _syncHostName(next.id, next.name);
    notifyListeners();
    // Si el admin edita a otro usuario, usar adminOverride para guardar por id del perfil editado
    SupabaseService.instance.updateProfile(
      next,
      adminOverride: isAdmin && next.id != me.id,
    );
    return null;
  }

  /// Sube la foto de perfil del usuario a Supabase y actualiza el avatar.
  Future<String?> uploadProfileAvatar(Uint8List bytes) async {
    final url = await SupabaseService.instance.uploadAvatar(bytes);
    if (url != null && _currentUser != null) {
      _currentUser = _currentUser!.copyWith(avatarUrl: url);
      final i = _users.indexWhere((u) => u.id == _currentUser!.id);
      if (i >= 0) {
        _users[i] = _currentUser!;
      }
      _syncHostAvatar(_currentUser!.id, url);
      notifyListeners();
    }
    return url;
  }

  /// Elimina un usuario (solo administrador). Sus departamentos pasan a
  /// Inactivo (baja lógica) y se conservan los favoritos de otras personas.
  /// No se puede eliminar la propia sesión ni a otro administrador.
  Future<bool> deleteUser(String id) async {
    if (!isAdmin || id == _currentUser?.id) return false;
    // Proteger a otros administradores
    final target = _users.firstWhere((u) => u.id == id,
        orElse: () => UserProfile.guest);
    if (target.role == UserRole.administrador) return false;
    _retireUser(id);
    notifyListeners();
    await SupabaseService.instance.deleteProfile(id);
    return true;
  }

  /// Elimina la cuenta con la sesión activa y cierra la sesión.
  void deleteCurrentAccount() {
    final user = _currentUser;
    if (user == null) return;
    _retireUser(user.id);
    _currentUser = null;
    _resetSession();
    notifyListeners();
  }

  void _retireUser(String id) {
    final now = DateTime.now();
    for (var i = 0; i < _apartments.length; i++) {
      final a = _apartments[i];
      if (a.ownerId != id) continue;
      // Si tenía una renta en curso, se da por terminada.
      for (var j = 0; j < _stays.length; j++) {
        if (_stays[j].apartmentId == a.id && _stays[j].isActive) {
          _stays[j] = _stays[j].ended(now);
        }
      }
      _apartments[i] = a.copyWith(status: ApartmentStatus.inactivo);
    }
    _users.removeWhere((u) => u.id == id);
    _credentials.remove(id);
    _favorites.removeWhere((f) => f.userId == id);
    _chats.removeWhere((c) => c.hasParticipant(id));
    _stays.removeWhere((s) => s.renterId == id);
  }

  void _syncHostName(String userId, String name) {
    for (var i = 0; i < _apartments.length; i++) {
      final a = _apartments[i];
      if (a.ownerId == userId && a.hostName != name) {
        _apartments[i] = a.copyWith(hostName: name);
      }
    }
  }

  void _syncHostAvatar(String userId, String avatarUrl) {
    for (var i = 0; i < _apartments.length; i++) {
      final a = _apartments[i];
      if (a.ownerId == userId && a.hostAvatarUrl != avatarUrl) {
        _apartments[i] = a.copyWith(hostAvatarUrl: avatarUrl);
      }
    }
  }
}
