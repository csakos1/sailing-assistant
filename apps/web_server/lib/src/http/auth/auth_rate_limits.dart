import 'package:web_server/src/auth/rate_limiter.dart';
import 'package:web_server/src/auth/utc_now.dart';

/// A hitelesítési végpontok próbálkozás-korlátai, IP-nként (ADR 0051 D8,
/// Addendum 4 L7).
final class AuthRateLimits {
  /// Korlátok a megadott limiterekkel (a tesztek lazábbat adhatnak).
  const AuthRateLimits({
    required this.loginRequests,
    required this.openings,
    required this.approvals,
    required this.enrollments,
    required this.deviceChallenges,
    required this.actionChallenges,
    required this.joinRequests,
  });

  /// A D8 számai: végpontonként IP-nként percenként 10, a csatlakozási
  /// kérelem óránként 3 (Addendum 5 M12).
  factory AuthRateLimits.standard({DateTime Function() now = utcNow}) {
    RateLimiter perMinute() =>
        RateLimiter(limit: 10, window: const Duration(minutes: 1), now: now);
    return AuthRateLimits(
      loginRequests: perMinute(),
      openings: perMinute(),
      approvals: perMinute(),
      enrollments: perMinute(),
      deviceChallenges: perMinute(),
      actionChallenges: perMinute(),
      joinRequests: RateLimiter(
        limit: 3,
        window: const Duration(hours: 1),
        now: now,
      ),
    );
  }

  /// Új belépési kérés a webről.
  final RateLimiter loginRequests;

  /// Egy kérés megnyitása a telefonról.
  final RateLimiter openings;

  /// Egy kérés jóváhagyása a telefonról.
  final RateLimiter approvals;

  /// Az `owner` telefonjának regisztrációja.
  final RateLimiter enrollments;

  /// Kihívás az eszköz-tokenhez (a token csak kihívással kérhető).
  final RateLimiter deviceChallenges;

  /// Kihívás egy ujjlenyomatos művelethez.
  final RateLimiter actionChallenges;

  /// Csatlakozási kérelem a fiók nélküli telefonról.
  final RateLimiter joinRequests;
}
