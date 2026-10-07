// A hitelesítés végpontjai (ADR 0051 Addendum 3 K6). Egy helyen, hogy a
// szerver routere, a web és az app kliense ne térhessen el egymástól.

/// Minden hitelesítési végpont közös előtagja; ezek a session-őr előtt
/// futnak.
const String authPathPrefix = '/api/auth/';

/// A telefon által küldött érték az `X-Foretack-Client` fejlécben.
const String clientHeaderPhoneValue = 'phone';

/// Új belépési kérés a weboldalról: `POST`.
const String loginRequestsPath = '/api/auth/login-requests';

/// A belépési kérés állapota a kötő-cookie-val: `POST` (a beváltás ír).
String loginRequestPollPath(String requestId) =>
    '${_loginRequestPath(requestId)}/poll';

/// A telefon megnyitja a beolvasott kérést: `POST`, eszköz-tokennel.
String loginRequestOpenPath(String requestId) =>
    '${_loginRequestPath(requestId)}/open';

/// A telefon jóváhagyja a kérést: `POST`, aláírással.
String loginRequestApprovalPath(String requestId) =>
    '${_loginRequestPath(requestId)}/approval';

/// Az `owner` telefonjának regisztrációja: `POST`.
const String enrollmentsPath = '/api/auth/enrollments';

/// Kihívás az eszköz-tokenhez: `POST`.
const String deviceChallengesPath = '/api/auth/device-challenges';

/// Eszköz-token az aláírt kihívásért: `POST`.
const String deviceTokensPath = '/api/auth/device-tokens';

/// A belépett fiók: `GET`, sessionnel vagy eszköz-tokennel.
const String mePath = '/api/auth/me';

/// Kijelentkezés a weben: `POST`.
const String logoutPath = '/api/auth/logout';

String _loginRequestPath(String requestId) =>
    '$loginRequestsPath/${Uri.encodeComponent(requestId)}';

/// Kihívás egy ujjlenyomatos művelethez (Addendum 5 M2): `POST`,
/// eszköz-tokennel.
const String actionChallengesPath = '/api/auth/action-challenges';

/// Csatlakozási kérelem (`POST`, a fiók nélküli app), illetve az el nem
/// döntött kérelmek listája (`GET`, az `owner` eszköz-tokenjével).
const String joinRequestsPath = '/api/auth/join-requests';

/// A kérelem állapota a lekérdező tokennel: `POST`.
String joinRequestStatusPath(String joinRequestId) =>
    '${_joinRequestPath(joinRequestId)}/status';

/// A kérelem jóváhagyása: `POST`, aláírással.
String joinRequestApprovalPath(String joinRequestId) =>
    '${_joinRequestPath(joinRequestId)}/approval';

/// A kérelem elutasítása: `POST`, eszköz-tokennel.
String joinRequestRejectionPath(String joinRequestId) =>
    '${_joinRequestPath(joinRequestId)}/rejection';

/// A fiókok és az aktív eszközeik: `GET`, az `owner` eszköz-tokenjével.
const String membersPath = '/api/auth/members';

/// Egy tag eltávolítása: `POST`, aláírással.
String memberRemovalPath(String userId) =>
    '$membersPath/${Uri.encodeComponent(userId)}/removal';

/// A regisztrált telefonok útvonal-előtagja.
const String devicesPath = '/api/auth/devices';

/// Egy eszköz visszavonása: `POST`, aláírással.
String deviceRevocationPath(String deviceId) =>
    '$devicesPath/${Uri.encodeComponent(deviceId)}/revocation';

/// A webes munkamenetek: `GET`, eszköz-tokennel.
const String sessionsPath = '/api/auth/sessions';

/// Egy munkamenet kiléptetése: `DELETE`, eszköz-tokennel.
String sessionPath(String sessionId) =>
    '$sessionsPath/${Uri.encodeComponent(sessionId)}';

/// A saját név átírása: `POST`, eszköz-tokennel.
const String accountNamePath = '/api/auth/account/name';

String _joinRequestPath(String joinRequestId) =>
    '$joinRequestsPath/${Uri.encodeComponent(joinRequestId)}';
