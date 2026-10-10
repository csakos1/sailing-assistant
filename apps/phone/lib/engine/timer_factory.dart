import 'dart:async';

/// Időzítő-gyártó: az élesben `Timer.new`, tesztben egy kézzel léptetett
/// hamis időzítő. Így a próba-ciklus és a 10 perces tétlenség-figyelés valódi
/// várakozás nélkül tesztelhető (ADR 0054 D4, D5).
typedef TimerFactory =
    Timer Function(Duration duration, void Function() callback);
