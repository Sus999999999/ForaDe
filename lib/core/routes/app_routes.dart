import 'package:flutter/material.dart';

import '../../features/admin/presentation/screens/admin_screen.dart';
import '../../features/admin/presentation/screens/edit_user_screen.dart';
import '../../features/apartment_detail/presentation/screens/apartment_detail_screen.dart';
import '../../features/apartments/domain/models/apartment.dart';
import '../../features/apartments/presentation/screens/apartment_form_screen.dart';
import '../../features/apartments/presentation/screens/apartments_list_screen.dart';
import '../../features/auth/domain/models/user_role.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/recover_access_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/widgets/role_guard.dart';
import '../../features/chat/presentation/screens/chat_screen.dart';
import '../../features/chat/presentation/screens/chats_screen.dart';
import '../../features/contact/presentation/screens/contact_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/favorites/presentation/screens/favorites_screen.dart';
import '../../features/map/presentation/screens/map_screen.dart';
import '../../features/profile/domain/models/user_profile.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/stays/presentation/screens/stay_history_screen.dart';

class AppRoutes {
  AppRoutes._();

  // Inicio
  static const splash = '/splash';

  // Acceso
  static const login = '/login';
  static const register = '/register';
  static const recoverAccess = '/recover-access';

  // App: el Dashboard es la pantalla de entrada; el resto se abre desde el menú.
  static const home = '/home'; // Dashboard
  static const map = '/map'; // arguments: String? (id del departamento a enfocar)
  static const apartments = '/apartments';
  static const apartmentDetail = '/apartment-detail'; // arguments: Apartment
  static const apartmentForm = '/apartment-form'; // arguments: Apartment? (null = nuevo)
  static const favorites = '/favorites';
  static const chats = '/chats'; // rentero y rentador
  static const chat = '/chat'; // arguments: String (id de la conversación)
  static const contact = '/contact'; // arguments: Apartment
  static const profile = '/profile';
  static const editProfile = '/edit-profile';
  static const settings = '/settings';
  static const stayHistory = '/stay-history'; // solo rentador

  // Administración de cuentas
  static const admin = '/admin';
  static const adminEditUser = '/admin/edit-user'; // arguments: UserProfile

  static const _anyUser = {
    UserRole.rentero,
    UserRole.rentador,
    UserRole.administrador,
  };
  static const _chatUsers = {UserRole.rentero, UserRole.rentador};

  static Route<dynamic> onGenerateRoute(RouteSettings s) {
    Route<dynamic> page(Widget w) =>
        MaterialPageRoute(settings: s, builder: (_) => w);
    Widget guard(Set<UserRole> allowed, Widget child) =>
        RoleGuard(allowed: allowed, child: child);

    switch (s.name) {
      case splash:
        return page(const SplashScreen());
      case register:
        return page(const RegisterScreen());
      case recoverAccess:
        return page(const RecoverAccessScreen());

      case home:
        return page(guard(_anyUser, const DashboardScreen()));
      case map:
        final focusId = s.arguments is String ? s.arguments as String : null;
        return page(guard(_anyUser, MapScreen(focusApartmentId: focusId)));
      case apartments:
        return page(guard(_anyUser, const ApartmentsListScreen()));
      case apartmentDetail:
        return page(guard(
            _anyUser, ApartmentDetailScreen(apartment: s.arguments as Apartment)));
      case apartmentForm:
        final editing = s.arguments is Apartment ? s.arguments as Apartment : null;
        return page(guard(
            const {UserRole.rentero}, ApartmentFormScreen(apartment: editing)));

      case favorites:
        return page(guard(_chatUsers, const FavoritesScreen()));
      case chats:
        return page(guard(_chatUsers, const ChatsScreen()));
      case chat:
        return page(guard(_chatUsers, ChatScreen(chatId: s.arguments as String)));
      case contact:
        return page(guard(
            _chatUsers, ContactScreen(apartment: s.arguments as Apartment)));
      case stayHistory:
        return page(
            guard(const {UserRole.rentador}, const StayHistoryScreen()));

      case profile:
        return page(guard(_anyUser, const ProfileScreen()));
      case editProfile:
        return page(guard(_anyUser, const EditProfileScreen()));
      case settings:
        return page(guard(_anyUser, const SettingsScreen()));

      case admin:
        return page(
            guard(const {UserRole.administrador}, const AdminScreen()));
      case adminEditUser:
        return page(guard(const {UserRole.administrador},
            EditUserScreen(user: s.arguments as UserProfile)));

      case login:
      default:
        return page(const LoginScreen());
    }
  }
}
