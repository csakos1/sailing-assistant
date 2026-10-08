import 'package:phone/features/web_access/application/hungarian_order.dart';
import 'package:race_archive_api/race_archive_api.dart';

/// Egy felhasználó munkamenetei a 18i csoportjában.
typedef WebSessionGroup = ({
  String userId,
  String userName,
  List<WebSession> sessions,
});

/// A munkamenetek felhasználónként (ADR 0051 Addendum 10 Z10): elöl a
/// [ownUserId] csoportja, a többi a nevük szerint a magyar ábécében;
/// csoporton belül a legutóbb aktív elöl.
List<WebSessionGroup> groupWebSessions(
  List<WebSession> sessions, {
  required String ownUserId,
}) {
  final byUser = <String, List<WebSession>>{};
  for (final session in sessions) {
    (byUser[session.userId] ??= []).add(session);
  }
  final groups = [
    for (final entry in byUser.entries)
      (
        userId: entry.key,
        userName: entry.value.first.userName,
        sessions: [...entry.value]
          ..sort((a, b) => b.lastSeenAt.compareTo(a.lastSeenAt)),
      ),
  ];
  int rankOf(WebSessionGroup group) => group.userId == ownUserId ? 0 : 1;
  return groups..sort((a, b) {
    final byOwner = rankOf(a).compareTo(rankOf(b));
    return byOwner != 0 ? byOwner : compareHungarian(a.userName, b.userName);
  });
}
