import 'dart:convert';
import 'dart:typed_data';

import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

const String _secretA = 'ICEiIyQlJicoKSorLC0uLzAxMjM0NTY3ODk6Ozw9Pj8';
const String _requestId = 'AAECAwQFBgcICQoLDA0ODw';
const AccountInfo _crew = AccountInfo(
  userId: 'u-dori',
  name: 'Dóri',
  role: UserRole.crew,
);

T _unwrap<T>(Result<T, DecodeError> result) => switch (result) {
  Ok(:final value) => value,
  Err(:final error) => throw StateError('Ok-t vartunk: $error'),
};

DecodeError _errorOf<T>(Result<T, DecodeError> result) => switch (result) {
  Ok(:final value) => throw StateError('Err-t vartunk: $value'),
  Err(:final error) => error,
};

Object? _overTheWire(Map<String, Object?> json) => jsonDecode(jsonEncode(json));

Map<String, Object?> _joinJson({String name = 'Dóri', String? challenge}) => {
  'requestId': _requestId,
  'challenge': challenge ?? _secretA,
  'name': name,
  'deviceName': 'Dóri Galaxy',
  'model': 'SM-S921B',
  'publicKey': 'MFkwEw==',
  'deviceKey': 'MFkwFA==',
  'signature': 'MEQCIA==',
};

