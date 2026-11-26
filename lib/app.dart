import 'dart:async';

import 'package:flutter/material.dart';

import 'core/routes/app_routes.dart';
import 'core/services/notification_service.dart';
import 'core/state/app_scope.dart';
import 'core/state/app_state.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';

class ForadeApp extends StatefulWidget {
  const ForadeApp({super.key});

  @override
  State<ForadeApp> createState() => _ForadeAppState();
}

class _ForadeAppState extends State<ForadeApp> {
  final AppState _state = AppState();
  final GlobalKey<ScaffoldMessengerState> _messengerKey =
      GlobalKey<ScaffoldMessengerState>();
  StreamSubscription<AppNotification>? _notifSub;

  @override
  void initState() {
    super.initState();
    _notifSub = NotificationService.instance.onNotification.listen((notif) {
      _messengerKey.currentState?.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.navy,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: Row(
            children: [
              Icon(
                switch (notif.type) {
                  NotificationType.chatMessage => Icons.chat_bubble_outline,
                  NotificationType.stayConfirmed => Icons.verified_outlined,
                  NotificationType.stayEnded => Icons.event_available,
                  NotificationType.system => Icons.notifications_none,
                },
                color: AppColors.orange,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notif.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      notif.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    });
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: _state,
      child: MaterialApp(
        scaffoldMessengerKey: _messengerKey,
        title: 'Forade',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    );
  }
}
