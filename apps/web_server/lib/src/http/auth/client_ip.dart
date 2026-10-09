import 'dart:io';

import 'package:shelf/shelf.dart';

const String _connectionInfoKey = 'shelf.io.connection_info';

/// Az IP, ha a kapcsolat adatai nem ismertek (például egy tesztben).
const String unknownClientIp = 'unknown';

/// A kérő kliens IP-je (ADR 0051 D8, Addendum 3 K8).
///
/// A Caddy mögött minden kérés a loopbackről jön, a valódi cím az
/// `X-Forwarded-For` utolsó eleme (a Caddy azt fűzi hozzá; az előtte
/// állókat a kliens hamisíthatja). Más címről jövő kérésnél a fejlécet nem
/// vesszük figyelembe, és egy nem IP-cím értéket sem.
String clientIpOf(Request request) {
  final info = request.context[_connectionInfoKey];
  if (info is! HttpConnectionInfo) return unknownClientIp;
  final remote = info.remoteAddress;
  if (remote.isLoopback) {
    final forwarded = request.headers['x-forwarded-for'];
    final last = forwarded?.split(',').last.trim();
    final address = last == null ? null : InternetAddress.tryParse(last);
    if (address != null) return address.address;
  }
  return remote.address;
}
