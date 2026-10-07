import 'package:equatable/equatable.dart';
import 'package:race_archive_api/src/auth/account_info.dart';
import 'package:race_archive_api/src/auth/member_device.dart';

/// Egy tag (vagy az `owner`) az aktív eszközeivel (ADR 0051 Addendum 5
/// M7).
final class MemberInfo extends Equatable {
  /// Tag a megadott mezőkkel.
  const MemberInfo({
    required this.account,
    required this.createdAt,
    required this.devices,
  });

  /// A fiók.
  final AccountInfo account;

  /// A fiók létrejötte (UTC).
  final DateTime createdAt;

  /// Az aktív eszközök, a legrégebbi elöl.
  final List<MemberDevice> devices;

  @override
  List<Object?> get props => [account, createdAt, devices];
}
