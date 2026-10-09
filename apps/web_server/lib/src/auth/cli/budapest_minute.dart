import 'package:web_server/src/legacy/budapest_time.dart';

/// Az [instant] budapesti ideje percre: `2026-10-06 21:30`.
String budapestMinuteOf(DateTime instant) {
  final local = budapestWallClockOf(instant);
  String two(int value) => value.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)} '
      '${two(local.hour)}:${two(local.minute)}';
}
