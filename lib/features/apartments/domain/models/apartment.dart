class Apartment {
  final String id;
  final String title;
  final String location;
  final String description;
  final int price;
  final double rating; // 0 = sin calificaciones (nuevo)
  final String? distanceLabel;
  final bool isAvailable;
  final bool isOwn; // true si lo publicó el usuario actual
  final String hostName;
  final String hostSubtitle;

  const Apartment({
    required this.id,
    required this.title,
    required this.location,
    required this.description,
    required this.price,
    required this.hostName,
    this.rating = 0,
    this.distanceLabel,
    this.isAvailable = true,
    this.isOwn = false,
    this.hostSubtitle = 'Propietario verificado',
  });
}
