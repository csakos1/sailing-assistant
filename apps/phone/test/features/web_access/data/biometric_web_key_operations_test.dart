import 'package:biometric_signature/biometric_signature.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/features/web_access/data/biometric_web_key_operations.dart';
import 'package:phone/features/web_access/data/web_key_operations.dart';

void main() {
  group('keyOperationFailureOf', () {
    test('maps the plugin codes to what the app tells the user', () {
      // Act and assert
      final expected = {
        BiometricError.userCanceled: KeyOperationFailure.canceled,
        BiometricError.systemCanceled: KeyOperationFailure.canceled,
        BiometricError.keyNotFound: KeyOperationFailure.keyMissing,
        BiometricError.keyInvalidated: KeyOperationFailure.keyMissing,
        BiometricError.notEnrolled: KeyOperationFailure.unavailable,
        BiometricError.passcodeNotSet: KeyOperationFailure.unavailable,
        BiometricError.lockedOutPermanent: KeyOperationFailure.lockedOut,
        BiometricError.unknown: KeyOperationFailure.failed,
        null: KeyOperationFailure.failed,
      };
      for (final MapEntry(:key, :value) in expected.entries) {
        expect(keyOperationFailureOf(key), value, reason: '$key');
      }
    });
  });
}
