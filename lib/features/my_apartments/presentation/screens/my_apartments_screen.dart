import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/snackbar.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/outlined_action_button.dart';
import '../../../apartments/domain/models/apartment.dart';
import '../../../apartments/presentation/widgets/apartment_list_tile.dart';

class MyApartmentsScreen extends StatelessWidget {
  const MyApartmentsScreen({super.key});

  Future<void> _confirmDelete(BuildContext context, Apartment a) async {
    final state = AppScope.read(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar departamento'),
        content: Text('¿Seguro que quieres eliminar "${a.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Eliminar',
                style: TextStyle(color: AppColors.orange)),
          ),
        ],
      ),
    );
    if (ok == true) {
      state.removeApartment(a.id);
      if (context.mounted) showAppSnackBar(context, 'Departamento eliminado');
    }
  }

  @override
  Widget build(BuildContext context) {
    final mine = AppScope.of(context).myApartments;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Mis departamentos',
          style: TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: mine.isEmpty
          ? EmptyState(
              icon: Icons.apartment_outlined,
              title: 'No has publicado departamentos',
              message: 'Publica el primero y aparecerá aquí.',
              action: SizedBox(
                width: 220,
                child: OutlinedActionButton(
                  label: 'Agregar departamento',
                  onPressed: () => Navigator.of(context)
                      .pushNamed(AppRoutes.addApartment),
                ),
              ),
            )
          : ListView.separated(
              itemCount: mine.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AppColors.divider),
              itemBuilder: (_, i) {
                final a = mine[i];
                return ApartmentListTile(
                  apartment: a,
                  onTap: () => Navigator.of(context)
                      .pushNamed(AppRoutes.apartmentDetail, arguments: a),
                  trailing: IconButton(
                    tooltip: 'Eliminar',
                    icon: const Icon(Icons.delete_outline,
                        color: AppColors.muted),
                    onPressed: () => _confirmDelete(context, a),
                  ),
                );
              },
            ),
    );
  }
}
