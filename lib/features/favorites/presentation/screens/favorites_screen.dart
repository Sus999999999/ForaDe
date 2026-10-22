import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/snackbar.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../apartments/presentation/widgets/apartment_list_tile.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final favorites = state.favorites;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Favoritos',
          style: TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: favorites.isEmpty
          ? const EmptyState(
              icon: Icons.favorite_border,
              title: 'Aún no tienes favoritos',
              message:
                  'Toca el corazón en el detalle de un departamento para guardarlo aquí.',
            )
          : ListView.separated(
              itemCount: favorites.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AppColors.divider),
              itemBuilder: (_, i) {
                final a = favorites[i];
                return ApartmentListTile(
                  apartment: a,
                  onTap: () => Navigator.of(context)
                      .pushNamed(AppRoutes.apartmentDetail, arguments: a),
                  trailing: IconButton(
                    tooltip: 'Quitar de favoritos',
                    icon:
                        const Icon(Icons.favorite, color: AppColors.orange),
                    onPressed: () {
                      state.toggleFavorite(a.id);
                      showAppSnackBar(context, 'Eliminado de favoritos');
                    },
                  ),
                );
              },
            ),
    );
  }
}
