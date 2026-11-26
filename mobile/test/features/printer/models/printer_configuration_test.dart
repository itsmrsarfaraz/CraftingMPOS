import 'package:flutter_test/flutter_test.dart';
import 'package:crafting_mpos/features/printer/models/printer_configuration.dart';

void main() {
  group('PrinterPaperWidth', () {
    test('Returns correct millimeter values', () {
      expect(PrinterPaperWidth.mm58.millimeters, 58);
      expect(PrinterPaperWidth.mm80.millimeters, 80);
    });
  });

  group('PrinterConfiguration', () {
    test('Creates configuration with default values', () {
      final configuration = PrinterConfiguration(
        printerName: 'Thermal Printer',
        printerAddress: '00:11:22:33:44:55',
      );

      expect(configuration.printerName, 'Thermal Printer');
      expect(configuration.printerAddress, '00:11:22:33:44:55');
      expect(configuration.paperWidth, PrinterPaperWidth.mm58);
      expect(configuration.capabilityProfileName, 'default');
    });

    test('Trims input values', () {
      final configuration = PrinterConfiguration(
        printerName: ' Thermal Printer ',
        printerAddress: ' 00:11:22:33:44:55 ',
        capabilityProfileName: ' default ',
      );

      expect(configuration.printerName, 'Thermal Printer');
      expect(configuration.printerAddress, '00:11:22:33:44:55');
      expect(configuration.capabilityProfileName, 'default');
    });

    test('Supports 80mm paper and custom capability profile', () {
      final configuration = PrinterConfiguration(
        printerName: 'POS Printer',
        printerAddress: 'AA:BB:CC:DD:EE:FF',
        paperWidth: PrinterPaperWidth.mm80,
        capabilityProfileName: 'custom-printer',
      );

      expect(configuration.paperWidth, PrinterPaperWidth.mm80);
      expect(configuration.paperWidth.millimeters, 80);
      expect(configuration.capabilityProfileName, 'custom-printer');
    });

    test('Rejects empty printer name', () {
      expect(
        () => PrinterConfiguration(
          printerName: ' ',
          printerAddress: '00:11:22:33:44:55',
        ),
        throwsArgumentError,
      );
    });

    test('Rejects empty printer address', () {
      expect(
        () => PrinterConfiguration(
          printerName: 'Thermal Printer',
          printerAddress: ' ',
        ),
        throwsArgumentError,
      );
    });

    test('Rejects invalid Bluetooth MAC address formats', () {
      final invalidAddresses = [
        '00:11:22:33:44',
        '00:11:22:33:44:GG',
        '0011:2233:4455',
        '00-11-22-33-44-55',
        'not-a-mac-address',
      ];

      for (final address in invalidAddresses) {
        expect(
          () => PrinterConfiguration(
            printerName: 'Thermal Printer',
            printerAddress: address,
          ),
          throwsArgumentError,
          reason: 'Should reject invalid MAC address: $address',
        );
      }
    });

    test('Rejects empty capability profile name', () {
      expect(
        () => PrinterConfiguration(
          printerName: 'Thermal Printer',
          printerAddress: '00:11:22:33:44:55',
          capabilityProfileName: ' ',
        ),
        throwsArgumentError,
      );
    });
  });
}
