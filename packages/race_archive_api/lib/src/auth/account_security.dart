import 'package:equatable/equatable.dart';

/// Az `owner` tartalék belépésének állapota a 18l-hez (ADR 0051 Addendum 1
/// H9, Addendum 6 N4, Addendum 10 Z12).
final class AccountSecurity extends Equatable {
  /// Állapot a megadott mezőkkel.
  const AccountSecurity({
    required this.recoveryCodesLeft,
    this.passwordSetAt,
    this.recoveryCodesGeneratedAt,
  });

  /// Mikor állította be a jelszót (UTC); `null`, ha nincs jelszó.
  final DateTime? passwordSetAt;

  /// A még fel nem használt helyreállító kódok száma.
  final int recoveryCodesLeft;

  /// Mikor készült a mostani kódkészlet (UTC; Addendum 10 Z12); `null`, ha
  /// nincs kód, vagy egy régebbi szerver nem adja meg.
  final DateTime? recoveryCodesGeneratedAt;

  @override
  List<Object?> get props => [
    passwordSetAt,
    recoveryCodesLeft,
    recoveryCodesGeneratedAt,
  ];
}
