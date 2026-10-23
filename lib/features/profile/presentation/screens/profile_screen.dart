import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/outlined_action_button.dart';
import '../widgets/contact_info_list.dart';
import '../widgets/profile_stats_card.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  List<ProfileStat> _statsFor(AppState s) {
    if (s.isAdmin) {
      return [
        ProfileStat('${s.users.length}', 'USUARIOS'),
        ProfileStat('${s.apartments.length}', 'DEPARTAMENTOS'),
      ];
    }
    if (s.canPublish) {
      return [
        ProfileStat('${s.myApartments.length}', 'PUBLICADOS'),
        ProfileStat('${s.favorites.length}', 'FAVORITOS'),
      ];
    }
    return [ProfileStat('${s.favorites.length}', 'FAVORITOS')];
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final profile = state.profile;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          children: [
            // Cabecera azul marino con círculo de foto (vacío) y datos.
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  color: AppColors.navy,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 72),
                      child: Column(
                        children: [
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white54,
                                width: 1.6,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            profile.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: AppColors.serif,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            profile.email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFFC7D2E5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 4,
                  child: SafeArea(
                    bottom: false,
                    child: IconButton(
                      tooltip: 'Regresar',
                      icon: const Icon(Icons.chevron_left,
                          size: 28, color: Colors.white),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                ),
              ],
            ),
            // La tarjeta de estadísticas queda montada sobre la cabecera.
            Align(
              alignment: Alignment.bottomCenter,
              heightFactor: 0.58,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ProfileStatsCard(stats: _statsFor(state)),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  ContactInfoList(profile: profile),
                  const SizedBox(height: 20),
                  OutlinedActionButton(
                    label: 'Editar información',
                    onPressed: () =>
                        Navigator.of(context).pushNamed(AppRoutes.editProfile),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
