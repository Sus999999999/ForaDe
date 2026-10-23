import 'package:flutter/material.dart';

import 'core/routes/app_routes.dart';
import 'core/state/app_scope.dart';
import 'core/state/app_state.dart';
import 'core/theme/app_theme.dart';

class ForadeApp extends StatefulWidget {
  const ForadeApp({super.key});

  @override
  State<ForadeApp> createState() => _ForadeAppState();
}

class _ForadeAppState extends State<ForadeApp> {
  final AppState _state = AppState();

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: _state,
      child: MaterialApp(
        title: 'Forade',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    );
  }
}
