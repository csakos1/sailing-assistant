import 'package:race_archive_api/race_archive_api.dart';
import 'package:shelf/shelf.dart';
import 'package:web_server/src/auth/rate_limiter.dart';
import 'package:web_server/src/http/json_response.dart';

/// `429` a `Retry-After` fejléccel, ha a [limiter] a [key]-re nem enged
/// több próbálkozást; különben `null`, és a próbálkozás beszámít (ADR 0051
/// D8).
Response? rateLimitedResponse(RateLimiter limiter, String key) {
  final wait = limiter.tryAcquire(key);
  if (wait == null) return null;
  // Felfelé kerekítve, legalább 1: a kliens ne próbálkozzon túl korán.
  final rounded = (wait.inMilliseconds + 999) ~/ 1000;
  final seconds = rounded < 1 ? 1 : rounded;
  return apiErrorResponse(
    TooManyAttempts(seconds),
  ).change(headers: {'retry-after': '$seconds'});
}
