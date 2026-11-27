import '../../../../core/utils/money.dart';

/// Tiempo transcurrido de una estancia, en meses y días de calendario.
class StayLength {
  final int months;
  final int days;
  const StayLength(this.months, this.days);

  static const zero = StayLength(0, 0);

  static DateTime _utcDate(DateTime d) => DateTime.utc(d.year, d.month, d.day);

  static DateTime _addMonths(DateTime d, int n) {
    final first = DateTime.utc(d.year, d.month + n, 1);
    final lastDay = DateTime.utc(first.year, first.month + 1, 0).day;
    final day = d.day > lastDay ? lastDay : d.day;
    return DateTime.utc(first.year, first.month, day);
  }

  /// Meses completos y días sueltos entre dos fechas (se ignora la hora).
  static StayLength between(DateTime start, DateTime end) {
    final s = _utcDate(start);
    final e = _utcDate(end);
    if (!e.isAfter(s)) return zero;

    var months = (e.year - s.year) * 12 + e.month - s.month;
    if (_addMonths(s, months).isAfter(e)) months--;
    final days = e.difference(_addMonths(s, months)).inDays;
    return StayLength(months, days);
  }

  /// Suma dos duraciones (30 días = 1 mes) para mostrar el total.
  StayLength operator +(StayLength other) {
    var m = months + other.months;
    var d = days + other.days;
    m += d ~/ 30;
    d = d % 30;
    return StayLength(m, d);
  }

  String get label {
    final y = months ~/ 12;
    final m = months % 12;
    final parts = <String>[
      if (y > 0) '$y ${y == 1 ? 'año' : 'años'}',
      if (m > 0) '$m ${m == 1 ? 'mes' : 'meses'}',
      if (days > 0) '$days ${days == 1 ? 'día' : 'días'}',
    ];
    if (parts.isEmpty) return 'Menos de 1 día';
    if (parts.length == 1) return parts.first;
    return '${parts.sublist(0, parts.length - 1).join(', ')} y ${parts.last}';
  }
}

/// Una estancia de un rentador en un departamento.
/// Guarda una copia de los datos del departamento para que el historial se
/// conserve aunque el departamento se elimine o se edite.
class Stay {
  final String id;
  final String renterId;
  final String renterName;
  final String ownerId;
  final String apartmentId;
  final String apartmentTitle;
  final String location;
  final String hostName;
  final Money monthlyPrice;
  final DateTime startDate;
  final DateTime? endDate; // null = estancia en curso

  const Stay({
    required this.id,
    required this.renterId,
    this.renterName = '',
    this.ownerId = '',
    required this.apartmentId,
    required this.apartmentTitle,
    required this.location,
    required this.hostName,
    required this.monthlyPrice,
    required this.startDate,
    this.endDate,
  });

  bool get isActive => endDate == null;

  StayLength lengthAt(DateTime now) =>
      StayLength.between(startDate, endDate ?? now);

  Stay ended(DateTime at) => Stay(
        id: id,
        renterId: renterId,
        renterName: renterName,
        ownerId: ownerId,
        apartmentId: apartmentId,
        apartmentTitle: apartmentTitle,
        location: location,
        hostName: hostName,
        monthlyPrice: monthlyPrice,
        startDate: startDate,
        endDate: at,
      );
}
