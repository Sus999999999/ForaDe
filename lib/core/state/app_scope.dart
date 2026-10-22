import 'package:flutter/widgets.dart';

import 'app_state.dart';

/// Expone [AppState] a todo el árbol de widgets.
///
/// - `AppScope.of(context)`   → dentro de `build` (se reconstruye al cambiar).
/// - `AppScope.read(context)` → en callbacks / initState (no se suscribe).
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({
    super.key,
    required AppState state,
    required super.child,
  }) : super(notifier: state);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'No hay AppScope en el árbol de widgets');
    return scope!.notifier!;
  }

  static AppState read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'No hay AppScope en el árbol de widgets');
    return scope!.notifier!;
  }
}
