import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/domain/models/user_role.dart';
import 'menu_item_data.dart';

/// Opciones del menú lateral según el tipo de usuario.
/// (Cerrar sesión vive en Configuración.)
List<MenuItemData> menuItemsFor(UserRole? role) {
  const home = MenuItemData('Inicio', AppColors.menuActive);
  const favorites =
      MenuItemData('Favoritos', AppColors.text, route: AppRoutes.favorites);
  const myApartments = MenuItemData('Mis departamentos', AppColors.text,
      route: AppRoutes.myApartments);
  const addApartment = MenuItemData('Agregar departamento', AppColors.orange,
      route: AppRoutes.addApartment);
  const admin =
      MenuItemData('Administración', AppColors.orange, route: AppRoutes.admin);
  const settings =
      MenuItemData('Configuración', AppColors.text, route: AppRoutes.settings);
  const profile =
      MenuItemData('Mi perfil', AppColors.text, route: AppRoutes.profile);

  if (role == UserRole.rentero) {
    return const [
      home,
      favorites,
      myApartments,
      addApartment,
      settings,
      profile,
    ];
  }
  if (role == UserRole.rentador) {
    return const [home, favorites, settings, profile];
  }
  if (role == UserRole.administrador) {
    return const [home, admin, settings, profile];
  }
  return const [home];
}
