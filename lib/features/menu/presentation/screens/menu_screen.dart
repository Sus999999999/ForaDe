import 'package:flutter/material.dart';

import '../../../../core/state/app_scope.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/menu_item_data.dart';
import '../../domain/menu_items.dart';
import '../widgets/menu_tile.dart';
import '../widgets/profile_header.dart';

/// Menú lateral: panel blanco (80 %) + franja azul oscuro a la derecha (20 %)
/// que cierra el menú al tocarla.
class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  void _onItemTap(BuildContext context, MenuItemData item) {
    final navigator = Navigator.of(context);
    navigator.pop();
    // "Inicio" no tiene ruta: solo cierra el menú y deja ver el mapa.
    if (item.route != null) navigator.pushNamed(item.route!);
  }

  @override
  Widget build(BuildContext context) {
    final items = menuItemsFor(AppScope.of(context).role);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Row(
        children: [
          Expanded(
            flex: 80,
            child: Container(
              color: Colors.white,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ProfileHeader(),
                      const SizedBox(height: 28),
                      const Divider(height: 1, color: AppColors.divider),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              for (final item in items)
                                MenuTile(
                                  item: item,
                                  onTap: () => _onItemTap(context, item),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 20,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(color: AppColors.menuStrip),
            ),
          ),
        ],
      ),
    );
  }
}
