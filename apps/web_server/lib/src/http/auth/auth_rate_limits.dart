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
  });

  /// A D8 számai: végpontonként IP-nként percenként 10.
  factory AuthRateLimits.standard({DateTime Function() now = utcNow}) {
    RateLimiter perMinute() =>
        RateLimiter(limit: 10, window: const Duration(minutes: 1), now: now);
    return AuthRateLimits(
      loginRequests: perMinute(),
      openings: perMinute(),
      approvals: perMinute(),
      enrollments: perMinute(),
      deviceChallenges: perMinute(),
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
}
