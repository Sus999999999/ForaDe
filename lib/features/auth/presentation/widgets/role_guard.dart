import 'package:flutter/material.dart';

import '../../../../core/state/app_scope.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/title_app_bar.dart';
import '../../domain/models/user_role.dart';

/// Muestra [child] solo si el usuario actual tiene uno de los roles permitidos.
class RoleGuard extends StatelessWidget {
  final Set<UserRole> allowed;
  final Widget child;
  const RoleGuard({super.key, required this.allowed, required this.child});

  @override
  Widget build(BuildContext context) {
    final role = AppScope.of(context).role;
    if (role != null && allowed.contains(role)) return child;

    return const Scaffold(
      appBar: TitleAppBar(title: 'Acceso restringido'),
      body: EmptyState(
        icon: Icons.lock_outline,
        title: 'Sin permiso',
        message: 'Tu tipo de usuario no puede acceder a esta sección.',
      ),
    );
  }
}
