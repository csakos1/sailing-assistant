import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:race_archive_api/race_archive_api.dart';

// A polar-tesztek kozos adatai: egy mutato-keszlet es egy verseny-sor a
// szerzodes szerint, es a valaszok a MockClient-hez.

/// Mutatok a mintaadat Lelle kupa soraval (16a): 83,6 / 85,2 / 102,2 /
/// 111,8 / 116,7 / 40,1% / 14,5%, 9,5 kn szel.
PolarStats samplePolarStats({
  int measuredSeconds = 3600,
  double? avgTwsMps = 4.89,
  double? bestFivePct = 116.7,
  double avgPct = 83.6,
}) => PolarStats(
  measuredSeconds: measuredSeconds,
  avgTwsMps: avgTwsMps,
  avgPct: avgPct,
  medianPct: 85.2,
  p90Pct: 102.2,
  p99Pct: 111.8,
  bestFivePct: bestFivePct,
  shareAtLeast90: 0.401,
  shareAtLeast100: 0.145,
);

/// Egy verseny sora a [raceId] azonositoval a [day] napon.
RacePolarRow samplePolarRow(
  String raceId, {
  String day = '2026-08-22',
  PolarStats? stats,
  int? rank,
  Duration? elapsed = const Duration(hours: 2, minutes: 53),
  bool isApproximate = false,
  PolarCacheState cacheState = PolarCacheState.fresh,
}) => RacePolarRow(
  raceId: raceId,
  name: 'Verseny $raceId',
  // A tesztben a nap mindig ervenyes ISO-datum.
  day: CalendarDate.tryParse(day)!,
  elapsed: elapsed,
  isApproximate: isApproximate,
  cacheState: cacheState,
  stats: stats,
  rank: rank,
);

/// JSON-valasz a [body]-val, magyar ekezetekkel is.
Future<http.Response> polarJson(Object? body, {int status = 200}) async =>
    http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

/// A szerver "nincs polar" valasza (ADR 0049 D5).
Future<http.Response> polarUnavailableResponse() =>
    polarJson(encodeApiError(const PolarUnavailable()), status: 503);
