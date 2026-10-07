import 'package:equatable/equatable.dart';
import 'package:race_archive_api/src/auth/signed_action.dart';

/// Az `owner` új tartalék-jelszava (ADR 0051 D6, Addendum 6 N4), a
/// `setPassword` ujjlenyomatos aláírásával.
final class PasswordChange extends Equatable {
  /// Jelszócsere a [password]-re az aláírt [action]-nel.
  const PasswordChange({required this.password, required this.action});

  /// Az új jelszó.
  final String password;

  /// A `setPassword` aláírása (`target` = `-`).
  final SignedAction action;

  @override
  List<Object?> get props => [password, action];

  @override
  String toString() => 'PasswordChange(…)';
}
