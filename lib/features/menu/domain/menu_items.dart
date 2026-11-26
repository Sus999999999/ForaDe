import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/domain/models/user_role.dart';
import 'menu_item_data.dart';

/// Opciones del menú lateral según el tipo de usuario.
/// Navegación mínima: Dashboard, Departamentos, Mapa, Favoritos, Mensajes y
/// Perfil (más las opciones propias de cada tipo de usuario).
/// (Cerrar sesión vive en Perfil y en Configuración.)
List<MenuItemData> menuItemsFor(UserRole? role) {
  // El Dashboard no tiene ruta propia: el menú regresa a él.
  const dashboard = MenuItemData('Dashboard', AppColors.menuActive);
  const apartments =
      MenuItemData('Departamentos', AppColors.text, route: AppRoutes.apartments);
  const myApartments = MenuItemData('Mis departamentos', AppColors.text,
      route: AppRoutes.apartments);
  const addApartment = MenuItemData('Publicar departamento', AppColors.orange,
      route: AppRoutes.apartmentForm);
  const map = MenuItemData('Mapa', AppColors.text, route: AppRoutes.map);
  const favorites =
      MenuItemData('Favoritos', AppColors.text, route: AppRoutes.favorites);
  const messages =
      MenuItemData('Mensajes', AppColors.text, route: AppRoutes.chats);
  const stayHistory = MenuItemData('Historial de rentas', AppColors.text,
      route: AppRoutes.stayHistory);
  const admin = MenuItemData('Administración de usuarios', AppColors.orange,
      route: AppRoutes.admin);
  const profile =
      MenuItemData('Perfil', AppColors.text, route: AppRoutes.profile);
  const settings =
      MenuItemData('Configuración', AppColors.text, route: AppRoutes.settings);

  if (role == UserRole.rentero) {
    return const [
      dashboard,
      myApartments,
      addApartment,
      map,
      favorites,
      messages,
      profile,
      settings,
    ];
  }
  if (role == UserRole.rentador) {
    return const [
      dashboard,
      apartments,
      map,
      favorites,
      messages,
      stayHistory,
      profile,
      settings,
    ];
  }
  if (role == UserRole.administrador) {
    return const [dashboard, apartments, map, favorites, admin, profile, settings];
  }
  return const [dashboard];
}
