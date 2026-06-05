import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wear_ongoing_activity/wear_ongoing_activity.dart';

/// Az óra verseny-kijelzőjét láthatóan tartó Ongoing Activity életciklusát
/// absztraháló varrat (DIP, ADR 0019 + Addendum A1).
///
/// A `RaceShell` ezen át indítja/állítja az Ongoing Activity-t a kijelző
/// mount/unmountjához kötve; a tesztek spy-jal helyettesítik (nincs natív
/// hívás). A telefon-oldali `ScreenWakeLock` óra-oldali, láthatósági párja.
abstract interface class RaceOngoingActivity {
  /// Elindítja a verseny Ongoing Activity-t (foreground service + ongoing
  /// notification), hogy a kijelző a számlapra-esés (Timeout #2) ellen
  /// látható maradjon.
  Future<void> start();

  /// Leállítja az Ongoing Activity-t (a verseny-kijelző elhagyásakor).
  Future<void> stop();
}

/// A `wear_ongoing_activity` plugint csomagoló konkrét adapter — az egyetlen
/// natív-érintő pont. A `POST_NOTIFICATIONS` engedélyt is itt, indítás előtt
/// kérjük el a `permission_handler`-rel: Wear OS 4 / API 33+-on enélkül az
/// ongoing notification néma marad, és nincs láthatóság-tartás.
final class WearOngoingActivityAdapter implements RaceOngoingActivity {
  /// Létrehozza az adaptert.
  const WearOngoingActivityAdapter();

  // Fix, ütközésmentes notification-id a verseny Ongoing Activity-hez.
  static const _notificationId = 0xF02E;

  @override
  Future<void> start() async {
    // API 33+-on futásidejű grant; alacsonyabb szinten azonnal granted.
    await Permission.notification.request();
    await WearOngoingActivity.start(
      channelId: 'race_ongoing',
      channelName: 'Verseny',
      notificationId: _notificationId,
      category: NotificationCategory.workout,
      // Statikus ikon + touch-intent kötelező (különben IllegalArgumentException);
      // az ic_ongoing monokróm, átlátszó hátterű vektor a res/drawable-ben.
      smallIcon: 'ic_ongoing',
      staticIcon: 'ic_ongoing',
      status: OngoingActivityStatus(
        templates: ['#label#'],
        parts: [TextPart(name: 'label', text: 'Foretack — verseny')],
      ),
    );
  }

  @override
  Future<void> stop() => WearOngoingActivity.stop();
}

/// Az `apps/watch` Ongoing Activity-seamje. Default a natív adapter; a tesztek
/// spy-jal felülírják.
final raceOngoingActivityProvider = Provider<RaceOngoingActivity>(
  (ref) => const WearOngoingActivityAdapter(),
);
