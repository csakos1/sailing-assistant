import 'package:test/test.dart';
import 'package:web_server/src/geoip/ip_address_bytes.dart';

bool _isPublic(String ip) {
  final address = ipAddressBytesOf(ip, unwrapIpv4Mapped: true);
  if (address == null) throw StateError('IP-cimet vartunk: $ip');
  return isPublicAddress(address);
}

void main() {
  test('reads IPv4, IPv6 and unwraps an IPv4-mapped address on request', () {
    expect(ipAddressBytesOf('203.0.113.7')?.family, 4);
    expect(ipAddressBytesOf('2001:db8::7')?.bytes, hasLength(16));
    expect(ipAddressBytesOf('::ffff:203.0.113.7')?.family, 6);
    expect(
      ipAddressBytesOf('::ffff:203.0.113.7', unwrapIpv4Mapped: true)?.bytes,
      [203, 0, 113, 7],
    );
    expect(ipAddressBytesOf('unknown'), isNull);
  });

  test('tells public addresses from private and local ones', () {
    for (final ip in ['203.0.113.7', '1.1.1.1', '2a01:4f8::1']) {
      expect(_isPublic(ip), isTrue, reason: ip);
    }
    for (final ip in [
      '127.0.0.1',
      '10.1.2.3',
      '172.16.0.1',
      '172.31.255.255',
      '192.168.1.1',
      '169.254.1.1',
      '100.64.0.1',
      '0.0.0.0',
      '224.0.0.1',
      '::1',
      '::',
      'fd00::1',
      'fe80::1',
      'ff02::1',
      '::ffff:192.168.1.1',
    ]) {
      expect(_isPublic(ip), isFalse, reason: ip);
    }
  });

  test('orders addresses bytewise', () {
    final low = ipAddressBytesOf('1.0.0.255')?.bytes;
    final high = ipAddressBytesOf('1.0.1.0')?.bytes;
    if (low == null || high == null) throw StateError('IP-cimet vartunk');

    expect(compareAddressBytes(low, high), isNegative);
    expect(compareAddressBytes(high, low), isPositive);
    expect(compareAddressBytes(low, low), isZero);
  });
}
