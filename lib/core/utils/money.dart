/// Importe de dinero con centavos exactos.
///
/// Se guarda como entero de centavos: evita los errores de redondeo de
/// `double` y equivale a un DECIMAL(12,2) de base de datos.
class Money implements Comparable<Money> {
  final int cents;

  const Money.fromCents(this.cents);
  const Money.pesos(int pesos) : cents = pesos * 100;

  static const zero = Money.fromCents(0);

  /// "8900", "8,900.50", "\$8900.5" → Money. Devuelve null si no es válido
  /// (más de 2 decimales, letras, vacío...).
  static Money? tryParse(String input) {
    final s = input
        .trim()
        .replaceAll(r'$', '')
        .replaceAll(',', '')
        .replaceAll(' ', '');
    final m = RegExp(r'^(\d+)(?:\.(\d{1,2}))?$').firstMatch(s);
    if (m == null) return null;
    final whole = int.tryParse(m.group(1)!);
    if (whole == null) return null;
    final frac = int.parse((m.group(2) ?? '').padRight(2, '0'));
    return Money.fromCents(whole * 100 + frac);
  }

  bool get isPositive => cents > 0;

  /// Texto editable: "8900" o "8900.50".
  String get plain {
    final whole = cents ~/ 100;
    final rest = cents % 100;
    return rest == 0 ? '$whole' : '$whole.${rest.toString().padLeft(2, '0')}';
  }

  bool operator >(Money o) => cents > o.cents;
  bool operator <(Money o) => cents < o.cents;
  bool operator >=(Money o) => cents >= o.cents;
  bool operator <=(Money o) => cents <= o.cents;

  @override
  int compareTo(Money other) => cents.compareTo(other.cents);

  @override
  bool operator ==(Object other) => other is Money && other.cents == cents;

  @override
  int get hashCode => cents.hashCode;

  @override
  String toString() => plain;
}
