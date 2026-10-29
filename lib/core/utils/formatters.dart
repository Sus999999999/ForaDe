/// 8900 -> "$8,900"
String formatPrice(int value) {
  final s = value.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return '\$$buf';
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
