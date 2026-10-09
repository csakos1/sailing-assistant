import 'dart:convert';

import 'package:race_archive_api/src/auth/account_info.dart';
import 'package:race_archive_api/src/auth/auth_codecs.dart';
import 'package:race_archive_api/src/auth/auth_json_fields.dart';
import 'package:race_archive_api/src/auth/join_approval.dart';
import 'package:race_archive_api/src/auth/join_request.dart';
import 'package:race_archive_api/src/auth/join_request_status.dart';
import 'package:race_archive_api/src/auth/join_ticket.dart';
import 'package:race_archive_api/src/auth/login_method.dart';
import 'package:race_archive_api/src/auth/member_device.dart';
import 'package:race_archive_api/src/auth/member_info.dart';
import 'package:race_archive_api/src/auth/pending_join_request.dart';
import 'package:race_archive_api/src/auth/qr_payload.dart';
import 'package:race_archive_api/src/auth/signed_action.dart';
import 'package:race_archive_api/src/auth/web_session.dart';
import 'package:race_archive_api/src/json/decode_error.dart';
import 'package:race_archive_api/src/json/json_reader.dart';
import 'package:shared/shared.dart';

// A csatlakozás, a legénység és a munkamenetek kodekjei (ADR 0051
// Addendum 5 M11). A dróton ugyanaz a szabály, mint az `auth_codecs`-ban:
// bájtok szabványos base64-ben, titkok base64url-ben hossz-ellenőrzéssel,
// időpontok UTC epoch ms-ben.

/// [JoinRequest] → JSON (`POST /api/auth/join-requests`).
Map<String, Object?> encodeJoinRequest(JoinRequest request) =>
    <String, Object?>{
      'requestId': request.requestId,
      'challenge': request.challenge,
      'name': request.name,
      'deviceName': request.deviceName,
      'model': request.model,
      'publicKey': base64Encode(request.publicKey),
      'deviceKey': base64Encode(request.deviceKey),
      'signature': base64Encode(request.signature),
    };

/// JSON → [JoinRequest]; a nevek a `normalizeDisplayName` szerint.
Result<JoinRequest, DecodeError> decodeJoinRequest(Object? json) =>
    runDecode(() {
      final reader = JsonReader.root(json);
      return JoinRequest(
        requestId: readSecret(reader, 'requestId', loginRequestIdLength),
        challenge: readSecret(reader, 'challenge', secretTokenLength),
        name: readDisplayName(reader, 'name'),
        deviceName: readDisplayName(reader, 'deviceName'),
        model: readDisplayName(reader, 'model'),
        publicKey: readBytes(reader, 'publicKey'),
        deviceKey: readBytes(reader, 'deviceKey'),
        signature: readBytes(reader, 'signature'),
      );
    });

/// [JoinTicket] → JSON.
Map<String, Object?> encodeJoinTicket(JoinTicket ticket) => <String, Object?>{
  'joinRequestId': ticket.joinRequestId,
  'statusToken': ticket.statusToken,
  'expiresAt': ticket.expiresAt.millisecondsSinceEpoch,
};

/// JSON → [JoinTicket].
Result<JoinTicket, DecodeError> decodeJoinTicket(Object? json) => runDecode(() {
  final reader = JsonReader.root(json);
  return JoinTicket(
    joinRequestId: readSecret(reader, 'joinRequestId', joinRequestIdLength),
    statusToken: readSecret(reader, 'statusToken', secretTokenLength),
    expiresAt: reader.utcMillis('expiresAt'),
  );
});

/// A kérelem lekérdezése (`POST …/status`): `{statusToken}`.
Map<String, Object?> encodeJoinStatusQuery(String statusToken) =>
    <String, Object?>{'statusToken': statusToken};

/// JSON → a lekérdező token.
Result<String, DecodeError> decodeJoinStatusQuery(Object? json) => runDecode(
  () => readSecret(JsonReader.root(json), 'statusToken', secretTokenLength),
);

