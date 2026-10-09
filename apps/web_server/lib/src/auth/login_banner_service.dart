import 'package:race_archive_api/race_archive_api.dart';
import 'package:web_server/src/auth/device_token_service.dart';
import 'package:web_server/src/auth/utc_now.dart';
import 'package:web_server/src/auth_db/join_request_repository.dart';
import 'package:web_server/src/auth_db/login_event_repository.dart';

/// Ennyi ideig látszik egy nyugtázatlan gyanús belépés a szalagon, és
/// ennyi után törlődik az esemény (ADR 0051 Addendum 3 K9, Addendum 6 N1,
/// N5).
const Duration loginEventRetention = Duration(days: 30);

/// A telefon szalagja és a gyanús belépések nyugtázása (ADR 0051 D7,
/// Addendum 1 H8, Addendum 6 N6).
///
/// Az `owner` mindenki eseményét látja és nyugtázza, a `crew` csak a
/// sajátját.
class LoginBannerService {
  /// Szolgáltatás az események és a kérelmek fölött.
  LoginBannerService({
    required LoginEventRepository events,
    required JoinRequestRepository joinRequests,
    DateTime Function() now = utcNow,
  }) : _events = events,
       _joinRequests = joinRequests,
       _now = now;

  final LoginEventRepository _events;
  final JoinRequestRepository _joinRequests;
  final DateTime Function() _now;

  /// A [caller] szalagja.
  Future<LoginBanner> banner(DeviceCaller caller) async {
    final now = _now();
    final isOwner = caller.user.role == UserRole.owner;
    final suspicious = await _events.listUnacknowledgedSuspicious(
      since: now.subtract(loginEventRetention),
      userId: isOwner ? null : caller.user.id,
    );
    final pending = isOwner
        ? (await _joinRequests.listPending(now: now)).length
        : 0;
    return LoginBanner(suspicious: suspicious, pendingJoinRequests: pending);
  }

  /// Az [eventId] esemény nyugtázása; `null`, ha sikerült vagy nincs ilyen
  /// esemény (két telefon egyszerre nyugtáz).
  Future<ApiError?> acknowledge(DeviceCaller caller, String eventId) async {
    final userId = await _events.userIdOf(eventId);
    if (userId == null) return null;
    final isOwn = userId == caller.user.id;
    if (!isOwn && caller.user.role != UserRole.owner) {
      return const NotAllowed();
    }
    await _events.acknowledge(eventId, now: _now());
    return null;
  }

  /// A [loginEventRetention]-nél régebbi események törlése (a szerver
  /// időnként hívja).
  Future<void> deleteExpired() =>
      _events.deleteOlderThan(_now().subtract(loginEventRetention));
}
