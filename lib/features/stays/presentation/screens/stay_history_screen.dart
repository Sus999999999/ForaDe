import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/title_app_bar.dart';
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
    final now = DateTime.now();
    final total = stays.fold<StayLength>(
        StayLength.zero, (sum, s) => sum + s.lengthAt(now));

    return Scaffold(
      appBar: const TitleAppBar(title: 'Historial de rentas'),
      body: stays.isEmpty
          ? const EmptyState(
              icon: Icons.history,
              title: 'Aún no has rentado',
              message:
                  'Cuando un rentero registre tu renta, el departamento y el tiempo que te hospedes aparecerán aquí.',
            )
          : ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.navy,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _Summary(
                          value: '${stays.length}',
                          label: stays.length == 1 ? 'RENTA' : 'RENTAS',
                        ),
                      ),
                      Container(width: 1, height: 38, color: Colors.white24),
                      Expanded(
                        flex: 2,
                        child: _Summary(
                          value: total.label,
                          label: 'TIEMPO HOSPEDADO EN TOTAL',
                          small: true,
                        ),
                      ),
                    ],
                  ),
                ),
                for (var i = 0; i < stays.length; i++) ...[
                  if (i > 0)
                    const Divider(
                        height: 1,
                        indent: 20,
                        endIndent: 20,
                        color: AppColors.divider),
                  StayTile(
                    stay: stays[i],
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
                ],
              ],
            ),
    );
  }
}

class _Summary extends StatelessWidget {
  final String value;
  final String label;
  final bool small;
  const _Summary({required this.value, required this.label, this.small = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppColors.serif,
              fontSize: small ? 15 : 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: Color(0xFFC7D2E5),
            ),
          ),
        ],
      ),
    );
  }
}
