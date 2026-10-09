import 'package:race_archive_api/race_archive_api.dart';
import 'package:web_server/src/auth/account_info_of.dart';
import 'package:web_server/src/auth_db/auth_device.dart';
import 'package:web_server/src/auth_db/auth_user.dart';

/// Az [user] fiók a drótra az aktív [devices] eszközeivel (ADR 0051
/// Addendum 5 M7); a [devices]-ből csak az övéi számítanak.
MemberInfo memberInfoOf(AuthUser user, Iterable<AuthDevice> devices) =>
    MemberInfo(
      account: accountInfoOf(user),
      createdAt: user.createdAt,
      devices: [
        for (final device in devices)
          if (device.userId == user.id && !device.isRevoked)
            MemberDevice(
              id: device.id,
              name: device.name,
              model: device.model,
              createdAt: device.createdAt,
              lastUsedAt: device.lastUsedAt,
            ),
      ],
    );
