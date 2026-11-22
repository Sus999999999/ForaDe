import 'money.dart';

String _group(int value) {
  final s = value.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

/// Money.pesos(8900) -> "$8,900"   ·   8900.50 -> "$8,900.50"
String formatPrice(Money value) {
  final whole = _group(value.cents ~/ 100);
  final rest = value.cents % 100;
  final decimals = rest == 0 ? '' : '.${rest.toString().padLeft(2, '0')}';
  return '\$$whole$decimals';
}

/// 0.45 -> "a 450 m"   ·   1.234 -> "a 1.2 km"   ·   14.6 -> "a 15 km"
String formatDistance(double km) {
  if (km < 1) return 'a ${(km * 1000).round()} m';
  if (km < 10) return 'a ${km.toStringAsFixed(1)} km';
  return 'a ${km.round()} km';
}

const _months = [
  'ene', 'feb', 'mar', 'abr', 'may', 'jun',
  'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
];

/// DateTime(2025, 3, 5) -> "5 mar 2025"
String formatDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

/// DateTime -> "14:05"
String formatTime(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
