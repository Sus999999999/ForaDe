import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/title_app_bar.dart';
import '../../../apartments/presentation/widgets/apartment_card.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favorites = AppScope.of(context).favorites;

    return Scaffold(
      appBar: const TitleAppBar(title: 'Favoritos'),
      body: favorites.isEmpty
          ? const EmptyState(
              icon: Icons.favorite_border,
              title: 'Aún no tienes favoritos',
              message: 'Toca el corazón de un departamento para guardarlo aquí.',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              itemCount: favorites.length,
              separatorBuilder: (_, __) => const SizedBox(height: 26),
              itemBuilder: (_, i) {
                final a = favorites[i];
                return ApartmentCard(
                  apartment: a,
                  aspectRatio: 16 / 10,
                  onTap: () => Navigator.of(context).pushNamed(
                    AppRoutes.apartmentDetail,
                    arguments: a,
                  ),
                );
              },
            ),
    );
  }
}
