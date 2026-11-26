import 'dart:async';
import 'package:flutter/foundation.dart';
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

/// Servicio centralizado de Notificaciones en Tiempo Real y Push (FCM).
/// Administra notificaciones en primer plano (in-app banners) y segundo plano (FCM).
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _controller = StreamController<AppNotification>.broadcast();

  /// Flujo reactivo de notificaciones para consumir en la interfaz.
  Stream<AppNotification> get onNotification => _controller.stream;

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  bool _initialized = false;

  /// Inicializa los canales de notificación y escucha eventos de mensajería.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    debugPrint('🔔 [NotificationService] Inicializado correctamente.');
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
