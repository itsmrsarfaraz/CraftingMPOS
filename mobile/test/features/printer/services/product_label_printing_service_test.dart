import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crafting_mpos/features/barcode_qr/models/generated_code.dart';
import 'package:crafting_mpos/features/barcode_qr/models/label_layout_config.dart';
import 'package:crafting_mpos/features/barcode_qr/models/product_label_data.dart';
import 'package:crafting_mpos/features/printer/models/printer_configuration.dart';
import 'package:crafting_mpos/features/printer/models/printer_connection_state.dart';
import 'package:crafting_mpos/features/printer/models/printer_device.dart';
import 'package:crafting_mpos/features/printer/models/receipt_print_result.dart';
import 'package:crafting_mpos/features/printer/services/esc_pos_builder.dart';
import 'package:crafting_mpos/features/printer/services/printer_service.dart';
import 'package:crafting_mpos/features/printer/services/product_label_builder.dart';
import 'package:crafting_mpos/features/printer/services/product_label_printing_service.dart';

import '../repositories/fake_printer_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CapabilityProfile profile;
  late FakePrinterRepository repository;
  late PrinterService printerService;
  late ProductLabelBuilder productLabelBuilder;
  late ProductLabelPrintingService printingService;

  final printer = PrinterDevice(
    name: 'Thermal Printer',
    address: '00:11:22:33:44:55',
  );

  final productData = ProductLabelData(
    productName: 'Mineral Water',
    variantName: '500ml Bottle',
    code: 'MPOS-123456',
    codeFormat: GeneratedCodeFormat.code128,
    sellingPrice: 1250,
    unit: 'piece',
    sku: 'SKU-001',
    categoryName: 'Beverages',
  );

  const layout = LabelLayoutConfig(
    template: ProductLabelTemplate.standardBarcode,
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

    final escPosBuilder = EscPosBuilder(
      configuration: configuration,
      capabilityProfile: profile,
    );

    productLabelBuilder = ProductLabelBuilder(escPosBuilder: escPosBuilder);

    printingService = ProductLabelPrintingService(
      productLabelBuilder: productLabelBuilder,
      printerService: printerService,
    );
  });

  tearDown(() async {
    await printerService.dispose();
  });

  group('ProductLabelPrintingService', () {
    test(
      'prints product label successfully when printer is connected',
      () async {
        expect(await printerService.connect(printer), isTrue);

        final expectedBytes = productLabelBuilder.build(
          data: productData,
          layout: layout,
        );

        final result = await printingService.printLabel(
          data: productData,
          layout: layout,
        );

        expect(result.status, ReceiptPrintStatus.printed);
        expect(result.isSuccess, isTrue);
        expect(repository.connectionStatusCalls, 1);
        expect(repository.writeCalls, 1);
        expect(repository.writtenJobs, hasLength(1));
        expect(repository.writtenJobs.single, expectedBytes);
        expect(repository.writtenJobs.single, isNotEmpty);
      },
    );

    test('returns printerNotConnected when no printer is connected', () async {
      final result = await printingService.printLabel(
        data: productData,
        layout: layout,
      );

      expect(result.status, ReceiptPrintStatus.printerNotConnected);
      expect(result.isSuccess, isFalse);
      expect(repository.connectionStatusCalls, 0);
      expect(repository.writeCalls, 0);
    });

    test('returns transmissionFailed when Bluetooth write fails', () async {
      repository.writeResult = false;

      expect(await printerService.connect(printer), isTrue);

      final result = await printingService.printLabel(
        data: productData,
        layout: layout,
      );

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
        printingService.printLabel(data: productData, layout: layout),
        throwsA(isA<Exception>()),
      );

      expect(repository.writeCalls, 1);
    });

    test(
      'rejects incompatible code format and layout before transmission',
      () async {
        expect(await printerService.connect(printer), isTrue);

        final qrProductData = ProductLabelData(
          productName: 'Mineral Water',
          variantName: '500ml Bottle',
          code: 'MPOS-123456',
          codeFormat: GeneratedCodeFormat.qrCode,
          sellingPrice: 1250,
          unit: 'piece',
        );

        await expectLater(
          printingService.printLabel(data: qrProductData, layout: layout),
          throwsA(isA<ArgumentError>()),
        );

        expect(repository.connectionStatusCalls, 0);
        expect(repository.writeCalls, 0);
      },
    );
  });
}
