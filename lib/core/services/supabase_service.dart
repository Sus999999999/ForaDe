import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/apartments/domain/models/apartment.dart';
import '../../features/apartments/domain/models/apartment_status.dart';
import '../../features/auth/domain/models/user_role.dart';
import '../../features/chat/domain/models/chat_models.dart';
import '../../features/profile/domain/models/user_profile.dart';
import '../../features/stays/domain/models/stay.dart';
import '../geo/geo_point.dart';
import '../utils/money.dart';

/// Servicio centralizado de conexión con Supabase.
class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  SupabaseClient get _client => Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;
  bool get hasSession => _client.auth.currentSession != null;

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

      if (data != null) {
        final emailFromDb = (data['email'] as String?) ?? '';
        final effectiveEmail =
            emailFromDb.isNotEmpty ? emailFromDb : (user.email ?? '');

        // Sincronizar el correo en la tabla profiles si falta en la base de datos
        if (emailFromDb.isEmpty && user.email != null && user.email!.isNotEmpty) {
          try {
            await _client.from('profiles').update({
              'email': user.email,
            }).eq('id', user.id);
          } catch (_) {}
        }

        return UserProfile(
          id: data['id'] as String,
          role: UserRole.values.firstWhere(
            (r) => r.name == data['role'],
            orElse: () => UserRole.rentador,
          ),
          name: (data['name'] as String?) ?? 'Usuario',
          email: effectiveEmail,
          phone: (data['phone'] as String?) ?? '',
          city: (data['city'] as String?) ?? '',
          avatarUrl: (data['avatar_url'] as String?) ?? '',
        );
      }
    } catch (_) {}

    // Fallback con los metadatos de Auth si la tabla no responde o no existe fila
    return UserProfile(
      id: user.id,
      role: UserRole.values.firstWhere(
        (r) => r.name == user.userMetadata?['role'],
        orElse: () => UserRole.rentador,
      ),
      name: (user.userMetadata?['name'] as String?) ?? 'Usuario',
      email: user.email ?? '',
      phone: (user.userMetadata?['phone'] as String?) ?? '',
      avatarUrl: (user.userMetadata?['avatar_url'] as String?) ?? '',
    );
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

      // Guardar el correo también en la tabla profiles para que el admin pueda verlo
      try {
        await _client.from('profiles').update({
          'email': email.trim(),
        }).eq('id', res.user!.id);
      } catch (_) {}

      // Si Supabase no otorgó sesión directa (por tener Confirm Email activado)
      if (res.session == null) {
        try {
          final loginRes = await _client.auth.signInWithPassword(
            email: email.trim(),
            password: password,
          );
          if (loginRes.session == null) {
            return 'Cuenta creada. Por favor confirma el correo electrónico enviado a tu bandeja para poder entrar.';
          }
        } on AuthException catch (e) {
          if (e.message.toLowerCase().contains('email not confirmed')) {
            return 'Cuenta creada. Supabase requiere confirmar tu correo antes de entrar. (O desactiva "Confirm email" en Supabase).';
          }
        } catch (_) {}
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

  /// Sube la foto de perfil del usuario a Supabase Storage y actualiza la tabla profiles.
  Future<String?> uploadAvatar(Uint8List bytes) async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final fileName = 'avatar_${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'avatars/$fileName';

      await _client.storage.from('apartments').uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
      );

      final publicUrl = _client.storage.from('apartments').getPublicUrl(path);

      await _client.from('profiles').update({
        'avatar_url': publicUrl,
      }).eq('id', user.id);

      return publicUrl;
    } catch (e) {
      return null;
    }
  }

  /// Actualiza los datos del perfil en Supabase.
  /// Cuando se llama desde el panel de administración el [adminOverride] es true
  /// y se usa el id del perfil editado en lugar del usuario autenticado.
  Future<String?> updateProfile(UserProfile profile,
      {bool adminOverride = false}) async {
    final user = currentUser;
    if (user == null) return 'No hay sesión activa.';

    final targetId = adminOverride ? profile.id : user.id;

    try {
      await _client.from('profiles').update({
        'name': profile.name,
        'phone': profile.phone,
        'city': profile.city,
        'avatar_url': profile.avatarUrl,
        'role': profile.role.name,
        if (profile.email.isNotEmpty) 'email': profile.email,
      }).eq('id', targetId);
      return null;
    } catch (e) {
      return 'Error al actualizar perfil: $e';
    }
  }

  /// Obtiene los perfiles de todos los usuarios registrados (para administración).
  Future<List<UserProfile>> fetchProfiles() async {
    try {
      dynamic data;
      try {
        data = await _client
            .from('profiles')
            .select()
            .order('created_at', ascending: false);
      } catch (_) {
        data = await _client.from('profiles').select();
      }

      return (data as List).map((row) {
        return UserProfile(
          id: row['id'] as String,
          role: UserRole.values.firstWhere(
            (r) => r.name == row['role'],
            orElse: () => UserRole.rentador,
          ),
          name: (row['name'] as String?) ?? 'Usuario',
          email: (row['email'] as String?) ?? '',
          phone: (row['phone'] as String?) ?? '',
          city: (row['city'] as String?) ?? '',
          avatarUrl: (row['avatar_url'] as String?) ?? '',
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// Elimina un perfil de usuario de la tabla profiles.
  Future<bool> deleteProfile(String profileId) async {
    try {
      if (_isUuid(profileId)) {
        await _client.from('profiles').delete().eq('id', profileId);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // ------------------------------------------------------------------
  // Departamentos
  // ------------------------------------------------------------------

  /// Descarga los departamentos desde Supabase incluyendo sus fotos.
  Future<List<Apartment>> fetchApartments() async {
    try {
      final data = await _client
          .from('apartments')
          .select('*, profiles:owner_id(name, avatar_url), apartment_images(image_url, order_index)')
          .order('created_at', ascending: false);

      return (data as List).map((row) {
        final hostName = (row['profiles'] != null && row['profiles']['name'] != null)
            ? row['profiles']['name'] as String
            : 'Propietario';
        final hostAvatarUrl = (row['profiles'] != null && row['profiles']['avatar_url'] != null)
            ? (row['profiles']['avatar_url'] as String?) ?? ''
            : '';

        final imagesRaw = (row['apartment_images'] as List?) ?? [];
        imagesRaw.sort((a, b) => ((a['order_index'] ?? 0) as int)
            .compareTo((b['order_index'] ?? 0) as int));
        final images = imagesRaw.map((img) => img['image_url'] as String).toList();

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
          hostAvatarUrl: hostAvatarUrl,
          images: images,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// Descarga los departamentos desde Supabase. Si la lista devuelta está vacía,
  /// reintenta hasta [maxRetries] veces (por defecto 5).
  Future<List<Apartment>> fetchApartmentsWithRetry({
    int maxRetries = 5,
    Duration delay = const Duration(milliseconds: 600),
  }) async {
    var list = await fetchApartments();
    if (list.isNotEmpty) return list;

    for (var retry = 1; retry <= maxRetries; retry++) {
      await Future<void>.delayed(delay);
      list = await fetchApartments();
      if (list.isNotEmpty) return list;
    }
    return [];
  }

  /// Inserta un departamento en Supabase y sube sus fotos si las hay.
  Future<String?> insertApartment(Apartment a, {List<Uint8List>? newImageBytes}) async {
    final user = currentUser;
    if (user == null) return 'Debes iniciar sesión para publicar.';

    try {
      final res = await _client.from('apartments').insert({
        'owner_id': user.id,
        'title': a.title,
        'description': a.description,
        'price_cents': a.price.cents,
        'location': a.location,
        'address': a.address,
        'latitude': a.point.lat,
        'longitude': a.point.lng,
        'status': a.status.name,
      }).select('id').single();

      final apartmentId = res['id'] as String;

      if (newImageBytes != null && newImageBytes.isNotEmpty) {
        for (var i = 0; i < newImageBytes.length; i++) {
          final fileName = '$apartmentId-${DateTime.now().millisecondsSinceEpoch}-$i.jpg';
          final path = '$apartmentId/$fileName';
          await _client.storage.from('apartments').uploadBinary(
            path,
            newImageBytes[i],
            fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
          );
          final publicUrl = _client.storage.from('apartments').getPublicUrl(path);
          await _client.from('apartment_images').insert({
            'apartment_id': apartmentId,
            'image_url': publicUrl,
            'order_index': i,
          });
        }
      }
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

  /// Elimina un departamento en Supabase junto con sus imágenes y favoritos.
  Future<String?> deleteApartment(String apartmentId) async {
    try {
      if (_isUuid(apartmentId)) {
        await _client.from('apartment_images').delete().eq('apartment_id', apartmentId);
        await _client.from('favorites').delete().eq('apartment_id', apartmentId);
        await _client.from('apartments').delete().eq('id', apartmentId);
      }
      return null;
    } catch (e) {
      return 'Error al eliminar el departamento: $e';
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

  static final _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  bool isUuid(String value) => _uuidPattern.hasMatch(value);
  bool _isUuid(String value) => isUuid(value);

  /// Alterna un favorito en Supabase.
  Future<bool> toggleFavorite(String apartmentId) async {
    final user = currentUser;
    if (user == null || !_isUuid(apartmentId)) return false;

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

  /// Elimina todos los favoritos del usuario en Supabase.
  Future<void> clearFavorites() async {
    final user = currentUser;
    if (user == null) return;

    try {
      await _client.from('favorites').delete().eq('user_id', user.id);
    } catch (_) {}
  }

  // ------------------------------------------------------------------
  // Mensajería en Tiempo Real (WebSockets) y Conversaciones
  // ------------------------------------------------------------------

  /// Descarga todas las conversaciones donde participa el usuario actual.
  Future<List<ChatConversation>> fetchConversations() async {
    final user = currentUser;
    if (user == null) return [];

    try {
      dynamic data;
      try {
        data = await _client
            .from('chat_conversations')
            .select('*, owner:profiles!owner_id(name, avatar_url), renter:profiles!renter_id(name, avatar_url)')
            .or('owner_id.eq.${user.id},renter_id.eq.${user.id}')
            .order('updated_at', ascending: false);
      } catch (e) {
        debugPrint('⚠️ Error select embed en fetchConversations, intentando plano: $e');
        data = await _client
            .from('chat_conversations')
            .select()
            .or('owner_id.eq.${user.id},renter_id.eq.${user.id}')
            .order('updated_at', ascending: false);
      }

      if (data == null || data is! List) return [];

      final conversations = <ChatConversation>[];
      for (final row in data) {
        try {
          final rowMap = row is Map<String, dynamic>
              ? row
              : Map<String, dynamic>.from(row as Map);
          final convId = rowMap['id']?.toString() ?? '';

          List<ChatMessage> messages = [];
          if (convId.isNotEmpty && isUuid(convId)) {
            try {
              final msgsData = await _client
                  .from('chat_messages')
                  .select()
                  .eq('conversation_id', convId)
                  .order('created_at', ascending: true);

              if (msgsData is List) {
                messages = msgsData.map((m) => ChatMessage.fromMap(m)).toList();
              }
            } catch (e) {
              debugPrint('⚠️ Error cargando mensajes para conv $convId: $e');
            }
          }

          conversations.add(ChatConversation.fromMap(
            rowMap,
            messages: messages,
          ));
        } catch (e) {
          debugPrint('⚠️ Error al parsear conversación: $e');
        }
      }
      return conversations;
    } catch (e) {
      debugPrint('❌ Error general en fetchConversations: $e');
      return [];
    }
  }

  /// Suscripción en tiempo real vía WebSockets a los mensajes de una conversación.
  Stream<List<ChatMessage>> streamMessages(String conversationId) {
    if (!isUuid(conversationId)) {
      return const Stream.empty();
    }
    return _client
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true)
        .map((rows) => rows.map((r) => ChatMessage.fromMap(r)).toList());
  }

  /// Envía un mensaje a la conversación y actualiza el timestamp de actividad.
  Future<ChatMessage?> sendMessage({
    required String conversationId,
    required String text,
  }) async {
    final user = currentUser;
    final body = text.trim();
    if (user == null || body.isEmpty || !isUuid(conversationId)) return null;

    try {
      final res = await _client.from('chat_messages').insert({
        'conversation_id': conversationId,
        'sender_id': user.id,
        'text': body,
      }).select().single();

      // Actualizar updated_at en la conversación de forma segura
      try {
        await _client.from('chat_conversations').update({
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('id', conversationId);
      } catch (e) {
        debugPrint('⚠️ No se pudo actualizar updated_at de la conversación: $e');
      }

      // Intentar disparar push en segundo plano para el destinatario
      _triggerPushNotification(
        conversationId: conversationId,
        senderId: user.id,
        text: body,
      );

      return ChatMessage.fromMap(res);
    } catch (e) {
      debugPrint('❌ Error al enviar mensaje en Supabase: $e');
      return null;
    }
  }

  /// Dispara la función de notificaciones push de Supabase hacia Firebase
  Future<void> _triggerPushNotification({
    required String conversationId,
    required String senderId,
    required String text,
  }) async {
    try {
      await _client.functions.invoke('chat-push-notification', body: {
        'record': {
          'conversation_id': conversationId,
          'sender_id': senderId,
          'text': text,
        },
      });
    } catch (e) {
      debugPrint('ℹ️ [PushNotification] Invocación de Edge Function: $e');
    }
  }

  RealtimeChannel? _globalMessagesChannel;

  /// Suscripción global a nuevos mensajes recibidos para disparar notificaciones in-app.
  void subscribeGlobalIncomingMessages(
    void Function(String senderId, String text, String convId) onMessage,
  ) {
    _globalMessagesChannel?.unsubscribe();
    _globalMessagesChannel = _client
        .channel('global:chat_messages')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          callback: (payload) {
            final record = payload.newRecord;
            final senderId = record['sender_id']?.toString() ?? '';
            final text = record['text']?.toString() ?? '';
            final convId = record['conversation_id']?.toString() ?? '';
            final myId = currentUser?.id;
            if (senderId.isNotEmpty && senderId != myId) {
              onMessage(senderId, text, convId);
            }
          },
        )
        .subscribe();
  }

  /// Abre una conversación existente o crea una nueva con el rentero.
  Future<ChatConversation?> openOrCreateConversation({
    required Apartment apartment,
  }) async {
    final user = currentUser;
    if (user == null || user.id == apartment.ownerId) return null;
    if (!isUuid(apartment.id) || !isUuid(apartment.ownerId)) return null;

    try {
      dynamic existing;
      try {
        existing = await _client
            .from('chat_conversations')
            .select('*, owner:profiles!owner_id(name, avatar_url), renter:profiles!renter_id(name, avatar_url)')
            .eq('apartment_id', apartment.id)
            .eq('renter_id', user.id)
            .maybeSingle();
      } catch (e) {
        debugPrint('⚠️ Fallo select embed en openOrCreateConversation, reintentando plano: $e');
        existing = await _client
            .from('chat_conversations')
            .select()
            .eq('apartment_id', apartment.id)
            .eq('renter_id', user.id)
            .maybeSingle();
      }

      if (existing != null) {
        final convId = existing['id']?.toString() ?? '';
        List<ChatMessage> messages = [];
        if (convId.isNotEmpty && isUuid(convId)) {
          try {
            final msgsData = await _client
                .from('chat_messages')
                .select()
                .eq('conversation_id', convId)
                .order('created_at', ascending: true);

            if (msgsData is List) {
              messages = msgsData.map((m) => ChatMessage.fromMap(m)).toList();
            }
          } catch (e) {
            debugPrint('⚠️ Error cargando mensajes existentes: $e');
          }
        }

        final existingMap = existing is Map<String, dynamic>
            ? existing
            : Map<String, dynamic>.from(existing as Map);

        return ChatConversation.fromMap(existingMap, messages: messages);
      }

      dynamic inserted;
      try {
        inserted = await _client.from('chat_conversations').insert({
          'apartment_id': apartment.id,
          'apartment_title': apartment.title,
          'owner_id': apartment.ownerId,
          'renter_id': user.id,
        }).select('*, owner:profiles!owner_id(name, avatar_url), renter:profiles!renter_id(name, avatar_url)').single();
      } catch (e) {
        debugPrint('⚠️ Fallo insert con select embed, reintentando plano: $e');
        inserted = await _client.from('chat_conversations').insert({
          'apartment_id': apartment.id,
          'apartment_title': apartment.title,
          'owner_id': apartment.ownerId,
          'renter_id': user.id,
        }).select().single();
      }

      final insertedMap = inserted is Map<String, dynamic>
          ? inserted
          : Map<String, dynamic>.from(inserted as Map);

      return ChatConversation.fromMap(insertedMap, messages: []);
    } catch (e) {
      debugPrint('❌ Error en openOrCreateConversation: $e');
      return null;
    }
  }

  /// Finaliza y elimina la conversación en Supabase (en cascada elimina los mensajes).
  Future<bool> deleteConversation(String conversationId) async {
    try {
      if (isUuid(conversationId)) {
        await _client
            .from('chat_conversations')
            .delete()
            .eq('id', conversationId);
      }
      return true;
    } catch (e) {
      debugPrint('❌ Error al eliminar conversación: $e');
      return false;
    }
  }

  // ------------------------------------------------------------------
  // Rentas (stays)
  // ------------------------------------------------------------------

  /// Descarga las rentas del usuario actual (como dueño o como rentador).
  Future<List<Stay>> fetchStays() async {
    final user = currentUser;
    if (user == null) return [];
    try {
      final data = await _client
          .from('stays')
          .select()
          .or('renter_id.eq.${user.id},owner_id.eq.${user.id}')
          .order('start_date', ascending: false);

      return (data as List).map((row) {
        return Stay(
          id: row['id'] as String,
          renterId: row['renter_id'] as String,
          renterName: (row['renter_name'] as String?) ?? '',
          ownerId: row['owner_id'] as String,
          apartmentId: row['apartment_id'] as String,
          apartmentTitle: row['apartment_title'] as String,
          location: (row['location'] as String?) ?? '',
          hostName: (row['host_name'] as String?) ?? '',
          monthlyPrice: Money.fromCents(row['monthly_price_cents'] as int),
          startDate: DateTime.parse(row['start_date'] as String),
          endDate: row['end_date'] != null
              ? DateTime.parse(row['end_date'] as String)
              : null,
        );
      }).toList();
    } catch (e) {
      debugPrint('❌ Error al cargar rentas: $e');
      return [];
    }
  }

  /// Inserta una nueva renta en Supabase y devuelve el UUID generado (o null si falla).
  Future<String?> insertStay(Stay stay) async {
    try {
      final res = await _client.from('stays').insert({
        'renter_id': stay.renterId,
        'owner_id': stay.ownerId,
        'apartment_id': stay.apartmentId,
        'apartment_title': stay.apartmentTitle,
        'location': stay.location,
        'host_name': stay.hostName,
        'monthly_price_cents': stay.monthlyPrice.cents,
        'renter_name': stay.renterName,
        'start_date': stay.startDate.toUtc().toIso8601String(),
      }).select('id').single();
      return res['id'] as String?;
    } catch (e) {
      debugPrint('❌ Error al insertar renta: $e');
      return null;
    }
  }

  /// Actualiza el campo end_date de la renta con [stayId] en Supabase.
  Future<void> endStayInSupabase(String stayId, DateTime endDate) async {
    if (!isUuid(stayId)) return;
    try {
      await _client
          .from('stays')
          .update({'end_date': endDate.toUtc().toIso8601String()})
          .eq('id', stayId);
    } catch (e) {
      debugPrint('❌ Error al finalizar renta en Supabase: $e');
    }
  }

  /// Guarda o actualiza el token de notificaciones FCM en el perfil.
  Future<void> saveFcmToken(String token) async {
    final user = currentUser;
    if (user == null || token.trim().isEmpty) return;

    try {
      await _client.from('profiles').update({
        'fcm_token': token.trim(),
      }).eq('id', user.id);
    } catch (_) {}
  }
}
