import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// A [token] SHA-256 hash-e, ahogy az `auth.sqlite` tárolja (ADR 0051
/// D3, D5).
///
/// A token maga sosem kerül a DB-be: egy kiszivárgott DB-ből így nem
/// lehet belépni. A keresés a hash-re történik; ennek ideje legfeljebb a
/// hash egy részét árulhatná el, a tokent nem.
Uint8List digestToken(String token) =>
    Uint8List.fromList(sha256.convert(utf8.encode(token)).bytes);
