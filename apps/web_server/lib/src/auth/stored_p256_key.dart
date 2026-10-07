import 'package:web_server/src/auth/p256_public_key.dart';

/// A DB-ben tárolt [spki] kulcs mint [P256PublicKey].
///
/// A regisztráció csak ellenőrzött kulcsot ír be, ezért egy olvashatatlan
/// kulcs sérült DB-t jelent: az üzemeltetési hiba, nem rossz bemenet, és a
/// kivételfogón át `500` lesz.
P256PublicKey storedP256Key(List<int> spki) =>
    P256PublicKey.tryParse(spki) ??
    (throw StateError('invalid stored P-256 key'));
