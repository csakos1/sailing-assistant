import 'package:web_server/src/http/auth/account_name_handler.dart';
import 'package:web_server/src/http/auth/action_challenge_handler.dart';
import 'package:web_server/src/http/auth/join_decision_handler.dart';
import 'package:web_server/src/http/auth/join_request_handler.dart';
import 'package:web_server/src/http/auth/member_handler.dart';
import 'package:web_server/src/http/auth/session_list_handler.dart';

/// Az A2b-1 handlerei együtt (ADR 0051 Addendum 5): a router így egy
/// paramétert kap, nem hatot.
final class AccessManagementHandlers {
  /// A handlerek csoportja.
  const AccessManagementHandlers({
    required this.actionChallenges,
    required this.joinRequests,
    required this.joinDecisions,
    required this.members,
    required this.sessions,
    required this.accountName,
  });

  /// Az ujjlenyomatos műveletek kihívása.
  final ActionChallengeHandler actionChallenges;

  /// A csatlakozási kérelem és az állapota.
  final JoinRequestHandler joinRequests;

  /// Az `owner` döntései a kérelmekről.
  final JoinDecisionHandler joinDecisions;

  /// A tagok és az eszközeik.
  final MemberHandler members;

  /// A webes munkamenetek.
  final SessionListHandler sessions;

  /// A saját név átírása.
  final AccountNameHandler accountName;
}
