/// Validaciones de formularios. Devuelven el mensaje de error o null si el
/// valor es válido.
class Validators {
  Validators._();

  static const minPasswordLength = 8;

  static String? name(String value) =>
      value.trim().isEmpty ? 'Escribe tu nombre' : null;

  static String? email(String value) {
    final v = value.trim();
    if (v.isEmpty) return 'Escribe tu correo';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v)) {
      return 'Correo no válido';
    }
    return null;
  }

  static String? phone(String value) {
    final v = value.trim();
    if (v.isEmpty) return 'Escribe tu teléfono';
    if (!RegExp(r'^[0-9+()\-\s]+$').hasMatch(v)) return 'Teléfono no válido';
    final digits = v.replaceAll(RegExp(r'\D'), '').length;
    if (digits < 10 || digits > 15) return 'Debe tener entre 10 y 15 dígitos';
    return null;
  }

  static String? password(String value) {
    if (value.isEmpty) return 'Escribe una contraseña';
    if (value.length < minPasswordLength) {
      return 'Mínimo $minPasswordLength caracteres';
    }
    if (!value.contains(RegExp(r'[A-Za-z]')) ||
        !value.contains(RegExp(r'\d'))) {
      return 'Debe incluir letras y números';
    }
    return null;
  }

  static String? confirmPassword(String value, String original) =>
      value != original ? 'Las contraseñas no coinciden' : null;
}
