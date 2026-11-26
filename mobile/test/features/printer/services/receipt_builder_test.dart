import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crafting_mpos/features/printer/models/printer_configuration.dart';
import 'package:crafting_mpos/features/printer/models/receipt_data.dart';
import 'package:crafting_mpos/features/printer/models/receipt_item_line.dart';
import 'package:crafting_mpos/features/printer/services/esc_pos_builder.dart';
import 'package:crafting_mpos/features/printer/services/receipt_builder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CapabilityProfile profile;
  late ReceiptData receipt;

  setUpAll(() async {
    profile = await CapabilityProfile.load();
  });

  setUp(() {
    receipt = ReceiptData(
      storeName: 'Crafting Store',
      storeAddress: 'Main Market, Parachinar',
      storePhone: '03001234567',
      receiptNumber: 'REC-001',
      issuedAt: DateTime(2026, 11, 25, 14, 30),
      items: [
        ReceiptItemLine(
          productName: 'Milk',
          variantName: '1 Litre',
          quantityMilliunits: 2000,
          unit: 'bottle',
          unitPricePaisa: 25000,
          lineTotalPaisa: 50000,
          sku: 'MILK-001',
        ),
      ],
      subtotalPaisa: 50000,
      discountPaisa: 5000,
      taxPaisa: 0,
      grandTotalPaisa: 45000,
      paymentMethod: 'Cash',
      amountPaidPaisa: 50000,
      changePaisa: 5000,
      footerMessage: 'Thank you for shopping!',
    );
  });

  ReceiptBuilder createBuilder(PrinterPaperWidth paperWidth) {
    final configuration = PrinterConfiguration(
      printerName: 'Test Printer',
      printerAddress: '00:11:22:33:44:55',
      paperWidth: paperWidth,
    );

    return ReceiptBuilder(
      escPosBuilder: EscPosBuilder(
        configuration: configuration,
        capabilityProfile: profile,
      ),
    );
  }

  group('ReceiptBuilder', () {
    test('Generates non-empty ESC/POS commands', () {
      final commands = createBuilder(PrinterPaperWidth.mm58).build(receipt);

      expect(commands, isNotEmpty);
      expect(commands.every((byte) => byte >= 0 && byte <= 255), isTrue);
    });

    test('Includes receipt content in generated commands', () {
      final commands = createBuilder(PrinterPaperWidth.mm58).build(receipt);
      final output = String.fromCharCodes(commands);

      expect(output, contains('Crafting Store'));
      expect(output, contains('REC-001'));
      expect(output, contains('Milk'));
      expect(output, contains('1 Litre'));
      expect(output, contains('Rs. 450.00'));
      expect(output, contains('Cash'));
      expect(output, contains('Thank you for shopping!'));
    });

    test('Includes formatted receipt date and time', () {
      final commands = createBuilder(PrinterPaperWidth.mm58).build(receipt);
      final output = String.fromCharCodes(commands);

      expect(output, contains('2026-11-25 14:30'));
    });

    test('Generates commands for 80mm paper', () {
      final commands = createBuilder(PrinterPaperWidth.mm80).build(receipt);

      expect(commands, isNotEmpty);
    });

    test('Generates commands for 58mm paper', () {
      final commands = createBuilder(PrinterPaperWidth.mm58).build(receipt);

      expect(commands, isNotEmpty);
    });

    test('Generates independent output for separate receipts', () {
      final builder = createBuilder(PrinterPaperWidth.mm58);

      final first = builder.build(receipt);
      final second = builder.build(receipt);

      expect(first, isNotEmpty);
      expect(second, isNotEmpty);
      expect(first, equals(second));
    });

    test('Preserves long product names in generated commands', () {
      final longName = ReceiptData(
        storeName: 'Crafting Store',
        receiptNumber: 'REC-002',
        issuedAt: DateTime(2026, 11, 25),
        items: [
          ReceiptItemLine(
            productName: 'Premium Quality Imported Cooking Oil',
            variantName: 'Five Litre Family Pack',
            quantityMilliunits: 1000,
            unit: 'bottle',
            unitPricePaisa: 125000,
            lineTotalPaisa: 125000,
          ),
        ],
        subtotalPaisa: 125000,
        discountPaisa: 0,
        taxPaisa: 0,
        grandTotalPaisa: 125000,
        paymentMethod: 'Cash',
        amountPaidPaisa: 125000,
        changePaisa: 0,
      );

      final commands = createBuilder(PrinterPaperWidth.mm58).build(longName);
      final output = String.fromCharCodes(commands);

      expect(output, contains('Premium Quality Imported Cookin'));
      expect(output, contains('g Oil - Five Litre Family Pack'));
    });

    test('Preserves long product names on 80mm paper', () {
      final longName = ReceiptData(
        storeName: 'Crafting Store',
        receiptNumber: 'REC-003',
        issuedAt: DateTime(2026, 11, 25),
        items: [
          ReceiptItemLine(
            productName: 'Premium Quality Imported Cooking Oil',
            variantName: 'Five Litre Family Pack',
            quantityMilliunits: 1000,
            unit: 'bottle',
            unitPricePaisa: 125000,
            lineTotalPaisa: 125000,
          ),
        ],
        subtotalPaisa: 125000,
        discountPaisa: 0,
        taxPaisa: 0,
        grandTotalPaisa: 125000,
        paymentMethod: 'Cash',
        amountPaidPaisa: 125000,
        changePaisa: 0,
      );

      final commands = createBuilder(PrinterPaperWidth.mm80).build(longName);
      final output = String.fromCharCodes(commands);

      expect(
        output,
        contains('Premium Quality Imported Cooking Oil - Five Lit'),
      );
      expect(output, contains('re Family Pack'));
    });
  });
}
