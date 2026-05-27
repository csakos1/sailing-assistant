import 'dart:async';

import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/features/debug/raw_nmea_viewer_screen.dart';
import 'package:phone/l10n/app_localizations.dart';
import 'package:phone/providers/nmea_stream_provider.dart';

void main() {
  group('RawNmeaViewerScreen', () {
    testWidgets(
      'üres állapotban a viewerEmptyState szöveget mutatja, ListView nincs',
      (tester) async {
        final fake = _FakeRawNmeaStream(initial: const Connecting());
        await _pumpViewer(tester, fake: fake);

        expect(find.text('Még nem érkezett sor.'), findsOneWidget);
        expect(find.byType(ListView), findsNothing);
      },
    );

    testWidgets(
      'a három fő ConnectionStatus-altípusra a megfelelő chip-szöveget '
      'rendereli',
      (tester) async {
        final fake = _FakeRawNmeaStream(initial: const Connecting());
        await _pumpViewer(tester, fake: fake);

        // initial: Connecting
        expect(find.text('Csatlakozás…'), findsOneWidget);

        fake.pushStatus(const Connected());
        await tester.pumpAndSettle();
        expect(find.text('Csatlakozva'), findsOneWidget);

        fake.pushStatus(const Disconnected());
        await tester.pumpAndSettle();
        expect(find.text('Nincs kapcsolat'), findsOneWidget);
      },
    );

    testWidgets(
      'ConnectionError esetén a hibaüzenet a chipen és a Tooltipben is látszik',
      (tester) async {
        final fake = _FakeRawNmeaStream(initial: const Connecting());
        await _pumpViewer(tester, fake: fake);

        fake.pushStatus(const ConnectionError('Kapcsolat megszakadt'));
        await tester.pumpAndSettle();

        // A chip-label szövege a "Hiba: {message}" placeholder-mintából.
        expect(find.text('Hiba: Kapcsolat megszakadt'), findsOneWidget);

        // A privát _ConnectionStatusChip nem elérhető byType-pal, viszont a
        // Tooltip-Chip ős-leszármazási kapcsolat egyértelmű: csak akkor van
        // Tooltip a Chip ős-elemei között, ha ConnectionError state van.
        final tooltipFinder = find.ancestor(
          of: find.byType(Chip),
          matching: find.byType(Tooltip),
        );
        expect(tooltipFinder, findsOneWidget);
        expect(
          tester.widget<Tooltip>(tooltipFinder).message,
          'Kapcsolat megszakadt',
        );
      },
    );

    testWidgets(
      'a beérkező nyers sorokat legújabb-felül listázza',
      (tester) async {
        final fake = _FakeRawNmeaStream(initial: const Connected());
        await _pumpViewer(tester, fake: fake);

        fake
          ..pushLine(r'$GPRMC,1')
          ..pushLine(r'$GPRMC,2')
          ..pushLine(r'$GPRMC,3');
        await tester.pumpAndSettle();

        expect(find.text(r'$GPRMC,1'), findsOneWidget);
        expect(find.text(r'$GPRMC,2'), findsOneWidget);
        expect(find.text(r'$GPRMC,3'), findsOneWidget);

        // A ListView-on belüli Text widgetek render-sorrendben: legújabb (3)
        // elöl, legrégebbi (1) hátul.
        final texts = tester
            .widgetList<Text>(
              find.descendant(
                of: find.byType(ListView),
                matching: find.byType(Text),
              ),
            )
            .map((t) => t.data)
            .toList();
        expect(texts, [r'$GPRMC,3', r'$GPRMC,2', r'$GPRMC,1']);
      },
    );
  });
}

Future<void> _pumpViewer(
  WidgetTester tester, {
  required _FakeRawNmeaStream fake,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [nmeaStreamProvider.overrideWithValue(fake)],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: RawNmeaViewerScreen(),
      ),
    ),
  );
  // A SynchronousFuture-os AppLocalizations.delegate egy pumpban betölt; nem
  // pumpAndSettle-elünk, mert az async I/O-ra vakon várakozna és elrejtené a
  // fail-mode-ot, ha a delegátor valamiért nem szinkron lenne.
  await tester.pump();
}

class _FakeRawNmeaStream implements NmeaStream, RawNmeaLineSource {
  _FakeRawNmeaStream({required ConnectionStatus initial}) : _current = initial;

  ConnectionStatus _current;
  final StreamController<ConnectionStatus> _statusChanges =
      StreamController<ConnectionStatus>.broadcast();
  final StreamController<String> _rawLinesController =
      StreamController<String>.broadcast();

  void pushStatus(ConnectionStatus status) {
    _current = status;
    _statusChanges.add(status);
  }

  void pushLine(String line) => _rawLinesController.add(line);

  @override
  Stream<DomainEvent> get events => const Stream<DomainEvent>.empty();

  @override
  Stream<ConnectionStatus> get statusChanges => _statusChanges.stream;

  @override
  ConnectionStatus get currentStatus => _current;

  @override
  Stream<String> get rawLines => _rawLinesController.stream;

  @override
  Future<void> connect() async {}

  @override
  Future<void> disconnect() async {}
}
