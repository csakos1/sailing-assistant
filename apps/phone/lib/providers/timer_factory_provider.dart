import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/engine/timer_factory.dart';

/// Az időzítő-gyártó: élesben `Timer.new`, tesztben kézzel léptetett hamis
/// időzítő (a próba-ciklus és a tétlenség-figyelés ezt kapja).
final timerFactoryProvider = Provider<TimerFactory>((ref) => Timer.new);
