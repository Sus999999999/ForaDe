import 'package:flutter/material.dart';

import '../routes/app_routes.dart';
import '../state/app_scope.dart';

/// Cierra la sesión y regresa al inicio de sesión (vacía la pila de pantallas).
void logoutToLogin(BuildContext context) {
  final navigator = Navigator.of(context);
  final state = AppScope.read(context);
  // Primero se navega y después se cierra la sesión, para que las pantallas
  // internas no se reconstruyan sin usuario.
  navigator.pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
  state.logout();
}
