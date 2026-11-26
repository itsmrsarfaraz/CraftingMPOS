import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crafting_mpos/features/printer/models/printer_configuration.dart';
import 'package:crafting_mpos/features/printer/services/esc_pos_builder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CapabilityProfile profile;

  setUpAll(() async {
    profile = await CapabilityProfile.load();
  });

  group('EscPosBuilder', () {
    test('Uses 58mm paper configuration', () {
      final configuration = PrinterConfiguration(
        printerName: 'Thermal Printer',
        printerAddress: '00:11:22:33:44:55',
      );

      final builder = EscPosBuilder(
        configuration: configuration,
        capabilityProfile: profile,
      );

      expect(builder.paperSize, PaperSize.mm58);
    });

    test('Uses 80mm paper configuration', () {
      final configuration = PrinterConfiguration(
        printerName: 'Thermal Printer',
        printerAddress: '00:11:22:33:44:55',
        paperWidth: PrinterPaperWidth.mm80,
      );

      final builder = EscPosBuilder(
        configuration: configuration,
        capabilityProfile: profile,
      );

      expect(builder.paperSize, PaperSize.mm80);
    });

    test('Creates independent generators', () {
      final configuration = PrinterConfiguration(
        printerName: 'Thermal Printer',
        printerAddress: '00:11:22:33:44:55',
      );

      final builder = EscPosBuilder(
        configuration: configuration,
        capabilityProfile: profile,
      );

      final first = builder.createGenerator();
      final second = builder.createGenerator();

      expect(first, isNot(same(second)));
    });

    test('Generates printer initialization commands', () {
      final configuration = PrinterConfiguration(
        printerName: 'Thermal Printer',
        printerAddress: '00:11:22:33:44:55',
      );

      final builder = EscPosBuilder(
        configuration: configuration,
        capabilityProfile: profile,
      );

      final generator = builder.createGenerator();
      final commands = builder.initialize(generator);

      expect(commands, isNotEmpty);
      expect(commands, contains(0x1B));
    });

    group('buildText', () {
      late EscPosBuilder builder;
      late Generator generator;

      setUp(() {
        final configuration = PrinterConfiguration(
          printerName: 'Thermal Printer',
          printerAddress: '00:11:22:33:44:55',
        );

        builder = EscPosBuilder(
          configuration: configuration,
          capabilityProfile: profile,
        );

        generator = builder.createGenerator();
      });

      group('buildBarcode', () {
        late EscPosBuilder builder;
        late Generator generator;

        setUp(() {
          final configuration = PrinterConfiguration(
            printerName: 'Thermal Printer',
            printerAddress: '00:11:22:33:44:55',
          );

          builder = EscPosBuilder(
            configuration: configuration,
            capabilityProfile: profile,
          );

          generator = builder.createGenerator();
        });

        test('Generates a CODE128 barcode', () {
          final commands = builder.buildBarcode(generator, '8901234567890');

          expect(commands, isNotEmpty);
        });

        test('Generates a barcode without human-readable text', () {
          final commands = builder.buildBarcode(
            generator,
            'PRODUCT-001',
            showText: false,
          );

          expect(commands, isNotEmpty);
        });

        test('Supports custom barcode dimensions and alignment', () {
          final commands = builder.buildBarcode(
            generator,
            'SKU-12345',
            alignment: PosAlign.left,
            height: 120,
            width: 4,
          );

          expect(commands, isNotEmpty);
        });

        test('Rejects empty barcode data', () {
          expect(
            () => builder.buildBarcode(generator, ' '),
            throwsArgumentError,
          );
        });

        test('Rejects non-ASCII barcode data', () {
          expect(
            () => builder.buildBarcode(generator, 'PRODUCT-شامپو'),
            throwsArgumentError,
          );
        });

        test('Rejects invalid barcode height', () {
          expect(
            () => builder.buildBarcode(generator, 'PRODUCT-001', height: 256),
            throwsArgumentError,
          );
        });

        test('Rejects invalid barcode width', () {
          expect(
            () => builder.buildBarcode(generator, 'PRODUCT-001', width: 7),
            throwsArgumentError,
          );
        });
      });

      group('buildQrCode', () {
        late EscPosBuilder builder;
        late Generator generator;

        setUp(() {
          final configuration = PrinterConfiguration(
            printerName: 'Thermal Printer',
            printerAddress: '00:11:22:33:44:55',
          );

          builder = EscPosBuilder(
            configuration: configuration,
            capabilityProfile: profile,
          );

          generator = builder.createGenerator();
        });

        test('Generates a QR code', () {
          final commands = builder.buildQrCode(
            generator,
            'https://craftingcolons.com',
          );

          expect(commands, isNotEmpty);
        });

        test('Supports custom QR alignment, size and correction', () {
          final commands = builder.buildQrCode(
            generator,
            'PRODUCT-001',
            alignment: PosAlign.left,
            size: QRSize.size6,
            correction: QRCorrection.H,
          );

          expect(commands, isNotEmpty);
        });

        test('Supports Latin-1 compatible text', () {
          final commands = builder.buildQrCode(generator, 'Cafe \u00E9');

          expect(commands, isNotEmpty);
        });

        test('Rejects empty QR data', () {
          expect(
            () => builder.buildQrCode(generator, ' '),
            throwsArgumentError,
          );
        });

        test('Rejects unsupported Unicode QR data', () {
          expect(
            () => builder.buildQrCode(
              generator,
              'Product \u0634\u0627\u0645\u067E\u0648',
            ),
            throwsArgumentError,
          );
        });
      });

      group('buildFeed and buildCut', () {
        late EscPosBuilder builder;
        late Generator generator;

        setUp(() {
          final configuration = PrinterConfiguration(
            printerName: 'Thermal Printer',
            printerAddress: '00:11:22:33:44:55',
          );

          builder = EscPosBuilder(
            configuration: configuration,
            capabilityProfile: profile,
          );

          generator = builder.createGenerator();
        });

        test('Generates default paper feed command', () {
          final commands = builder.buildFeed(generator);

          expect(commands, isNotEmpty);
        });

        test('Supports custom paper feed lines', () {
          final commands = builder.buildFeed(generator, lines: 5);

          expect(commands, isNotEmpty);
        });

        test('Allows zero feed lines', () {
          final commands = builder.buildFeed(generator, lines: 0);

          expect(commands, equals([27, 100, 0]));
        });

        test('Rejects negative feed lines', () {
          expect(
            () => builder.buildFeed(generator, lines: -1),
            throwsArgumentError,
          );
        });

        test('Rejects feed lines above 255', () {
          expect(
            () => builder.buildFeed(generator, lines: 256),
            throwsArgumentError,
          );
        });

        test('Generates default paper cut command', () {
          final commands = builder.buildCut(generator);

          expect(commands, isNotEmpty);
        });

        test('Supports full paper cut command', () {
          final commands = builder.buildCut(generator, mode: PosCutMode.full);

          expect(commands, isNotEmpty);
        });
      });

      test('Generates a basic text command', () {
        final commands = builder.buildText(generator, 'CraftingMPOS');

        expect(commands, isNotEmpty);
      });

      test('Generates centered bold text', () {
        final commands = builder.buildText(
          generator,
          'TOTAL',
          alignment: PosAlign.center,
          bold: true,
        );

        expect(commands, isNotEmpty);
      });

      test('Generates double-size text', () {
        final commands = builder.buildText(
          generator,
          'RECEIPT',
          doubleWidth: true,
          doubleHeight: true,
        );

        expect(commands, isNotEmpty);
      });

      test('Supports lines after text', () {
        final commands = builder.buildText(
          generator,
          'Thank you',
          linesAfter: 2,
        );

        expect(commands, isNotEmpty);
      });

      test('Rejects empty text', () {
        expect(() => builder.buildText(generator, ''), throwsArgumentError);
      });

      test('Rejects negative lines after', () {
        expect(
          () => builder.buildText(generator, 'Invalid', linesAfter: -1),
          throwsArgumentError,
        );
      });
    });
  });
}
