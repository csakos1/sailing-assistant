import 'package:equatable/equatable.dart';
import 'package:race_archive_api/src/auth/suspicious_login.dart';

/// A telefon szalagja megnyitáskor (ADR 0051 D7, Addendum 1 H8, Addendum 6
/// N6).
final class LoginBanner extends Equatable {
  /// Szalag a gyanús belépésekkel és a függő kérelmek számával.
  const LoginBanner({
    required this.suspicious,
    required this.pendingJoinRequests,
  });

  /// A nyugtázatlan, 30 napnál nem régebbi gyanús belépések, a legújabb
  /// elöl.
  final List<SuspiciousLogin> suspicious;

  /// Az el nem döntött csatlakozási kérelmek száma (a `crew`-nál 0).
  final int pendingJoinRequests;

  @override
  List<Object?> get props => [suspicious, pendingJoinRequests];
}
