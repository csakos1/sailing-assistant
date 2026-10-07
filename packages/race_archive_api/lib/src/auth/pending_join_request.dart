import 'package:equatable/equatable.dart';

/// Egy el nem döntött csatlakozási kérelem az `owner` listájában (ADR
/// 0051 D3, Addendum 5 M6).
final class PendingJoinRequest extends Equatable {
  /// Kérelem a megadott mezőkkel.
  const PendingJoinRequest({
    required this.id,
    required this.name,
    required this.deviceName,
    required this.model,
    required this.ip,
    required this.createdAt,
    required this.expiresAt,
    this.country,
    this.city,
  });

  /// A kérelem azonosítója.
  final String id;

  /// A csatlakozó által megadott név.
  final String name;

  /// A telefon neve.
  final String deviceName;

  /// A telefon típusa.
  final String model;

  /// A kérelem IP-címe.
  final String ip;

  /// Az ország a GeoIP-ből, ha ismert (A2b-2).
  final String? country;

  /// A város a GeoIP-ből, ha ismert (A2b-2).
  final String? city;

  /// A beküldés ideje (UTC).
  final DateTime createdAt;

  /// A lejárat (UTC).
  final DateTime expiresAt;

  @override
  List<Object?> get props => [
    id,
    name,
    deviceName,
    model,
    ip,
    country,
    city,
    createdAt,
    expiresAt,
  ];
}
