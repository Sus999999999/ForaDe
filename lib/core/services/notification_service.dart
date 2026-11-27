import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'supabase_service.dart';

enum NotificationType {
  chatMessage,
  stayConfirmed,
  stayEnded,
  system,
}

class AppNotification {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final Map<String, dynamic>? payload;
  final DateTime timestamp;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.payload,
    required this.timestamp,
  });
}

/// Manejador de notificaciones en segundo plano o cuando la aplicación está cerrada.
/// Debe ser una función de nivel superior con la anotación @pragma('vm:entry-point').
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    debugPrint('📩 [FCM Background] Notificación recibida con app cerrada: ${message.messageId}');
  } catch (e) {
    debugPrint('⚠️ [FCM Background] Error en background handler: $e');
  }
}

/// Servicio centralizado de Notificaciones en Tiempo Real y Push (FCM).
/// Administra notificaciones en primer plano (in-app banners) y segundo plano (FCM con app cerrada).
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _controller = StreamController<AppNotification>.broadcast();

  /// Flujo reactivo de notificaciones para consumir en la interfaz.
  Stream<AppNotification> get onNotification => _controller.stream;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
    'forade_chat_channel',
    'Mensajes de Forade',
    description: 'Notificaciones prioritarias para mensajes de chat y rentas.',
    importance: Importance.max,
    playSound: true,
  );

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  bool _initialized = false;

  /// Inicializa Firebase, canales de notificación y escucha eventos de mensajería.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      // 1. Inicializar Firebase Core
      await Firebase.initializeApp();
      debugPrint('🔥 [NotificationService] Firebase inicializado.');

      // 2. Registrar el manejador de notificaciones en segundo plano
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 3. Configurar canal de notificaciones locales para Android
      const initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
      );
      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (response) {
          debugPrint('👆 [NotificationService] Toque en notificación local: ${response.payload}');
        },
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_androidChannel);

      // 4. Solicitar permisos de notificación (Android 13+ y iOS)
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      debugPrint('🔔 [NotificationService] Estado de permisos: ${settings.authorizationStatus}');

      // 5. Configurar presentación de notificaciones en primer plano
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 6. Obtener token FCM del dispositivo
      try {
        _fcmToken = await messaging.getToken();
        if (_fcmToken != null && _fcmToken!.isNotEmpty) {
          debugPrint('📱 [NotificationService] FCM Token obtenido: $_fcmToken');
          await SupabaseService.instance.saveFcmToken(_fcmToken!);
        }
      } catch (tokenErr) {
        debugPrint('⚠️ [NotificationService] No se pudo obtener token FCM: $tokenErr');
      }

      // 7. Escuchar cambios de token FCM
      messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        debugPrint('🔄 [NotificationService] FCM Token renovado: $newToken');
        SupabaseService.instance.saveFcmToken(newToken);
      });

      // 8. Escuchar mensajes mientras la aplicación está ABIERTA en primer plano
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('📩 [NotificationService] Mensaje recibido en primer plano: ${message.data}');
        final notification = message.notification;
        final title = notification?.title ?? message.data['title'] ?? 'Nuevo mensaje';
        final body = notification?.body ?? message.data['body'] ?? message.data['text'] ?? '';
        final convId = message.data['conversation_id'] ?? message.data['conversationId'] ?? '';

        // Disparar notificación visual local en la barra de Android
        _localNotifications.show(
          message.hashCode,
          title,
          body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _androidChannel.id,
              _androidChannel.name,
              channelDescription: _androidChannel.description,
              icon: '@mipmap/ic_launcher',
              importance: Importance.max,
              priority: Priority.high,
              playSound: true,
            ),
          ),
          payload: convId,
        );

        // Emitir notificación in-app (banner flotante dentro de la app)
        notifyNewChatMessage(
          senderName: title,
          message: body,
          conversationId: convId,
        );
      });

      // 9. Manejar cuando el usuario toca la notificación y abre la app
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('🚀 [NotificationService] App abierta por notificación: ${message.data}');
      });

      debugPrint('🔔 [NotificationService] Inicializado correctamente.');
    } catch (e) {
      debugPrint('⚠️ [NotificationService] Error al inicializar notificaciones: $e');
    }
  }

  /// Sincroniza el token FCM con la cuenta del usuario actual autenticado.
  Future<void> syncTokenWithCurrentUser() async {
    try {
      if (_fcmToken != null && _fcmToken!.isNotEmpty) {
        await SupabaseService.instance.saveFcmToken(_fcmToken!);
      } else {
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null && token.isNotEmpty) {
          _fcmToken = token;
          await SupabaseService.instance.saveFcmToken(token);
        }
      }
    } catch (e) {
      debugPrint('⚠️ [NotificationService] Error al sincronizar FCM Token con usuario: $e');
    }
  }

  /// Registra el token de dispositivo (FCM) y lo sincroniza con la base de datos de Supabase.
  Future<void> registerFcmToken(String token) async {
    _fcmToken = token;
    debugPrint('📱 [NotificationService] FCM Token registrado: $token');
    await SupabaseService.instance.saveFcmToken(token);
  }

  /// Dispara una notificación dentro de la aplicación.
  void showNotification({
    required String title,
    required String body,
    required NotificationType type,
    Map<String, dynamic>? payload,
  }) {
    final notification = AppNotification(
      id: 'notif-${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      body: body,
      type: type,
      payload: payload,
      timestamp: DateTime.now(),
    );

    _controller.add(notification);
    debugPrint('🔔 [NotificationService] ${notification.title}: ${notification.body}');
  }

  /// Notifica un mensaje nuevo de chat recibido en segundo plano o en pantalla distinta.
  void notifyNewChatMessage({
    required String senderName,
    required String message,
    required String conversationId,
  }) {
    showNotification(
      title: 'Mensaje de $senderName',
      body: message,
      type: NotificationType.chatMessage,
      payload: {'conversationId': conversationId},
    );
  }

  /// Notifica la confirmación y registro de una renta / estancia aprobada.
  void notifyStayConfirmed({
    required String apartmentTitle,
    required String tenantName,
  }) {
    showNotification(
      title: '¡Renta confirmada!',
      body: 'Se ha registrado la estancia de $tenantName en "$apartmentTitle".',
      type: NotificationType.stayConfirmed,
      payload: {'apartmentTitle': apartmentTitle},
    );
  }

  /// Notifica el término de una estancia o renta.
  void notifyStayEnded({
    required String apartmentTitle,
  }) {
    showNotification(
      title: 'Renta finalizada',
      body: 'La estancia en "$apartmentTitle" ha concluido exitosamente.',
      type: NotificationType.stayEnded,
      payload: {'apartmentTitle': apartmentTitle},
    );
  }

  void dispose() {
    _controller.close();
  }
}
