import 'package:flutter/widgets.dart';

/// Egy másodlagos akció az űrlap-sáv felső sorában (ADR 0044 D50).
///
/// Érték-osztály: a sáv API-ja `List<FormBarAction>`-t vesz át a korábbi
/// `secondaryLabel` / `secondaryIcon` / `onSecondary` nullable hármas
/// helyett. A hármas **egy** akciót írt le, a kétsoros sávban viszont
/// kettő van (bója hozzáadása és könyvtár), a lista pedig nyitva hagyja a
/// harmadikat is anélkül, hogy az API-t újra kellene bontani.
///
/// Az **üres** lista ugyanazt jelenti, amit korábban a három `null`: a sáv
/// egyetlen, teljes szélességű primary gombra esik (ADR 0046 D4).
@immutable
class FormBarAction {
  /// Egy másodlagos akció.
  const FormBarAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  /// A cella felirata.
  final String label;

  /// A felirat előtti ikon.
  final IconData icon;

  /// A koppintás akciója.
  final VoidCallback onTap;
}