/// [JoinRequestStatus] → JSON.
Map<String, Object?> encodeJoinRequestStatus(JoinRequestStatus status) =>
    <String, Object?>{
      'state': status.state.name,
      'account': switch (status.account) {
        null => null,
        final AccountInfo account => encodeAccountInfo(account),
      },
      'deviceId': status.deviceId,
    };

/// JSON → [JoinRequestStatus].
///
/// A fiók és az eszköz pontosan az `approved` állapotnál van jelen.
Result<JoinRequestStatus, DecodeError> decodeJoinRequestStatus(
  Object? json,
) => runDecode(() {
  final reader = JsonReader.root(json);
  final state = reader.enumByName('state', JoinRequestState.values);
  final accountReader = reader.optionalObject('account');
  final deviceId = reader.optionalString('deviceId');
  final isApproved = state == JoinRequestState.approved;
  if (isApproved != (accountReader != null)) {
    JsonReader.failAt(
      reader.childPath('account'),
      'account exactly when approved',
    );
  }
  if (isApproved != (deviceId != null) ||
      (deviceId != null && deviceId.isEmpty)) {
    JsonReader.failAt(
      reader.childPath('deviceId'),
      'device id exactly when approved',
    );
  }
  return JoinRequestStatus(
    state: state,
    account: accountReader == null ? null : readAccountInfo(accountReader),
    deviceId: deviceId,
  );
});

/// Az el nem döntött kérelmek → JSON (`GET /api/auth/join-requests`).
Map<String, Object?> encodePendingJoinRequests(
  List<PendingJoinRequest> requests,
) => <String, Object?>{
  'joinRequests': [for (final request in requests) _pendingJson(request)],
};

/// JSON → az el nem döntött kérelmek.
Result<List<PendingJoinRequest>, DecodeError> decodePendingJoinRequests(
  Object? json,
) => runDecode(
  () =>
      JsonReader.root(
        json,
      ).list(
        'joinRequests',
        (item, path) => _readPending(JsonReader.at(item, path)),
      ),
);

/// [SignedAction] → JSON (eltávolítás, visszavonás).
Map<String, Object?> encodeSignedAction(SignedAction action) =>
    <String, Object?>{
      'challenge': action.challenge,
      'signature': base64Encode(action.signature),
    };

/// JSON → [SignedAction].
Result<SignedAction, DecodeError> decodeSignedAction(Object? json) =>
    runDecode(() => readSignedAction(JsonReader.root(json)));

/// [JoinApproval] → JSON (`POST …/approval`).
Map<String, Object?> encodeJoinApproval(JoinApproval approval) =>
    <String, Object?>{
      'memberId': approval.memberId,
      ...encodeSignedAction(approval.action),
    };

/// JSON → [JoinApproval]; a hiányzó vagy `null` `memberId` új tagot jelent.
Result<JoinApproval, DecodeError> decodeJoinApproval(Object? json) =>
    runDecode(() {
      final reader = JsonReader.root(json);
      final hasMember = reader.optionalString('memberId') != null;
      return JoinApproval(
        memberId: hasMember ? reader.nonEmptyString('memberId') : null,
        action: readSignedAction(reader),
      );
    });

/// [MemberInfo] → JSON (a jóváhagyás válasza).
Map<String, Object?> encodeMemberInfo(MemberInfo member) => <String, Object?>{
  'account': encodeAccountInfo(member.account),
  'createdAt': member.createdAt.millisecondsSinceEpoch,
  'devices': [for (final device in member.devices) _deviceJson(device)],
};

/// JSON → [MemberInfo].
Result<MemberInfo, DecodeError> decodeMemberInfo(Object? json) =>
    runDecode(() => _readMember(JsonReader.root(json)));

/// A fiókok → JSON (`GET /api/auth/members`).
Map<String, Object?> encodeMembers(List<MemberInfo> members) =>
    <String, Object?>{
      'members': [for (final member in members) encodeMemberInfo(member)],
    };

/// JSON → a fiókok.
Result<List<MemberInfo>, DecodeError> decodeMembers(Object? json) => runDecode(
  () => JsonReader.root(
    json,
  ).list('members', (item, path) => _readMember(JsonReader.at(item, path))),
);

