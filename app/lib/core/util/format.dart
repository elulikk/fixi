import 'package:intl/intl.dart';

import '../config/constants.dart';

final _nf = NumberFormat.decimalPattern('es_AR');

/// Formato de pesos argentinos: "$ 45.000".
String money(num v) => '\$ ${_nf.format(v.round())}';

/// Comisión de Fixi sobre un precio (entero en pesos).
int commissionOf(num price, [num percent = AppConst.commissionPercent]) =>
    (price * percent / 100).round();

/// Lo que recibe el técnico después de la comisión.
int techNetOf(num price, [num percent = AppConst.commissionPercent]) =>
    price.round() - commissionOf(price, percent);

String fmtDistance(double? km) {
  if (km == null) return '—';
  if (km < 1) return '${(km * 1000).round()} m';
  return '${NumberFormat('0.0', 'es_AR').format(km)} km';
}

String fmtMinutes(int? min) {
  if (min == null) return '—';
  if (min < 60) return '$min min';
  final h = min ~/ 60;
  final m = min % 60;
  return m == 0 ? '$h h' : '$h h $m min';
}

String fmtEta(int? min) => min == null ? '—' : 'en ${fmtMinutes(min)}';

String timeAgo(DateTime? d) {
  if (d == null) return '';
  final diff = DateTime.now().difference(d);
  if (diff.inSeconds < 60) return 'ahora';
  if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'hace ${diff.inHours} h';
  if (diff.inDays < 7) return 'hace ${diff.inDays} d';
  return DateFormat('d MMM', 'es_AR').format(d);
}

String fmtDateTime(DateTime? d) {
  if (d == null) return '';
  return DateFormat("EEE d MMM, HH:mm", 'es_AR').format(d);
}

String fmtClock(DateTime? d) => d == null ? '' : DateFormat('HH:mm').format(d);

String fmtScore(num? s) => s == null ? '—' : s.round().toString();
