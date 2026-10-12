import 'package:flutter/foundation.dart';

/// A snackbar egyetlen akciója (pl. VISSZAVONÁS, makett 35e).
@immutable
class ForetackSnackBarAction {
  /// Akció a [label] felirattal; koppintásra a snackbar bezárul, és az
  /// [onPressed] fut.
  const ForetackSnackBarAction({
    required this.label,
    required this.onPressed,
  });

  /// A felirat; a snackbar mono verzállal írja ki.
  final String label;

  /// A koppintás teendője.
  final VoidCallback onPressed;
}
