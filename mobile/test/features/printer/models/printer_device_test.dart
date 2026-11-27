
import 'package:flutter_test/flutter_test.dart';
import 'package:crafting_mpos/features/printer/models/printer_device.dart';

void main() {
  group('PrinterDevice', () {
    test('Creates a printer device with valid values', () {
      final device = PrinterDevice(
        name: 'Thermal Printer',
        address: '00:11:22:33:44:55',
      );

      expect(device.name, 'Thermal Printer');
      expect(device.address, '00:11:22:33:44:55');
    });

    test('Trims the printer name and address', () {
      final device = PrinterDevice(
        name: ' Thermal Printer ',
        address: ' 00:11:22:33:44:55 ',
      );

      expect(device.name, 'Thermal Printer');
      expect(device.address, '00:11:22:33:44:55');
    });

    test('Normalizes lowercase MAC address to uppercase', () {
      final device = PrinterDevice(
        name: 'Thermal Printer',
        address: 'aa:bb:cc:dd:ee:ff',
      );

      expect(device.address, 'AA:BB:CC:DD:EE:FF');
    });

    test('Rejects an empty printer name', () {
      expect(
        () => PrinterDevice(
          name: ' ',
          address: '00:11:22:33:44:55',
        ),
        throwsArgumentError,
      );
    });

    test('Rejects an invalid Bluetooth MAC address', () {
      final invalidAddresses = [
        '',
        '00:11:22:33:44',
        '00:11:22:33:44:GG',
        '0011:2233:4455',
        '00-11-22-33-44-55',
        'not-a-mac-address',
      ];

      for (final address in invalidAddresses) {
        expect(
          () => PrinterDevice(
            name: 'Thermal Printer',
            address: address,
          ),
          throwsArgumentError,
          reason: 'Should reject invalid address: $address',
        );
      }
    });
  });
}
