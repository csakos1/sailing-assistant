import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';
import 'package:web_server/src/auth/account_info_of.dart';
import 'package:web_server/src/auth/device_token_service.dart';
import 'package:web_server/src/auth_db/user_repository.dart';

/// A saját név átírása (ADR 0051 Addendum 1 H9, Addendum 5 M1, M9).
///
/// Mindenki, az `owner` is, csak a saját nevét írhatja át; a név már a
/// `normalizeDisplayName` szerint egységesítve érkezik.
class AccountNameService {
  /// Szolgáltatás a [users] fölött.
  AccountNameService({required UserRepository users}) : _users = users;

  final UserRepository _users;

  /// A [caller] fiókja új [name]-mel.
  Future<Result<AccountInfo, ApiError>> rename(
    DeviceCaller caller,
    String name,
  ) async {
    final user = await _users.rename(caller.user.id, name);
    // A fiókot közben eltávolították: a telefon a 18d-5 panelt mutatja.
    if (user == null) return const Err(DeviceRevoked());
    return Ok(accountInfoOf(user));
  }
}