/// A munkamenetek → JSON (`GET /api/auth/sessions`).
Map<String, Object?> encodeWebSessions(List<WebSession> sessions) =>
    <String, Object?>{
      'sessions': [for (final session in sessions) _sessionJson(session)],
    };

/// JSON → a munkamenetek.
Result<List<WebSession>, DecodeError> decodeWebSessions(Object? json) =>
    runDecode(
      () => JsonReader.root(json).list(
        'sessions',
        (item, path) => _readSession(JsonReader.at(item, path)),
      ),
    );

/// A saját név átírása (`POST /api/auth/account/name`): `{name}`.
Map<String, Object?> encodeDisplayNameChange(String name) => <String, Object?>{
  'name': name,
};

/// JSON → az új név a `normalizeDisplayName` szerint.
Result<String, DecodeError> decodeDisplayNameChange(Object? json) =>
    runDecode(() => readDisplayName(JsonReader.root(json), 'name'));

Map<String, Object?> _pendingJson(PendingJoinRequest request) =>
    <String, Object?>{
      'id': request.id,
      'name': request.name,
      'deviceName': request.deviceName,
      'model': request.model,
      'ip': request.ip,
      'country': request.country,
      'city': request.city,
      'createdAt': request.createdAt.millisecondsSinceEpoch,
      'expiresAt': request.expiresAt.millisecondsSinceEpoch,
    };

PendingJoinRequest _readPending(JsonReader reader) => PendingJoinRequest(
  id: reader.nonEmptyString('id'),
  name: reader.nonEmptyString('name'),
  deviceName: reader.nonEmptyString('deviceName'),
  model: reader.nonEmptyString('model'),
  ip: reader.nonEmptyString('ip'),
  country: reader.optionalString('country'),
  city: reader.optionalString('city'),
  createdAt: reader.utcMillis('createdAt'),
  expiresAt: reader.utcMillis('expiresAt'),
);

Map<String, Object?> _deviceJson(MemberDevice device) => <String, Object?>{
  'id': device.id,
  'name': device.name,
  'model': device.model,
  'createdAt': device.createdAt.millisecondsSinceEpoch,
  'lastUsedAt': device.lastUsedAt?.millisecondsSinceEpoch,
};

MemberDevice _readDevice(JsonReader reader) => MemberDevice(
  id: reader.nonEmptyString('id'),
  name: reader.nonEmptyString('name'),
  model: reader.nonEmptyString('model'),
  createdAt: reader.utcMillis('createdAt'),
  lastUsedAt: reader.optionalUtcMillis('lastUsedAt'),
);

MemberInfo _readMember(JsonReader reader) => MemberInfo(
  account: readAccountInfo(reader.object('account')),
  createdAt: reader.utcMillis('createdAt'),
  devices: reader.list(
    'devices',
    (item, path) => _readDevice(JsonReader.at(item, path)),
  ),
);

Map<String, Object?> _sessionJson(WebSession session) => <String, Object?>{
  'id': session.id,
  'userId': session.userId,
  'userName': session.userName,
  'method': session.method.name,
  'ip': session.ip,
  'browser': session.browser,
  'os': session.os,
  'country': session.country,
  'city': session.city,
  'createdAt': session.createdAt.millisecondsSinceEpoch,
  'lastSeenAt': session.lastSeenAt.millisecondsSinceEpoch,
  'isSuspicious': session.isSuspicious,
};

WebSession _readSession(JsonReader reader) => WebSession(
  id: reader.nonEmptyString('id'),
  userId: reader.nonEmptyString('userId'),
  userName: reader.nonEmptyString('userName'),
  method: reader.enumByName('method', LoginMethod.values),
  ip: reader.nonEmptyString('ip'),
  browser: reader.optionalString('browser'),
  os: reader.optionalString('os'),
  country: reader.optionalString('country'),
  city: reader.optionalString('city'),
  createdAt: reader.utcMillis('createdAt'),
  lastSeenAt: reader.utcMillis('lastSeenAt'),
  isSuspicious: reader.optionalBoolean('isSuspicious', fallback: false),
);
