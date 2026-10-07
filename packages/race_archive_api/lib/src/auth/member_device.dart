import 'package:equatable/equatable.dart';

/// Egy tag aktív telefonja a legénység listájában (ADR 0051 Addendum 5
/// M7).
final class MemberDevice extends Equatable {
  /// Eszköz a megadott mezőkkel.
  const MemberDevice({
    required this.id,
    required this.name,
    required this.model,
    required this.createdAt,
    this.lastUsedAt,
  });

  /// Az eszköz azonosítója.
  final String id;

  /// A telefon neve.
  final String name;

  /// A telefon típusa.
  final String model;

  /// A regisztráció ideje (UTC).
  final DateTime createdAt;

  /// Az utolsó használat (UTC), ha volt.
  final DateTime? lastUsedAt;

  @override
  List<Object?> get props => [id, name, model, createdAt, lastUsedAt];
}
