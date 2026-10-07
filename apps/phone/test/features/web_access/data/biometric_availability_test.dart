import 'dart:typed_data';

import 'package:biometric_signature/biometric_signature.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/features/web_access/data/biometric_web_key_operations.dart';
import 'package:phone/features/web_access/data/web_key_operations.dart';
import 'package:shared/shared.dart';

// A plugin helyett egy alosztaly: a Keystore-t nem eri el.
class _FakePlugin extends BiometricSignature {
  _FakePlugin({required this.hasFingerprint});

  final bool hasFingerprint;
  int createdKeys = 0;

  @override
  Future<BiometricAvailability> biometricAuthAvailable() async =>
      BiometricAvailability(
        canAuthenticate: hasFingerprint,
        hasEnrolledBiometrics: hasFingerprint,
      );

  @override
  Future<KeyCreationResult> createKeys({
    String? keyAlias,
    CreateKeysConfig? config,
    KeyFormat keyFormat = KeyFormat.base64,
    String? promptMessage,
  }) async {
    createdKeys++;
    return KeyCreationResult(publicKeyBytes: Uint8List.fromList([1]));
  }
}

void main() {
  test('a phone without fingerprints cannot create the signing key', () async {
    // Arrange
    final plugin = _FakePlugin(hasFingerprint: false);

    // Act
    final result = await biometricWebKeyOperations(
      plugin,
    ).createKey(WebKeyRole.signing);

    // Assert
    expect(
      result,
      const Err<Uint8List, KeyOperationFailure>(
        KeyOperationFailure.unavailable,
      ),
    );
    expect(plugin.createdKeys, 0);
  });

  test('the silent device key needs no fingerprint', () async {
    // Arrange
    final plugin = _FakePlugin(hasFingerprint: false);

    // Act
    final result = await biometricWebKeyOperations(
      plugin,
    ).createKey(WebKeyRole.device);

    // Assert
    expect(result, isA<Ok<Uint8List, KeyOperationFailure>>());
    expect(plugin.createdKeys, 1);
  });
}
