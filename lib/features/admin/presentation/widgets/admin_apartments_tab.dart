import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/snackbar.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../apartments/domain/models/apartment.dart';
import '../../../apartments/presentation/widgets/apartment_list_tile.dart';

class AdminApartmentsTab extends StatelessWidget {
  const AdminApartmentsTab({super.key});

  Future<void> _delete(BuildContext context, Apartment a) async {
    final state = AppScope.read(context);
    final ok = await confirmDialog(
      context,
      title: 'Eliminar departamento',
      message: '¿Seguro que quieres eliminar "${a.title}"?',
      confirmLabel: 'Eliminar',
    );
    if (!ok || !context.mounted) return;
    state.removeApartment(a.id);
    showAppSnackBar(context, 'Departamento eliminado');
  }

  @override
  Widget build(BuildContext context) {
    final items = AppScope.of(context).apartments;

    if (items.isEmpty) {
      return const EmptyState(
        icon: Icons.apartment_outlined,
        title: 'No hay departamentos',
        message: 'Cuando los renteros publiquen, aparecerán aquí.',
      );
    }

    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, color: AppColors.divider),
      itemBuilder: (_, i) {
        final a = items[i];
        final extra = a.isAvailable
            ? 'Publicado por ${a.hostName}'
            : 'Publicado por ${a.hostName} • No disponible';
        return ApartmentListTile(
          apartment: a,
          extraLine: extra,
          onTap: () => Navigator.of(context)
              .pushNamed(AppRoutes.apartmentDetail, arguments: a),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Editar',
                icon: const Icon(Icons.edit_outlined, color: AppColors.blue),
                onPressed: () => Navigator.of(context)
                    .pushNamed(AppRoutes.adminEditApartment, arguments: a),
              ),
              IconButton(
                tooltip: 'Eliminar',
                icon:
                    const Icon(Icons.delete_outline, color: AppColors.muted),
                onPressed: () => _delete(context, a),
              ),
            ],
          ),
        );
      },
    );
  }
}
