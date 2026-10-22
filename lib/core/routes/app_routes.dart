import 'package:flutter/material.dart';

import '../../features/add_apartment/presentation/screens/add_apartment_screen.dart';
import '../../features/apartment_detail/presentation/screens/apartment_detail_screen.dart';
import '../../features/apartments/domain/models/apartment.dart';
import '../../features/contact/presentation/screens/contact_screen.dart';
import '../../features/favorites/presentation/screens/favorites_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/menu/presentation/screens/menu_screen.dart';
import '../../features/my_apartments/presentation/screens/my_apartments_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import 'slide_left_route.dart';

class AppRoutes {
  AppRoutes._();

  static const home = '/';
  static const menu = '/menu';
  static const apartmentDetail = '/apartment-detail'; // arguments: Apartment
  static const contact = '/contact'; // arguments: Apartment
  static const addApartment = '/add-apartment';
  static const favorites = '/favorites';
  static const myApartments = '/my-apartments';
  static const settings = '/settings';
  static const profile = '/profile';
  static const editProfile = '/edit-profile';

  static Route<dynamic> onGenerateRoute(RouteSettings s) {
    Route<dynamic> page(Widget w) =>
        MaterialPageRoute(settings: s, builder: (_) => w);

    switch (s.name) {
      case menu:
        return slideLeftRoute(const MenuScreen(), s);
      case apartmentDetail:
        return page(
            ApartmentDetailScreen(apartment: s.arguments as Apartment));
      case contact:
        return page(ContactScreen(apartment: s.arguments as Apartment));
      case addApartment:
        return page(const AddApartmentScreen());
      case favorites:
        return page(const FavoritesScreen());
      case myApartments:
        return page(const MyApartmentsScreen());
      case settings:
        return page(const SettingsScreen());
      case profile:
        return page(const ProfileScreen());
      case editProfile:
        return page(const EditProfileScreen());
      case home:
      default:
        return page(const HomeScreen());
    }
  }
}
