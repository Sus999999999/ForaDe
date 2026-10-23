import 'package:flutter/material.dart';

import '../../../admin/presentation/screens/admin_screen.dart';
import '../../../auth/domain/models/user_role.dart';
import '../../../favorites/presentation/screens/favorites_screen.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../../map/presentation/screens/map_screen.dart';
import '../../../my_apartments/presentation/screens/my_apartments_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import 'app_bottom_nav.dart';

class ShellTab {
  final NavItem item;
  final Widget page;
  const ShellTab(this.item, this.page);
}

/// Pestañas de la barra inferior según el tipo de usuario.
List<ShellTab> shellTabsFor(UserRole? role) {
  const explore = ShellTab(
    NavItem('Explora', Icons.search_rounded, Icons.search_rounded),
    HomeScreen(),
  );
  const map = ShellTab(
    NavItem('Mapa', Icons.map_outlined, Icons.map),
    MapScreen(),
  );
  const favorites = ShellTab(
    NavItem('Favoritos', Icons.favorite_border, Icons.favorite),
    FavoritesScreen(),
  );
  const mine = ShellTab(
    NavItem('Mis deptos', Icons.apartment_outlined, Icons.apartment),
    MyApartmentsScreen(),
  );
  const admin = ShellTab(
    NavItem('Admin', Icons.admin_panel_settings_outlined,
        Icons.admin_panel_settings),
    AdminScreen(),
  );
  const profile = ShellTab(
    NavItem('Perfil', Icons.person_outline, Icons.person),
    ProfileScreen(),
  );

  if (role == UserRole.rentero) return const [explore, map, favorites, mine, profile];
  if (role == UserRole.administrador) return const [explore, map, admin, profile];
  if (role == UserRole.rentador) return const [explore, map, favorites, profile];
  return const [explore, map, profile];
}
