import 'package:race_archive_api/race_archive_api.dart';
import 'package:web_server/src/auth_db/auth_user.dart';

/// Az [user] fiók a drótra (`GET /api/auth/me`, a belépés válasza).
AccountInfo accountInfoOf(AuthUser user) =>
    AccountInfo(userId: user.id, name: user.name, role: user.role);
