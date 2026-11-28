import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crafting_mpos/features/printer/models/printer_configuration.dart';
import 'package:crafting_mpos/features/printer/models/printer_connection_state.dart';
import 'package:crafting_mpos/features/printer/models/printer_device.dart';
import 'package:crafting_mpos/features/printer/models/receipt_data.dart';
import 'package:crafting_mpos/features/printer/models/receipt_item_line.dart';
import 'package:crafting_mpos/features/printer/models/receipt_print_result.dart';
import 'package:crafting_mpos/features/printer/services/esc_pos_builder.dart';
import 'package:crafting_mpos/features/printer/services/printer_service.dart';
import 'package:crafting_mpos/features/printer/services/receipt_builder.dart';
import 'package:crafting_mpos/features/printer/services/receipt_printing_service.dart';

import '../repositories/fake_printer_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CapabilityProfile profile;
  late FakePrinterRepository repository;
  late PrinterService printerService;
  late ReceiptPrintingService receiptPrintingService;
  late ReceiptData receipt;

  final printer = PrinterDevice(
    name: 'Thermal Printer',
    address: '00:11:22:33:44:55',
  );

  setUpAll(() async {
    profile = await CapabilityProfile.load();
  });

  setUp(() {
    repository = FakePrinterRepository();
    printerService = PrinterService(repository: repository);

    final configuration = PrinterConfiguration(
      printerName: 'Thermal Printer',
      printerAddress: printer.address,
      paperWidth: PrinterPaperWidth.mm58,
    );

    final receiptBuilder = ReceiptBuilder(
      escPosBuilder: EscPosBuilder(
        configuration: configuration,
        capabilityProfile: profile,
      ),
    );

    receiptPrintingService = ReceiptPrintingService(
      receiptBuilder: receiptBuilder,
      printerService: printerService,
    );

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

  tearDown(() async {
    await printerService.dispose();
  });

  group('ReceiptPrintingService', () {
    test('prints receipt successfully when printer is connected', () async {
      expect(await printerService.connect(printer), isTrue);

      final result = await receiptPrintingService.printReceipt(receipt);

      expect(result.status, ReceiptPrintStatus.printed);
      expect(result.isSuccess, isTrue);
      expect(repository.connectionStatusCalls, 1);
      expect(repository.writeCalls, 1);
      expect(repository.writtenJobs, hasLength(1));
      expect(repository.writtenJobs.first, isNotEmpty);

      final output = String.fromCharCodes(repository.writtenJobs.first);

      expect(output, contains('Crafting Store'));
      expect(output, contains('REC-001'));
      expect(output, contains('Milk'));
    });

    test('returns printerNotConnected when no printer is connected', () async {
      final result = await receiptPrintingService.printReceipt(receipt);

      expect(result.status, ReceiptPrintStatus.printerNotConnected);
      expect(result.isSuccess, isFalse);
      expect(repository.connectionStatusCalls, 0);
      expect(repository.writeCalls, 0);
    });

    test('returns transmissionFailed when Bluetooth write fails', () async {
      repository.writeResult = false;

      expect(await printerService.connect(printer), isTrue);

      final result = await receiptPrintingService.printReceipt(receipt);

      expect(result.status, ReceiptPrintStatus.transmissionFailed);
      expect(result.isSuccess, isFalse);
      expect(repository.connectionStatusCalls, 1);
      expect(repository.writeCalls, 1);
      expect(printerService.state, PrinterConnectionState.connected);
    });

    test('propagates Bluetooth transmission exceptions', () async {
      repository.writeError = Exception('Bluetooth transmission failed');

      expect(await printerService.connect(printer), isTrue);

      await expectLater(
        receiptPrintingService.printReceipt(receipt),
        throwsA(isA<Exception>()),
      );

      expect(repository.writeCalls, 1);
    });
  });
}
