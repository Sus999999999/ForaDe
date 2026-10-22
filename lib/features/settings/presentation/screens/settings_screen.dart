import 'package:flutter/material.dart';

import '../../../../core/state/app_scope.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/snackbar.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmClearFavorites(BuildContext context) async {
    final state = AppScope.read(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Quitar favoritos'),
        content: const Text('¿Quieres quitar todos tus departamentos favoritos?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child:
                const Text('Quitar', style: TextStyle(color: AppColors.orange)),
          ),
        ],
      ),
    );
    if (ok == true) {
      state.clearFavorites();
      if (context.mounted) {
        showAppSnackBar(context, 'Favoritos eliminados');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Configuración',
          style: TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Notificaciones'),
            subtitle: const Text('Avisos de mensajes y novedades'),
            value: state.notificationsEnabled,
            onChanged: state.setNotificationsEnabled,
          ),
          const Divider(height: 1, color: AppColors.divider),
          SwitchListTile(
            title: const Text('Mostrar solo disponibles'),
            subtitle: const Text('Oculta los departamentos no disponibles en la búsqueda'),
            value: state.onlyAvailable,
            onChanged: state.setOnlyAvailable,
          ),
          const Divider(height: 1, color: AppColors.divider),
          ListTile(
            leading:
                const Icon(Icons.favorite_border, color: AppColors.muted),
            title: const Text('Quitar todos los favoritos'),
            onTap: () => _confirmClearFavorites(context),
          ),
        ],
      ),
    );
  }
}
