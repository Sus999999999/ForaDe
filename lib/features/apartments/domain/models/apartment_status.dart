/// Estado controlado de un departamento.
enum ApartmentStatus {
  /// Visible en búsquedas y se puede contactar.
  disponible('Disponible'),

  /// Ya está rentado (lo marca el rentero o se asigna al registrar una renta).
  ocupado('Ocupado'),

  /// Temporalmente fuera del mercado (remodelación, etc.).
  noDisponible('No disponible'),

  /// Baja lógica: oculto para todos menos para su dueño; se conservan los
  /// contactos y favoritos asociados.
  inactivo('Inactivo');

  final String label;
  const ApartmentStatus(this.label);
}
