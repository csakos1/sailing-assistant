import 'dart:io';
import 'dart:typed_data';

/// Egy IP-cím a GeoIP-kereséshez: a család (4 vagy 6) és a big-endian
/// bájtjai (4 vagy 16).
typedef IpAddressBytes = ({int family, Uint8List bytes});

/// A [text] cím bájtjai, vagy `null`, ha nem IP-cím (pl. `unknown`).
///
/// [unwrapIpv4Mapped]-dal az IPv4-be ágyazott IPv6 címet
/// (`::ffff:a.b.c.d`) IPv4-ként adja: kereséskor így egy kétvermű szerver
/// mögött is az IPv4-es tartomány talál. A CSV olvasásakor nem bontjuk ki,
/// hogy az IPv6-os tartományok a helyükön maradjanak.
IpAddressBytes? ipAddressBytesOf(String text, {bool unwrapIpv4Mapped = false}) {
  final address = InternetAddress.tryParse(text);
  if (address == null) return null;
  final raw = address.rawAddress;
  if (address.type == InternetAddressType.IPv4) {
    return (family: 4, bytes: Uint8List.fromList(raw));
  }
  if (unwrapIpv4Mapped && _isIpv4Mapped(raw)) {
    return (family: 4, bytes: Uint8List.fromList(raw.sublist(12)));
  }
  return (family: 6, bytes: Uint8List.fromList(raw));
}

/// Nyilvános-e a cím: a loopback, a link-local, a privát (RFC 1918, ULA),
/// a meghatározatlan és a multicast cím nem az, ezekre nincs hely
/// (Addendum 6 N9).
bool isPublicAddress(IpAddressBytes address) {
  final bytes = address.bytes;
  if (address.family == 4) {
    final first = bytes[0];
    final second = bytes[1];
    return !(first == 0 ||
        first == 10 ||
        first == 127 ||
        first >= 224 ||
        (first == 169 && second == 254) ||
        (first == 172 && second >= 16 && second <= 31) ||
        (first == 192 && second == 168) ||
        (first == 100 && second >= 64 && second <= 127));
  }
  final isUnspecifiedOrLoopback =
      bytes.take(15).every((byte) => byte == 0) && bytes[15] <= 1;
  return !(isUnspecifiedOrLoopback ||
      (bytes[0] & 0xFE) == 0xFC ||
      (bytes[0] == 0xFE && (bytes[1] & 0xC0) == 0x80) ||
      bytes[0] == 0xFF);
}

/// Bájtonkénti (big-endian) összevetés két azonos hosszú címre: negatív,
/// nulla vagy pozitív, mint a `compareTo`.
int compareAddressBytes(Uint8List a, Uint8List b) {
  for (var i = 0; i < a.length && i < b.length; i++) {
    if (a[i] != b[i]) return a[i] - b[i];
  }
  return a.length - b.length;
}

bool _isIpv4Mapped(List<int> raw) {
  for (var i = 0; i < 10; i++) {
    if (raw[i] != 0) return false;
  }
  return raw[10] == 0xFF && raw[11] == 0xFF;
}
