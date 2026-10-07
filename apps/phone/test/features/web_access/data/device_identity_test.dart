import 'package:flutter_test/flutter_test.dart';
import 'package:phone/features/web_access/data/device_identity.dart';

void main() {
  group('deviceIdentityOf', () {
    test('names the phone by its model and types it with the maker', () {
      // Act
      final identity = deviceIdentityOf(
        manufacturer: 'Google',
        model: 'Pixel 8',
      );

      // Assert
      expect(identity, (deviceName: 'Pixel 8', model: 'Google Pixel 8'));
    });

    test('does not repeat a maker the model already starts with', () {
      // Act
      final identity = deviceIdentityOf(
        manufacturer: 'samsung',
        model: 'Samsung Galaxy S24',
      );

      // Assert
      expect(identity.model, 'Samsung Galaxy S24');
    });

    test('falls back when the system gives nothing usable', () {
      // Act
      final identity = deviceIdentityOf(manufacturer: '', model: '  ');

      // Assert
      expect(identity, (
        deviceName: fallbackDeviceName,
        model: fallbackDeviceName,
      ));
    });

    test('a model longer than the server allows falls back', () {
      // Act
      final identity = deviceIdentityOf(
        manufacturer: 'Acme',
        model: 'X' * 41,
      );

      // Assert
      expect(identity.deviceName, fallbackDeviceName);
      expect(identity.model, fallbackDeviceName);
    });
  });
}
