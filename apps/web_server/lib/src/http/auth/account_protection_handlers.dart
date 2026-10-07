import 'package:web_server/src/http/auth/account_security_handler.dart';
import 'package:web_server/src/http/auth/fallback_login_handler.dart';
import 'package:web_server/src/http/auth/login_banner_handler.dart';

/// Az A2b-2 handlerei együtt (ADR 0051 Addendum 6): a tartalék belépés, a
/// beállításai és a szalag.
final class AccountProtectionHandlers {
  /// A handlerek csoportja.
  const AccountProtectionHandlers({
    required this.fallbackLogin,
    required this.accountSecurity,
    required this.banner,
  });

  /// A tartalék belépés a weben.
  final FallbackLoginHandler fallbackLogin;

  /// A jelszó és a kódok a telefonon.
  final AccountSecurityHandler accountSecurity;

  /// A szalag és a nyugtázás.
  final LoginBannerHandler banner;
}
