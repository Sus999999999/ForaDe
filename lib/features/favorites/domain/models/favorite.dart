/// Relación explícita Usuario ↔ Departamento. Solo puede existir una por cada
/// combinación (la garantiza `AppState.toggleFavorite`).
class Favorite {
  final String userId;
  final String apartmentId;
  final DateTime createdAt;

  const Favorite({
    required this.userId,
    required this.apartmentId,
    required this.createdAt,
  });
}
