import 'dart:math';
import 'dart:typed_data';

/// [length] darab véletlen bájt.
///
/// Függvény-típus, hogy a tesztek rögzített bájtokat adhassanak; a
/// szerveren mindig a [secureRandomBytes] áll mögötte.
typedef RandomBytes = Uint8List Function(int length);

final Random _secureRandom = Random.secure();

/// [length] kriptográfiailag biztonságos véletlen bájt (`Random.secure`).
Uint8List secureRandomBytes(int length) => Uint8List.fromList([
  for (var i = 0; i < length; i++) _secureRandom.nextInt(256),
]);
