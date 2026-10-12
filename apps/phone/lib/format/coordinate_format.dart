import 'package:domain/domain.dart';

/// Egy koordináta tizedes fokban, négy jeggyel: „46.9000, 18.0500".
///
/// A részlet bója- és rajthely-sora írja így (ADR 0044 D25; az U6-ban a
/// felhasználó a makett fok-perces alakja helyett ezt tartotta meg, mert a
/// bevitel is tizedes fok).
String formatDecimalCoordinate(Coordinate position) =>
    '${position.latitude.toStringAsFixed(4)}, '
    '${position.longitude.toStringAsFixed(4)}';