void main() {
  group('round trips', () {
    test('keep the join request with its bytes', () {
      final request = JoinRequest(
        requestId: _requestId,
        challenge: _secretA,
        name: 'Dóri',
        deviceName: 'Dóri Galaxy',
        model: 'SM-S921B',
        publicKey: Uint8List.fromList([0x30, 0x59, 0x30, 0x13]),
        deviceKey: Uint8List.fromList([0x30, 0x59, 0x30, 0x14]),
        signature: Uint8List.fromList([0x30, 0x44, 0x02, 0x20]),
      );

      final decoded = _unwrap(
        decodeJoinRequest(_overTheWire(encodeJoinRequest(request))),
      );

      expect(decoded, request);
    });

    test('keep the ticket and the status query', () {
      final ticket = JoinTicket(
        joinRequestId: _requestId,
        statusToken: _secretA,
        expiresAt: DateTime.utc(2026, 10, 8, 9, 30, 15, 250),
      );

      expect(
        _unwrap(decodeJoinTicket(_overTheWire(encodeJoinTicket(ticket)))),
        ticket,
      );
      expect(
        _unwrap(
          decodeJoinStatusQuery(_overTheWire(encodeJoinStatusQuery(_secretA))),
        ),
        _secretA,
      );
    });

    test('keep every join status', () {
      const statuses = [
        JoinRequestStatus(state: JoinRequestState.pending),
        JoinRequestStatus(
          state: JoinRequestState.approved,
          account: _crew,
          deviceId: 'd-2',
        ),
        JoinRequestStatus(state: JoinRequestState.notApproved),
      ];

      for (final status in statuses) {
        final decoded = _unwrap(
          decodeJoinRequestStatus(
            _overTheWire(encodeJoinRequestStatus(status)),
          ),
        );
        expect(decoded, status);
      }
    });

    test('keep the pending requests in order', () {
      final requests = [
        PendingJoinRequest(
          id: 'j-2',
          name: 'Gergő',
          deviceName: 'Gergő telefonja',
          model: 'Pixel 7',
          ip: '2001:db8::7',
          createdAt: DateTime.utc(2026, 10, 7, 9),
          expiresAt: DateTime.utc(2026, 10, 8, 9),
        ),
        PendingJoinRequest(
          id: 'j-1',
          name: 'Dóri',
          deviceName: 'Dóri Galaxy',
          model: 'SM-S921B',
          ip: '203.0.113.7',
          country: 'HU',
          city: 'Budapest',
          createdAt: DateTime.utc(2026, 10, 7, 8),
          expiresAt: DateTime.utc(2026, 10, 8, 8),
        ),
      ];

      final decoded = _unwrap(
        decodePendingJoinRequests(
          _overTheWire(encodePendingJoinRequests(requests)),
        ),
      );

      expect(decoded, requests);
    });

    test('keep an approval for a new and for an existing member', () {
      final action = SignedAction(
        challenge: _secretA,
        signature: Uint8List.fromList([1, 2, 3]),
      );
      final approvals = [
        JoinApproval(action: action),
        JoinApproval(action: action, memberId: 'u-dori'),
      ];

      for (final approval in approvals) {
        final decoded = _unwrap(
          decodeJoinApproval(_overTheWire(encodeJoinApproval(approval))),
        );
        expect(decoded, approval);
      }
      expect(
        _unwrap(decodeSignedAction(_overTheWire(encodeSignedAction(action)))),
        action,
      );
    });

    test('keep the members with their devices', () {
      final members = [
        MemberInfo(
          account: _crew,
          createdAt: DateTime.utc(2026, 10, 1, 12),
          devices: [
            MemberDevice(
              id: 'd-2',
              name: 'Dóri Galaxy',
              model: 'SM-S921B',
              createdAt: DateTime.utc(2026, 10, 1, 12),
              lastUsedAt: DateTime.utc(2026, 10, 7, 8, 15),
            ),
            MemberDevice(
              id: 'd-3',
              name: 'Dóri tablet',
              model: 'SM-X710',
              createdAt: DateTime.utc(2026, 10, 2, 12),
            ),
          ],
        ),
      ];

      final decoded = _unwrap(
        decodeMembers(_overTheWire(encodeMembers(members))),
      );

      expect(decoded, members);
      expect(
        _unwrap(decodeMemberInfo(_overTheWire(encodeMemberInfo(members[0])))),
        members[0],
      );
    });

    test('keep the sessions with unknown fields', () {
      final sessions = [
        WebSession(
          id: 's-1',
          userId: 'u-dori',
          userName: 'Dóri',
          method: LoginMethod.qr,
          ip: '203.0.113.7',
          browser: 'Firefox',
          os: 'Linux',
          createdAt: DateTime.utc(2026, 10, 7, 8),
          lastSeenAt: DateTime.utc(2026, 10, 7, 9),
        ),
      ];

      final decoded = _unwrap(
        decodeWebSessions(_overTheWire(encodeWebSessions(sessions))),
      );

      expect(decoded, sessions);
    });
  });

  group('decoding', () {
    test('trims the names like the display name rule', () {
      final request = _unwrap(decodeJoinRequest(_joinJson(name: '  Dóri  ')));
      final name = _unwrap(decodeDisplayNameChange({'name': ' Bence '}));

      expect(request.name, 'Dóri');
      expect(name, 'Bence');
    });

    test('rejects a name that would add a line to the signed message', () {
      final error = _errorOf(decodeJoinRequest(_joinJson(name: 'Dóri\nÁkos')));

      expect(
        error,
        const DecodeError(path: r'$.name', expected: 'display name'),
      );
    });

    test('rejects a short challenge in the join request', () {
      final error = _errorOf(
        decodeJoinRequest(_joinJson(challenge: _requestId)),
      );

      expect(error.path, r'$.challenge');
    });

    test('rejects an account or device on a status that is not approved', () {
      final withAccount = _errorOf(
        decodeJoinRequestStatus({
          'state': 'pending',
          'account': encodeAccountInfo(_crew),
          'deviceId': null,
        }),
      );
      final withDevice = _errorOf(
        decodeJoinRequestStatus({
          'state': 'notApproved',
          'account': null,
          'deviceId': 'd-2',
        }),
      );

      expect(withAccount.path, r'$.account');
      expect(withDevice.path, r'$.deviceId');
    });

    test('rejects an approved status without a device', () {
      final error = _errorOf(
        decodeJoinRequestStatus({
          'state': 'approved',
          'account': encodeAccountInfo(_crew),
          'deviceId': null,
        }),
      );

      expect(error.path, r'$.deviceId');
    });

    test('rejects an empty member id in the approval', () {
      final error = _errorOf(
        decodeJoinApproval({
          'memberId': '',
          'challenge': _secretA,
          'signature': 'AQID',
        }),
      );

      expect(error.path, r'$.memberId');
    });
  });

  test('builds the approval target for a new and an existing member', () {
    expect(
      joinApprovalTarget(joinRequestId: 'j-1', memberId: null),
      'j-1:new',
    );
    expect(
      joinApprovalTarget(joinRequestId: 'j-1', memberId: 'u-dori'),
      'j-1:u-dori',
    );
  });

  test('builds the paths with encoded identifiers', () {
    expect(
      joinRequestStatusPath('a/b'),
      '/api/auth/join-requests/a%2Fb/status',
    );
    expect(joinRequestApprovalPath('j'), '/api/auth/join-requests/j/approval');
    expect(
      joinRequestRejectionPath('j'),
      '/api/auth/join-requests/j/rejection',
    );
    expect(memberRemovalPath('u'), '/api/auth/members/u/removal');
    expect(deviceRevocationPath('d'), '/api/auth/devices/d/revocation');
    expect(sessionPath('s'), '/api/auth/sessions/s');
  });

  test('keeps the challenge out of the string forms', () {
    final request = _unwrap(decodeJoinRequest(_joinJson()));
    final ticket = _unwrap(
      decodeJoinTicket({
        'joinRequestId': _requestId,
        'statusToken': _secretA,
        'expiresAt': 0,
      }),
    );

    expect(request.toString(), isNot(contains(_secretA)));
    expect(ticket.toString(), isNot(contains(_secretA)));
  });
}
