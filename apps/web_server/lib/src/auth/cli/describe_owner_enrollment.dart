import 'package:web_server/src/auth/cli/budapest_minute.dart';
import 'package:web_server/src/auth/owner_enrollment.dart';

/// A `create_owner_enrollment` stderr-re írt sorai: mit regisztrál a kód,
/// meddig érvényes, és hogyan rajzolható ki (ADR 0051 D3).
///
/// A QR-szöveg maga a stdout-ra megy, így a parancs kimenete egyenesen a
/// `qrencode`-ba vezethető.
List<String> describeOwnerEnrollment(IssuedOwnerEnrollment enrollment) => [
  if (enrollment.isFirstOwner)
    'Új tulajdonos: ${enrollment.ownerName}.'
  else
    'A tulajdonos (${enrollment.ownerName}) új telefonja.',
  _validityLine(enrollment.expiresAt),
  'Kirajzolás a terminálban: … | qrencode -t ansiutf8',
];

/// Az [error] egy sorban.
String describeOwnerEnrollmentError(OwnerEnrollmentError error) =>
    switch (error) {
      InvalidEnrollmentOrigin() =>
        '--origin: kanonikus origó kell, pl. https://archivum.example.hu '
            '(https, útvonal nélkül; http csak localhost-ra).',
      InvalidOwnerName() => '--name: 1–40 karakter, vezérlőkarakter nélkül.',
      OwnerNameRequired() => 'Még nincs tulajdonos: a --name kötelező.',
      OwnerAlreadyExists(:final ownerName) =>
        'Már van tulajdonos ($ownerName); --name nélkül futtasd, a kód az '
            'ő új telefonját regisztrálja.',
    };

String _validityLine(DateTime expiresAt) =>
    'Érvényes eddig: ${budapestMinuteOf(expiresAt)} (budapesti idő), '
    'egyszer használható.';
