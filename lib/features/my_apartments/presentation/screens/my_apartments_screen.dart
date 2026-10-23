import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/snackbar.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/title_app_bar.dart';
import '../../../apartments/domain/models/apartment.dart';
import '../../../apartments/presentation/widgets/apartment_list_tile.dart';

class MyApartmentsScreen extends StatelessWidget {
  const MyApartmentsScreen({super.key});

  void _add(BuildContext context) =>
      Navigator.of(context).pushNamed(AppRoutes.addApartment);

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
    final mine = AppScope.of(context).myApartments;

    return Scaffold(
      appBar: TitleAppBar(
        title: 'Mis departamentos',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: PrimaryButton(
                label: '+ Agregar',
                expand: false,
                height: 40,
                onPressed: () => _add(context),
              ),
            ),
          ),
        ],
      ),
      body: mine.isEmpty
          ? EmptyState(
              icon: Icons.apartment_outlined,
              title: 'No has publicado departamentos',
              message: 'Publica el primero y aparecerá aquí.',
              action: PrimaryButton(
                label: 'Agregar departamento',
                expand: false,
                onPressed: () => _add(context),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: mine.length,
              separatorBuilder: (_, __) => const Divider(
                  height: 1,
                  indent: 20,
                  endIndent: 20,
                  color: AppColors.divider),
              itemBuilder: (_, i) {
                final a = mine[i];
                return ApartmentListTile(
                  apartment: a,
                  onTap: () => Navigator.of(context).pushNamed(
                    AppRoutes.apartmentDetail,
                    arguments: a,
                  ),
                  trailing: IconButton(
                    tooltip: 'Eliminar',
                    icon: const Icon(Icons.delete_outline,
                        color: AppColors.muted),
                    onPressed: () => _delete(context, a),
                  ),
                );
              },
            ),
    );
  }
}
