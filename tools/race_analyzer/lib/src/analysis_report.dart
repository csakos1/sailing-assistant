import 'package:race_analyzer/src/rounding_analysis.dart';

/// A korozesi eredmenyekbol ember-olvashato szoveges reportot epit (stdout).
String formatReport(List<RoundingResult> results) {
  if (results.isEmpty) {
    return 'Nincs boja-korozes a logban — nincs mit elemezni.\n';
  }
  final buffer = StringBuffer()
    ..writeln('Post-race next-mark TWA elemzes — ${results.length} korozes')
    ..writeln();
  for (final result in results) {
    buffer
      ..writeln(
        '  ${result.fromMark} -> ${result.toMark}'
        '  @ ${_hms(result.roundedAt)}',
      )
      ..writeln(
        '    predikalt TWA : ${_deg(result.predictedTwaDeg)}'
        '  (konf: ${result.predictedConfidence ?? '-'}, '
        'sav: ${_band(result.forecastBandDeg)})',
      )
      ..writeln(
        '    tenyleges TWA : ${_deg(result.actualTwaDeg)}'
        '  (${result.actualSampleCount} minta)',
      )
      ..writeln(
        '    delta         : ${_signedDeg(result.deltaDeg)}'
        '  ${_bandVerdict(result.isWithinBand)}',
      )
      ..writeln('    lead-time     : ${_lead(result.leadTime)}')
      ..writeln();
  }
  return (buffer..write(_summary(results))).toString();
}

/// CSV-t epit a delta-tablahoz (`--csv`): fejlec + soronkent egy korozes.
String formatCsv(List<RoundingResult> results) {
  final buffer = StringBuffer()
    ..writeln(
      'from_mark,to_mark,rounded_at_utc,predicted_twa_deg,'
      'actual_twa_deg,delta_deg,forecast_band_deg,within_band,'
      'predicted_confidence,lead_time_s,actual_samples',
    );
  for (final result in results) {
    buffer.writeln(
      <String>[
        result.fromMark,
        result.toMark,
        result.roundedAt.toUtc().toIso8601String(),
        _csv(result.predictedTwaDeg),
        _csv(result.actualTwaDeg),
        _csv(result.deltaDeg),
        _csv(result.forecastBandDeg),
        _csvBool(result.isWithinBand),
        result.predictedConfidence ?? '',
        result.leadTime?.inSeconds.toString() ?? '',
        result.actualSampleCount.toString(),
      ].join(','),
    );
  }
  return buffer.toString();
}

String _summary(List<RoundingResult> results) {
  final withBand = results.where((r) => r.isWithinBand != null).toList();
  final hits = withBand.where((r) => r.isWithinBand!).length;
  final deltas = <double>[
    for (final r in results)
      if (r.deltaDeg != null) r.deltaDeg!.abs(),
  ];
  final leads = <int>[
    for (final r in results)
      if (r.leadTime != null) r.leadTime!.inSeconds,
  ];

  final buffer = StringBuffer('Osszegzes: ');
  if (withBand.isEmpty) {
    buffer.write('nincs sav-adat');
  } else {
    buffer.write('$hits/${withBand.length} savon belul');
  }
  if (deltas.isNotEmpty) {
    final mean = deltas.reduce((a, b) => a + b) / deltas.length;
    buffer.write(', atlag |delta| ${mean.toStringAsFixed(1)} fok');
  }
  if (leads.isNotEmpty) {
    final mean = (leads.reduce((a, b) => a + b) / leads.length).round();
    buffer.write(', atlag lead-time ${_lead(Duration(seconds: mean))}');
  }
  return (buffer..writeln()).toString();
}

String _hms(DateTime time) {
  final utc = time.toUtc();
  String pad(int n) => n.toString().padLeft(2, '0');
  return '${pad(utc.hour)}:${pad(utc.minute)}:${pad(utc.second)}Z';
}

String _deg(double? value) =>
    value == null ? 'n/a' : '${value.toStringAsFixed(1)} fok';

String _signedDeg(double? value) {
  if (value == null) return 'n/a';
  final sign = value >= 0 ? '+' : '';
  return '$sign${value.toStringAsFixed(1)} fok';
}

String _band(double? value) =>
    value == null ? 'n/a' : '+/-${value.toStringAsFixed(1)} fok';

String _bandVerdict(bool? within) {
  if (within == null) return '';
  return within ? '-> SAVON BELUL' : '-> SAVON KIVUL';
}

String _lead(Duration? duration) {
  if (duration == null) return 'nem volt megbizhato';
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds % 60;
  return minutes > 0 ? '$minutes min $seconds s' : '$seconds s';
}

String _csv(double? value) => value == null ? '' : value.toStringAsFixed(2);

String _csvBool(bool? value) {
  if (value == null) return '';
  return value ? '1' : '0';
}
