import 'package:equatable/equatable.dart';

/// Az újragenerált helyreállító kódok (ADR 0051 Addendum 6 N4); csak ez az
/// egy válasz mutatja őket (18l-3).
final class IssuedRecoveryCodes extends Equatable {
  /// A [codes] kódok.
  const IssuedRecoveryCodes(this.codes);

  /// A 10 kód `XXXXX-XXXXX` alakban.
  final List<String> codes;

  @override
  List<Object?> get props => [codes];

  @override
  String toString() => 'IssuedRecoveryCodes(${codes.length})';
}
