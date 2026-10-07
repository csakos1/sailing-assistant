import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foretack_web/api/archive_api_client.dart';
import 'package:foretack_web/app/http_client_provider.dart';
import 'package:foretack_web/auth/session_aware_client.dart';
import 'package:foretack_web/auth/session_provider.dart';

/// Az archívum API-kliense, az oldal saját címéhez képest (ADR 0048
/// Addendum 4 K1, K5): élesben és lokálisan is ugyanaz az origin.
///
/// A kérései a `SessionAwareClient`-en mennek: egy `401` a munkamenetet
/// lejárttá teszi (ADR 0051 Addendum 7 P3). A belépett fiók változásakor
/// (belépés, lejárat, kijelentkezés) a kliens újraépül, és vele az
/// archívum providerei is: egy lejárat előtti `401` hibája így nem ragad
/// be a következő belépésre.
final Provider<ArchiveApiClient> archiveApiClientProvider =
    Provider<ArchiveApiClient>((ref) {
      ref.watch(signedInUserIdProvider);
      return ArchiveApiClient(
        SessionAwareClient(
          ref.watch(httpClientProvider),
          onUnauthorized: () => ref.read(sessionProvider.notifier).expire(),
        ),
        baseUri: Uri.base,
      );
    });
