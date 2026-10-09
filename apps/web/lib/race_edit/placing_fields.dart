import 'package:flutter/widgets.dart';
import 'package:foretack_web/race_edit/form/result_form_values.dart';

/// Egy helyezés-pár szerkeszthető mezői (ADR 0048 Addendum 4 K11).
class PlacingFields {
  /// Mezők az [initial] értékekkel előtöltve.
  PlacingFields(PlacingFormValues initial)
    : kind = ValueNotifier(initial.kind),
      place = TextEditingController(text: initial.place),
      fleetSize = TextEditingController(text: initial.fleetSize);

  /// A `[SZÁM | DNF | DSQ]` szegmens választása.
  final ValueNotifier<PlacingKind> kind;

  /// A helyezés szövege.
  final TextEditingController place;

  /// A mezőny szövege.
  final TextEditingController fleetSize;

  /// A helyezés-mező fókusza.
  final FocusNode placeFocus = FocusNode();

  /// A mezőny-mező fókusza.
  final FocusNode fleetSizeFocus = FocusNode();

  /// A mezők mostani értéke.
  PlacingFormValues get values =>
      (kind: kind.value, place: place.text, fleetSize: fleetSize.text);

  /// Minden változás egy jelzésben.
  late final Listenable changes = Listenable.merge([kind, place, fleetSize]);

  /// Felszabadítja a vezérlőket.
  void dispose() {
    kind.dispose();
    place.dispose();
    fleetSize.dispose();
    placeFocus.dispose();
    fleetSizeFocus.dispose();
  }
}
