import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/menu_item_data.dart';
import '../widgets/menu_tile.dart';
import '../widgets/profile_header.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  /// Cierra el menú y, si hay ruta, navega a ella.
  void _go(BuildContext context, String? route) {
    final navigator = Navigator.of(context);
    navigator.pop();
    if (route != null) navigator.pushNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    const items = <MenuItemData>[
      MenuItemData('Inicio', AppColors.blue),
      MenuItemData('Favoritos', AppColors.text, route: AppRoutes.favorites),
      MenuItemData('Mis departamentos', AppColors.text,
          route: AppRoutes.myApartments),
      MenuItemData('Agregar departamento', AppColors.orange,
          route: AppRoutes.addApartment),
      MenuItemData('Configuración', AppColors.text,
          route: AppRoutes.settings),
      MenuItemData('Mi perfil', AppColors.text, route: AppRoutes.profile),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Row(
        children: [
          Expanded(
            flex: 76,
            child: Container(
              color: AppColors.menuBg,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 0, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ProfileHeader(),
                      const SizedBox(height: 18),
                      const Divider(height: 1, color: AppColors.divider),
                      const SizedBox(height: 8),
                      ...items.map(
                        (e) => MenuTile(
                          item: e,
                          onTap: () => _go(context, e.route),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 24,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(color: AppColors.navy),
            ),
          ),
        ],
      ),
    );
  }
}
