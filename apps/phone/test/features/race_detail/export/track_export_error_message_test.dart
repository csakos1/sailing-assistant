import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/features/race_detail/export/track_export_error.dart';
import 'package:phone/features/race_detail/export/track_export_error_message.dart';
import 'package:phone/l10n/app_localizations.dart';

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('hu'));
  });

  // A `cause` tipusa kozombos: az uzenet a hiba FAJTAJABOL kovetkezik.
  // Nem-const peldany, hogy a prefer_const_constructors ne szoljon bele.
  List<TrackExportError> allErrors() => [
    CaptureFailed(Exception('boom')),
    StorageUnavailable(Exception('boom')),
    ShareFailed(Exception('boom')),
  ];

  test('minden hibaag sajat, nem ures uzenetet kap', () {
    // ARRANGE
    final errors = allErrors();

    // ACT
    final messages = [
      for (final error in errors) trackExportErrorMessage(error, l10n),
    ];

    // ASSERT — a klasszikus masolas-hiba (ket ag ugyanarra az ARB-kulcsra
    // mutat) igy bukik el, es nem a vizparton derul ki.
    expect(messages.toSet().length, errors.length);
    expect(messages.every((m) => m.trim().isNotEmpty), isTrue);
  });

  test('az uzenet nem szivarogtatja ki a technikai okot', () {
    // ARRANGE — a `cause` egy nyers platform-hiba szovegevel.
    final error = ShareFailed(Exception('MissingPluginException: share'));

    // ACT
    final message = trackExportErrorMessage(error, l10n);

    // ASSERT — a SnackBar a felhasznaloe, nem a naploe.
    expect(message, isNot(contains('MissingPluginException')));
    expect(message, isNot(contains('Exception')));
  });
}
