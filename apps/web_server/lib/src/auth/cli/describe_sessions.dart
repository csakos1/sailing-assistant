import 'package:race_archive_api/race_archive_api.dart';
import 'package:web_server/src/auth/cli/budapest_minute.dart';

/// Az `end_sessions` listája: soronként egy élő munkamenet az
/// azonosítójával (ezt kell a `--session`-nek adni), a fiókkal és annak
/// azonosítójával (a `--user`-hez), a móddal, a címmel és az időkkel
/// (ADR 0052 D10).
List<String> describeSessions(List<WebSession> sessions) {
  if (sessions.isEmpty) return const ['Nincs élő webes munkamenet.'];
  return [for (final session in sessions) _sessionLine(session)];
}

String _sessionLine(WebSession session) {
  final browser = [?session.browser, ?session.os].join(' · ');
  final place = [?session.city, ?session.country].join(', ');
  return [
    session.id,
    '${session.userName} (${session.userId})',
    _methodLabel(session.method),
    if (place.isEmpty) session.ip else '${session.ip} $place',
    if (browser.isNotEmpty) browser,
    'belépett ${budapestMinuteOf(session.createdAt)}',
    'utoljára ${budapestMinuteOf(session.lastSeenAt)}',
    if (session.isSuspicious) 'GYANÚS',
  ].join('  ');
}

String _methodLabel(LoginMethod method) => switch (method) {
  LoginMethod.qr => 'QR',
  LoginMethod.password => 'jelszó',
  LoginMethod.recoveryCode => 'kód',
};
