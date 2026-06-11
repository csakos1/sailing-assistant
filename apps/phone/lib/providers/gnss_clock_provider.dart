import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/app/geolocator_gnss_clock.dart';
import 'package:phone/app/gnss_clock.dart';

/// A GNSS-óra fix-stream-seamjét adó keep-alive provider.
///
/// Keep-alive, mert a true-time anchor (ADR 0012) a live screen re-mountját is
/// túléli; a `trueTimeProvider` ezt hívja a fix-burstökhöz. Tesztben fake
/// `GnssClock` stream-mel override-olható.
final gnssClockProvider = Provider<GnssClock>((ref) => geolocatorFixStream);
