/// A csatlakozási kérelem élettartama (ADR 0051 D3, Addendum 5 M3); a
/// 18e-2 „Elküldve" sora a lejáratból ennyit visszaszámolva adódik (X4).
const Duration joinRequestValidity = Duration(hours: 24);

/// A lejáratig hátralévő idő egész órákban és percekben, a [now]
/// pillanattól; lejárt kérelemnél nulla.
({int hours, int minutes}) joinTimeLeft(DateTime expiresAt, DateTime now) {
  final left = expiresAt.difference(now);
  if (left.isNegative) return (hours: 0, minutes: 0);
  return (hours: left.inHours, minutes: left.inMinutes % 60);
}

/// Egy pillanat helyi idő szerint, `ÓÓ:PP` alakban.
String formatLocalClock(DateTime moment) {
  final local = moment.toLocal();
  String twoDigits(int value) => value.toString().padLeft(2, '0');
  return '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
}
