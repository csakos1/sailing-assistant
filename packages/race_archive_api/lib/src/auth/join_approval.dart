import 'package:equatable/equatable.dart';
import 'package:race_archive_api/src/auth/signed_action.dart';

/// Egy csatlakozási kérelem jóváhagyása (ADR 0051 Addendum 5 M6).
///
/// [memberId] nélkül új `crew` tag jön létre; vele a meglévő tag kap új
/// eszközt.
final class JoinApproval extends Equatable {
  /// Jóváhagyás az aláírt [action]-nel.
  const JoinApproval({required this.action, this.memberId});

  /// A meglévő tag azonosítója, vagy `null` új tagnál.
  final String? memberId;

  /// Az `approveJoin` aláírása.
  final SignedAction action;

  @override
  List<Object?> get props => [memberId, action];

  @override
  String toString() => 'JoinApproval(${memberId ?? 'new'}, …)';
}

/// Az `approveJoin` művelet `target` sora (Addendum 3 K4): `<kérelem>:new`
/// vagy `<kérelem>:<memberId>`. A telefon és a szerver ugyanezt írja alá,
/// illetve ellenőrzi.
String joinApprovalTarget({
  required String joinRequestId,
  required String? memberId,
}) => '$joinRequestId:${memberId ?? 'new'}';
