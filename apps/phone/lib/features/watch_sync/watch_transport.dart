import 'package:shared/shared.dart';

/// A telefon→óra küldés absztrakciója (DIP): a `WatchSyncController` ezen át
/// szinkronizál. A konkrét natív implementációt (`PhoneWearableBridge`,
/// MethodChannel) a slice 3 adja — egy ilyen szignatúrájú függvényként.
///
/// Szerződés (LSP): a függvény **nem dob** — az implementáció az átmeneti
/// natív/platform-hibákat maga kezeli/logolja. A hívó nem védekezik kivételre,
/// mert a passzív óra a következő változásnál úgyis újraszinkronizál.
typedef WatchTransport = Future<void> Function(WatchPayload payload);
