import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/app/geolocator_gnss_clock.dart';
import 'package:phone/app/gnss_clock.dart';

/// A GNSS-óra függvény-seam-jét adó keep-alive provider.
///
/// Keep-alive, mert a true-time anchor (ADR 0012) a live screen re-mountját is
/// túléli; a `trueTimeProvider` ezt hívja a fix-ekhez. Tesztben fake
/// `GnssClock` függvénnyel override-olható.
final gnssClockProvider = Provider<GnssClock>(
  (ref) => geolocatorCurrentUtcFix,
);
