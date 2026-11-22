import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/apartments/domain/models/apartment.dart';
import '../../features/apartments/domain/models/apartment_status.dart';
import '../../features/auth/domain/models/user_role.dart';
import '../../features/profile/domain/models/user_profile.dart';
import '../geo/geo_point.dart';
import '../utils/money.dart';

/// Servicio centralizado de conexión con Supabase.
class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  SupabaseClient get _client => Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;
  bool get hasSession => currentUser != null;

  /// Obtiene el perfil del usuario actual desde la tabla 'profiles'.
  Future<UserProfile?> getCurrentProfile() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data == null) {
        return UserProfile(
          id: user.id,
          role: UserRole.rentador,
          name: user.userMetadata?['name'] ?? 'Usuario',
          email: user.email ?? '',
          phone: user.userMetadata?['phone'] ?? '',
        );
      }

      return UserProfile(
        id: data['id'] as String,
        role: UserRole.values.firstWhere(
          (r) => r.name == data['role'],
          orElse: () => UserRole.rentador,
        ),
        name: (data['name'] as String?) ?? 'Usuario',
        email: user.email ?? '',
        phone: (data['phone'] as String?) ?? '',
        city: (data['city'] as String?) ?? '',
      );
    } catch (_) {
      return null;
    }
  }

  /// Inicia sesión con correo y contraseña.
  /// Devuelve null si fue exitoso o el mensaje de error.
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      return null;
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('invalid login credentials')) {
        return 'Correo o contraseña incorrectos.';
      }
      return e.message;
    } catch (e) {
      return 'Error de conexión. Verifica tu internet.';
    }
  }

  /// Registra un nuevo usuario en Supabase Auth y su perfil correspondiente.
  Future<String?> signUp({
    required String name,
    required String email,
    required String phone,
    required UserRole role,
    required String password,
  }) async {
    try {
      final res = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'name': name.trim(),
          'phone': phone.trim(),
          'role': role.name,
        },
      );

      if (res.user == null) {
        return 'No se pudo crear la cuenta.';
      }
      return null;
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('already registered')) {
        return 'Ya existe una cuenta con ese correo.';
      }
      return e.message;
    } catch (e) {
      return 'Error de conexión. Inténtalo más tarde.';
    }
  }

  /// Cierra la sesión activa.
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (_) {}
  }

  /// Envía un correo para restablecer la contraseña.
  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email.trim());
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (_) {
      return 'Error al solicitar el restablecimiento.';
    }
  }

  // ------------------------------------------------------------------
  // Departamentos
  // ------------------------------------------------------------------

  /// Descarga los departamentos desde Supabase.
  Future<List<Apartment>> fetchApartments() async {
    try {
      final data = await _client
          .from('apartments')
          .select('*, profiles:owner_id(name)')
          .order('created_at', ascending: false);

      return (data as List).map((row) {
        final hostName = (row['profiles'] != null && row['profiles']['name'] != null)
            ? row['profiles']['name'] as String
            : 'Propietario';

        return Apartment(
          id: row['id'] as String,
          ownerId: row['owner_id'] as String,
          title: row['title'] as String,
          description: row['description'] as String,
          price: Money.fromCents(row['price_cents'] as int),
          location: row['location'] as String,
          address: row['address'] as String,
          point: GeoPoint(
            (row['latitude'] as num).toDouble(),
            (row['longitude'] as num).toDouble(),
          ),
          status: ApartmentStatus.values.firstWhere(
            (s) => s.name == row['status'],
            orElse: () => ApartmentStatus.disponible,
          ),
          rating: (row['rating'] as num?)?.toDouble() ?? 0.0,
          hostName: hostName,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// Inserta un departamento en Supabase.
  Future<String?> insertApartment(Apartment a) async {
    final user = currentUser;
    if (user == null) return 'Debes iniciar sesión para publicar.';

    try {
      await _client.from('apartments').insert({
        'owner_id': user.id,
        'title': a.title,
        'description': a.description,
        'price_cents': a.price.cents,
        'location': a.location,
        'address': a.address,
        'latitude': a.point.lat,
        'longitude': a.point.lng,
        'status': a.status.name,
      });
      return null;
    } catch (e) {
      return 'Error al guardar el departamento: $e';
    }
  }

  /// Actualiza un departamento en Supabase.
  Future<String?> updateApartment(Apartment a) async {
    try {
      await _client.from('apartments').update({
        'title': a.title,
        'description': a.description,
        'price_cents': a.price.cents,
        'location': a.location,
        'address': a.address,
        'latitude': a.point.lat,
        'longitude': a.point.lng,
        'status': a.status.name,
      }).eq('id', a.id);
      return null;
    } catch (e) {
      return 'Error al actualizar el departamento: $e';
    }
  }

  // ------------------------------------------------------------------
  // Favoritos
  // ------------------------------------------------------------------

  /// Obtiene los IDs de departamentos favoritos del usuario.
  Future<Set<String>> fetchFavoriteApartmentIds() async {
    final user = currentUser;
    if (user == null) return {};

    try {
      final data = await _client
          .from('favorites')
          .select('apartment_id')
          .eq('user_id', user.id);

      return (data as List).map((row) => row['apartment_id'] as String).toSet();
    } catch (_) {
      return {};
    }
  }

  /// Alterna un favorito en Supabase.
  Future<bool> toggleFavorite(String apartmentId) async {
    final user = currentUser;
    if (user == null) return false;

    try {
      final existing = await _client
          .from('favorites')
          .select('id')
          .eq('user_id', user.id)
          .eq('apartment_id', apartmentId)
          .maybeSingle();

      if (existing != null) {
        await _client.from('favorites').delete().eq('id', existing['id']);
        return false;
      } else {
        await _client.from('favorites').insert({
          'user_id': user.id,
          'apartment_id': apartmentId,
        });
        return true;
      }
    } catch (_) {
      return false;
    }
  }
}
