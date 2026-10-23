import '../../../auth/domain/models/user_role.dart';

class UserProfile {
  final String id;
  final UserRole role;
  final String name;
  final String email;
  final String phone;
  final String city;

  const UserProfile({
    required this.id,
    required this.role,
    required this.name,
    required this.email,
    this.phone = '',
    this.city = '',
  });

  /// Perfil vacío usado cuando no hay sesión (p. ej. al cerrar sesión).
  static const guest = UserProfile(
    id: '',
    role: UserRole.rentador,
    name: '',
    email: '',
  );

  UserProfile copyWith({
    UserRole? role,
    String? name,
    String? email,
    String? phone,
    String? city,
  }) =>
      UserProfile(
        id: id,
        role: role ?? this.role,
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        city: city ?? this.city,
      );
}
