import 'package:equatable/equatable.dart';
import 'package:race_archive_api/src/auth/account_info.dart';

/// A sikeres regisztráció (ADR 0051 D3, D6).
final class EnrollmentResult extends Equatable {
  /// Eredmény a megadott mezőkkel.
  const EnrollmentResult({
    required this.account,
    required this.deviceId,
    required this.recoveryCodes,
  });

  /// Az `owner` fiókja.
  final AccountInfo account;

  /// Az új eszköz azonosítója; az app ezt teszi az aláírt üzenetekbe.
  final String deviceId;

  /// A 10 helyreállító kód; csak most látszik (18g).
  final List<String> recoveryCodes;

  @override
  List<Object?> get props => [account, deviceId, recoveryCodes];

  // A kódok titkok; ne kerüljenek naplóba.
  @override
  String toString() => 'EnrollmentResult($account, $deviceId, …)';
}
