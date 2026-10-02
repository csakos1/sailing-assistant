import 'package:flutter/foundation.dart';

/// Egy adatsor a dialógus adatcellájában: címke balra, érték jobbra
/// (makett 11a, ADR 0048 Addendum 4 K13).
typedef ForetackDialogDetail = ({String label, String value});

/// A dialógus egy akció-cellája.
///
/// A [value] az a válasz, amellyel a dialógus bezárul. A destruktív akció
/// piros; a biztonságos akció kapja a kezdő fókuszt.
@immutable
class ForetackDialogAction<T> {
  /// Akció a [label] felirattal, amely a [value]-val zár.
  const ForetackDialogAction({
    required this.label,
    required this.value,
    this.isDestructive = false,
  });

  /// A cella felirata.
  final String label;

  /// A dialógus válasza, ha erre az akcióra kattintanak.
  final T value;

  /// Visszafordíthatatlan műveletet indít-e (piros felirat).
  final bool isDestructive;
}
