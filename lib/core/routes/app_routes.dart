import 'package:flutter/material.dart';

import '../../features/add_apartment/presentation/screens/add_apartment_screen.dart';
import '../../features/admin/presentation/screens/edit_apartment_screen.dart';
import '../../features/admin/presentation/screens/edit_user_screen.dart';
import '../../features/apartment_detail/presentation/screens/apartment_detail_screen.dart';
import '../../features/apartments/domain/models/apartment.dart';
import '../../features/auth/domain/models/user_role.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/role_selection_screen.dart';
import '../../features/auth/presentation/widgets/role_guard.dart';
import '../../features/admin/presentation/screens/admin_screen.dart';
import '../../features/contact/presentation/screens/contact_screen.dart';
import '../../features/favorites/presentation/screens/favorites_screen.dart';
import '../../features/map/presentation/screens/map_screen.dart';
import '../../features/my_apartments/presentation/screens/my_apartments_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/domain/models/user_profile.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';

class AppRoutes {
  AppRoutes._();

  // Inicio
  static const splash = '/splash';

  // Acceso
  static const roleSelection = '/';
  static const login = '/login'; // arguments: UserRole

  // App: el mapa es la pantalla principal; el resto se abre desde el menú.
  static const home = '/home';
  static const apartmentDetail = '/apartment-detail'; // arguments: Apartment
  static const contact = '/contact'; // arguments: Apartment
  static const addApartment = '/add-apartment';
  static const settings = '/settings';
  static const editProfile = '/edit-profile';

  static const String favorites = '/favorites';
  static const String myApartments = '/my-apartments';
  static const String admin = '/admin';
  static const String profile = '/profile';

  // Administración
  static const adminEditApartment = '/admin/edit-apartment'; // Apartment
  static const adminEditUser = '/admin/edit-user'; // UserProfile

  static Route<dynamic> onGenerateRoute(RouteSettings s) {
    Route<dynamic> page(Widget w) =>
        MaterialPageRoute(settings: s, builder: (_) => w);

    switch (s.name) {
      case splash:
        return page(const SplashScreen());
      case login:
        return page(LoginScreen(role: s.arguments as UserRole));
      case home:
        return page(const MapScreen());
      case favorites:
        return page(const RoleGuard(
          allowed: {UserRole.rentero, UserRole.rentador},
          child: FavoritesScreen(),
        ));
      case myApartments:
        return page(const RoleGuard(
          allowed: {UserRole.rentero},
          child: MyApartmentsScreen(),
        ));
      case admin:
        return page(const RoleGuard(
          allowed: {UserRole.administrador},
          child: AdminScreen(),
        ));
      case profile:
        return page(const ProfileScreen());
      case apartmentDetail:
        return page(
            ApartmentDetailScreen(apartment: s.arguments as Apartment));
      case contact:
        return page(ContactScreen(apartment: s.arguments as Apartment));
      case addApartment:
        return page(const RoleGuard(
          allowed: {UserRole.rentero},
          child: AddApartmentScreen(),
        ));
      case settings:
        return page(const SettingsScreen());
      case editProfile:
        return page(const EditProfileScreen());
      case adminEditApartment:
        return page(RoleGuard(
          allowed: const {UserRole.administrador},
          child: EditApartmentScreen(apartment: s.arguments as Apartment),
        ));
      case adminEditUser:
        return page(RoleGuard(
          allowed: const {UserRole.administrador},
          child: EditUserScreen(user: s.arguments as UserProfile),
        ));
      case roleSelection:
      default:
        return page(const RoleSelectionScreen());
    }
  }
}
