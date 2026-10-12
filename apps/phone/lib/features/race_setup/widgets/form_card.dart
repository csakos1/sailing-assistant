import 'package:flutter/material.dart';

/// Egy űrlap-kártya kerete (33a, a 9e nyelve): `outline` keret,
/// `surfaceContainer` háttér, lekerekítés nélkül.
///
/// A [isTransparent] az üres rajthely-kártyáé (33b): ott csak a keret
/// látszik, mert a kártya még nem tartalom, hanem egy hely.
class FormCard extends StatelessWidget {
  /// Egy kártya a [child]-dal.
  const FormCard({required this.child, this.isTransparent = false, super.key});

  /// A kártya tartalma.
  final Widget child;

  /// Átlátszó háttér (az üres rajthely-hely).
  final bool isTransparent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // Material, nem DecoratedBox: a kártyán belüli InkWell-ek (rajtidő,
    // rajthely-utak) a legközelebbi Material-ra festenek, és egy színes
    // DecoratedBox eltakarná a hullámot.
    return Material(
      color: isTransparent ? Colors.transparent : scheme.surfaceContainer,
      shape: Border.all(color: scheme.outline),
      child: child,
    );
  }
}
