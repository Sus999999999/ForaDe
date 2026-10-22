class UserProfile {
  final String name;
  final String email;
  final String phone;
  final String city;

  const UserProfile({
    required this.name,
    required this.email,
    required this.phone,
    required this.city,
  });

  UserProfile copyWith({
    String? name,
    String? email,
    String? phone,
    String? city,
  }) =>
      UserProfile(
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        city: city ?? this.city,
      );
}
