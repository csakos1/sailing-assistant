import 'package:shelf/shelf.dart';
import 'package:web_server/src/auth/user_agent_description.dart';
import 'package:web_server/src/auth_db/session_repository.dart';
import 'package:web_server/src/http/auth/client_ip.dart';

/// A kérő böngésző IP-je, böngészője és OS-e (ADR 0051 D7).
SessionOrigin browserOriginOf(Request request) {
  final (:browser, :os) = describeUserAgent(request.headers['user-agent']);
  return (ip: clientIpOf(request), browser: browser, os: os);
}
