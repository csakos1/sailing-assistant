import 'package:test/test.dart';
import 'package:web_server/src/auth/user_agent_description.dart';

void main() {
  final cases = <String, UserAgentDescription>{
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36': (
      browser: 'Chrome',
      os: 'Windows',
    ),
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36 '
        'Edg/129.0.0.0': (
      browser: 'Edge',
      os: 'Windows',
    ),
    'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like '
        'Gecko) Chrome/129.0.0.0 Safari/537.36 OPR/114.0.0.0': (
      browser: 'Opera',
      os: 'Linux',
    ),
    'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:131.0) Gecko/20100101 '
        'Firefox/131.0': (
      browser: 'Firefox',
      os: 'Linux',
    ),
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 '
        '(KHTML, like Gecko) Version/18.0 Safari/605.1.15': (
      browser: 'Safari',
      os: 'macOS',
    ),
    'Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) '
        'AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/129.0.0.0 '
        'Mobile/15E148 Safari/604.1': (
      browser: 'Chrome',
      os: 'iOS',
    ),
    'Mozilla/5.0 (Linux; Android 15; Pixel 8) AppleWebKit/537.36 (KHTML, '
        'like Gecko) Chrome/129.0.0.0 Mobile Safari/537.36': (
      browser: 'Chrome',
      os: 'Android',
    ),
    'Mozilla/5.0 (X11; CrOS x86_64 14541.0.0) AppleWebKit/537.36 (KHTML, '
        'like Gecko) Chrome/129.0.0.0 Safari/537.36': (
      browser: 'Chrome',
      os: 'ChromeOS',
    ),
    'curl/8.10.1': (browser: null, os: null),
  };

  for (final MapEntry(key: userAgent, value: expected) in cases.entries) {
    test('describes ${expected.browser} on ${expected.os}', () {
      expect(describeUserAgent(userAgent), expected);
    });
  }

  test('describes a missing User-Agent as unknown', () {
    expect(describeUserAgent(null), (browser: null, os: null));
  });
}
