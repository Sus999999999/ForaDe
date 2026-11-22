import '../../../../core/geo/geo_point.dart';
import '../../../../core/utils/money.dart';
import 'apartment_status.dart';

class Apartment {
  final String id;
  final String ownerId; // id del usuario (rentero) que lo publicó
  final String title;
  final String description;
  final Money price; // renta mensual

  /// Zona pública (colonia y ciudad). Es lo único que ve cualquier persona.
  final String location;

  /// Dirección exacta. PRIVADA: solo el dueño y quien ya está en contacto con
  /// él (ver `AppState.canSeeExactLocation`).
  final String address;

  /// Coordenadas exactas. PRIVADAS: en la búsqueda se usa [approxPoint].
  final GeoPoint point;

  final ApartmentStatus status;
  final double rating; // 0 = sin calificaciones (nuevo)
  final String hostName;
  final String hostSubtitle;

  const Apartment({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.location,
    required this.address,
    required this.point,
    required this.description,
    required this.price,
    required this.hostName,
    this.status = ApartmentStatus.disponible,
    this.rating = 0,
    this.hostSubtitle = 'Propietario verificado',
  });

  bool get isAvailable => status == ApartmentStatus.disponible;
  bool get isInactive => status == ApartmentStatus.inactivo;

  /// Punto desplazado unos cientos de metros: es el que se dibuja en el mapa
  /// público y se usa para calcular distancias.
  GeoPoint get approxPoint => point.fuzzed(id);

  Apartment copyWith({
    String? title,
    String? location,
    String? address,
    GeoPoint? point,
    String? description,
    Money? price,
    ApartmentStatus? status,
    String? hostName,
  }) =>
      Apartment(
        id: id,
        ownerId: ownerId,
        title: title ?? this.title,
        location: location ?? this.location,
        address: address ?? this.address,
        point: point ?? this.point,
        description: description ?? this.description,
        price: price ?? this.price,
        status: status ?? this.status,
        rating: rating,
        hostName: hostName ?? this.hostName,
        hostSubtitle: hostSubtitle,
      );
}
