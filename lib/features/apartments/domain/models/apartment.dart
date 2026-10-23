class Apartment {
  final String id;
  final String ownerId; // id del usuario (rentero) que lo publicó
  final String title;
  final String location;
  final String description;
  final int price;
  final double rating; // 0 = sin calificaciones (nuevo)
  final String? distanceLabel;
  final bool isAvailable;
  final String hostName;
  final String hostSubtitle;
  final String contact; // teléfono o correo que escribió el rentero

  const Apartment({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.location,
    required this.description,
    required this.price,
    required this.hostName,
    this.rating = 0,
    this.distanceLabel,
    this.isAvailable = true,
    this.hostSubtitle = 'Propietario verificado',
    this.contact = '',
  });

  Apartment copyWith({
    String? title,
    String? location,
    String? description,
    int? price,
    bool? isAvailable,
    String? hostName,
  }) =>
      Apartment(
        id: id,
        ownerId: ownerId,
        title: title ?? this.title,
        location: location ?? this.location,
        description: description ?? this.description,
        price: price ?? this.price,
        rating: rating,
        distanceLabel: distanceLabel,
        isAvailable: isAvailable ?? this.isAvailable,
        hostName: hostName ?? this.hostName,
        hostSubtitle: hostSubtitle,
        contact: contact,
      );
}
