import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/title_app_bar.dart';
import '../../../auth/domain/models/user_role.dart';
import '../../domain/models/stay.dart';
import '../widgets/stay_tile.dart';

/// Historial de departamentos que ha rentado el rentador y cuánto tiempo
/// se hospedó en cada uno.
class StayHistoryScreen extends StatelessWidget {
  const StayHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final stays = state.myStays;
    final isRentero = state.profile.role == UserRole.rentero;

    return Scaffold(
      appBar: const TitleAppBar(title: 'Historial de rentas'),
      body: stays.isEmpty
          ? EmptyState(
              icon: Icons.history,
              title: isRentero ? 'Aún no tienes rentas' : 'Aún no has rentado',
              message: isRentero
                  ? 'Cuando aceptes la renta de uno de tus departamentos, aparecerá aquí.'
                  : 'Cuando se acepte una renta, el departamento y el tiempo que te hospedes aparecerán aquí.',
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: stays.length,
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                indent: 20,
                endIndent: 20,
                color: AppColors.divider,
              ),
              itemBuilder: (_, i) => StayTile(
                stay: stays[i],
                isOwnerView: isRentero,
                onTap: () {
                  // Solo se abre si el departamento sigue publicado.
                  final apt = state.apartmentById(stays[i].apartmentId);
                  if (apt == null) return;
                  Navigator.of(context).pushNamed(
                    AppRoutes.apartmentDetail,
                    arguments: apt,
                  );
                },
              ),
            ),
    );
  }
}
