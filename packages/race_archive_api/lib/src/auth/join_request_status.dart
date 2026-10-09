import 'package:equatable/equatable.dart';
import 'package:race_archive_api/src/auth/account_info.dart';

/// Egy csatlakozási kérelem állapota a telefon szemszögéből (ADR 0051
/// Addendum 5 M1, M4).
enum JoinRequestState {
  /// Az `owner` még nem döntött.
  pending,

  /// Jóváhagyva: a telefon a válaszban kapja a fiókját és az eszközét.
  approved,

  /// Elutasítva, lejárt vagy ismeretlen; a telefon ezeket nem különbözteti
  /// meg („A kérelem nem lett jóváhagyva").
  notApproved,
}

/// A kérelem lekérdezésének válasza.
final class JoinRequestStatus extends Equatable {
  /// Állapot; az [account] és a [deviceId] csak `approved`-nál van.
  const JoinRequestStatus({required this.state, this.account, this.deviceId});

  /// Az állapot.
  final JoinRequestState state;

  /// A jóváhagyott fiók, ha a [state] `approved`.
  final AccountInfo? account;

  /// Az új eszköz azonosítója, ha a [state] `approved`.
  final String? deviceId;

  @override
  List<Object?> get props => [state, account, deviceId];
}
