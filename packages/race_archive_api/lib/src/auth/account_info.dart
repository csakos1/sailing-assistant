import 'package:equatable/equatable.dart';
import 'package:race_archive_api/src/auth/user_role.dart';

/// A belépett fiók (ADR 0051 D2): a web és az app ebből tudja, mit
/// mutasson. A biztonság a szerveren van, nem ezen.
final class AccountInfo extends Equatable {
  /// Fiók a megadott mezőkkel.
  const AccountInfo({
    required this.userId,
    required this.name,
    required this.role,
  });

  /// A fiók azonosítója.
  final String userId;

  /// A megjelenítendő név.
  final String name;

  /// A szerep.
  final UserRole role;

  @override
  List<Object?> get props => [userId, name, role];
}
