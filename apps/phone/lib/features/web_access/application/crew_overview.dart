import 'package:flutter/foundation.dart';
import 'package:phone/features/web_access/application/hungarian_order.dart';
import 'package:race_archive_api/race_archive_api.dart';

/// A „Legénység" képernyő adatai egy betöltésből (ADR 0051 Addendum 10
/// Z11, makett 18k–18k-3).
///
/// A tagonkénti webes aktivitás nem a szerver mezője, hanem a
/// munkamenetekből jön: az `owner` mindenki munkamenetét látja (M8), így
/// új végpont nélkül összerakható (Z1).
@immutable
class CrewOverview {
  /// Áttekintés a [requests] kérelmekkel, a [members] fiókokkal és a
  /// [sessions] munkamenetekkel.
  const CrewOverview({
    required this.requests,
    required this.members,
    required this.sessions,
  });

  /// Nincs mit mutatni (fiók nélkül).
  static const CrewOverview empty = CrewOverview(
    requests: [],
    members: [],
    sessions: [],
  );

  /// Az el nem döntött csatlakozási kérelmek, a szerver sorrendjében
  /// (legújabb elöl).
  final List<PendingJoinRequest> requests;

  /// Minden fiók az aktív eszközeivel.
  final List<MemberInfo> members;

  /// Minden élő webes munkamenet.
  final List<WebSession> sessions;

  /// A fiókok: az `owner` elöl, a többi a magyar ábécé szerint (Z8). A
  /// szerver bájtsorrendben ad (az „Ádám" a „Zoli" után jönne).
  List<MemberInfo> get orderedMembers => [...members]
    ..sort((a, b) {
      final byRole = _rankOf(a).compareTo(_rankOf(b));
      return byRole != 0
          ? byRole
          : compareHungarian(a.account.name, b.account.name);
    });

  /// A legénység tagjai (az `owner` nélkül), a jóváhagyó lap
  /// választásához (Z2: `owner`-eszköz csak a CLI-vel jöhet).
  List<MemberInfo> get crewMembers => [
    for (final member in orderedMembers)
      if (member.account.role == UserRole.crew) member,
  ];

  /// A [userId] fiók, vagy `null`, ha közben eltávolították.
  MemberInfo? memberById(String userId) {
    for (final member in members) {
      if (member.account.userId == userId) return member;
    }
    return null;
  }

  /// A [userId] fiók legutóbb aktív munkamenetének ideje, vagy `null`, ha
  /// nincs élő munkamenete.
  DateTime? lastWebActivityOf(String userId) {
    DateTime? latest;
    for (final session in _sessionsOf(userId)) {
      if (latest == null || session.lastSeenAt.isAfter(latest)) {
        latest = session.lastSeenAt;
      }
    }
    return latest;
  }

  /// A [userId] fiók élő munkameneteinek száma.
  int sessionCountOf(String userId) => _sessionsOf(userId).length;

  Iterable<WebSession> _sessionsOf(String userId) =>
      sessions.where((session) => session.userId == userId);
}

int _rankOf(MemberInfo member) => member.account.role == UserRole.owner ? 0 : 1;
