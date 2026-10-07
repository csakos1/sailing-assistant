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
