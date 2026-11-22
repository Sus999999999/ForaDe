import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../apartments/presentation/widgets/apartment_list_tile.dart';
import '../../../apartments/presentation/widgets/status_chip.dart';

/// Vista de consulta: solo quien publicó un departamento puede editarlo o
/// desactivarlo, así que el administrador no tiene acciones aquí.
class AdminApartmentsTab extends StatelessWidget {
  const AdminApartmentsTab({super.key});

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
        return ApartmentListTile(
          apartment: a,
          badge: StatusChip(status: a.status),
          extraLine: 'Publicado por ${a.hostName}',
          onTap: () => Navigator.of(context)
              .pushNamed(AppRoutes.apartmentDetail, arguments: a),
        );
      },
    );
  }
}
