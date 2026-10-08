import 'package:flutter/foundation.dart';
import 'package:phone/features/web_access/application/web_access_error.dart';
import 'package:phone/features/web_access/data/web_key_operations.dart';

/// Egy webes hozzáférési hiba kiírása a konzolra (`flutter run`, logcat).
///
/// A „Nincs hálózat" panel több okot gyűjt egybe (hálózat, olvashatatlan
/// válasz, ismeretlen szerverhiba, V6); a próbán így látszik, melyik volt.
/// A hibák szövege titkot nem tartalmaz. Az elvetett ujjlenyomat-ablak
/// nem hiba, azt nem írja ki.
void logWebAccessError(WebAccessError error) {
  if (error case KeyOperationFailed(failure: KeyOperationFailure.canceled)) {
    return;
  }
  debugPrint('web_access: $error');
}

/// Egy váratlan kivétel kiírása, amely egy panelhez vezetett.
void logWebAccessException(Exception exception) =>
    debugPrint('web_access: unexpected $exception');
