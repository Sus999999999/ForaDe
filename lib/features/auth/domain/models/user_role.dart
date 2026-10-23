enum UserRole {
  rentero('Rentero', 'Publica y administra tus departamentos'),
  rentador('Rentador', 'Busca departamentos y contacta a los renteros'),
  administrador('Administrador', 'Gestiona departamentos y usuarios');

  final String label;
  final String description;
  const UserRole(this.label, this.description);
}
