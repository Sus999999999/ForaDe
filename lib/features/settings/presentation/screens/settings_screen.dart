import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/snackbar.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/menu_row_tile.dart';
import '../../../../shared/widgets/title_app_bar.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _clearFavorites(BuildContext context) async {
    final state = AppScope.read(context);
    final ok = await confirmDialog(
      context,
      title: 'Eliminar favoritos',
      message: '¿Quieres quitar todos tus departamentos favoritos?',
      confirmLabel: 'Eliminar',
    );
    if (!ok || !context.mounted) return;
    state.clearFavorites();
    showAppSnackBar(context, 'Favoritos eliminados');
  }

  void _logout(BuildContext context) {
    final navigator = Navigator.of(context);
    final state = AppScope.read(context);
    navigator.pushNamedAndRemoveUntil(AppRoutes.roleSelection, (_) => false);
    state.logout();
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final state = AppScope.read(context);

    final count = state.myApartments.length;
    final extra = count > 0
        ? ' También se eliminarán tus $count departamento${count == 1 ? '' : 's'}.'
        : '';

    final ok = await confirmDialog(
      context,
      title: 'Eliminar cuenta',
      message:
          'Se eliminará tu cuenta y tus datos.$extra Esta acción no se puede deshacer.',
      confirmLabel: 'Eliminar',
    );
    if (!ok) return;

    navigator.pushNamedAndRemoveUntil(AppRoutes.roleSelection, (_) => false);
    state.deleteCurrentAccount();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Tu cuenta fue eliminada'),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    return Scaffold(
      appBar: const TitleAppBar(title: 'Configuración'),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          if (state.canFavorite)
            MenuRowTile(
              icon: Icons.favorite_border,
              label: 'Eliminar favoritos',
              showChevron: false,
              onTap: () => _clearFavorites(context),
            ),
          MenuRowTile(
            icon: Icons.logout,
            label: 'Cerrar sesión',
            showChevron: false,
            onTap: () => _logout(context),
          ),
          MenuRowTile(
            icon: Icons.delete_forever_outlined,
            label: 'Eliminar cuenta',
            color: AppColors.orange,
            showChevron: false,
            onTap: () => _deleteAccount(context),
          ),
        ],
      ),
    );
  }
}
