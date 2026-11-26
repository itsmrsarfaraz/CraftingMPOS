import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crafting_mpos/features/barcode_qr/models/label_layout_config.dart';
import 'package:crafting_mpos/features/printer/models/printer_configuration.dart';
import 'package:crafting_mpos/features/printer/services/esc_pos_builder.dart';
import 'package:crafting_mpos/features/printer/services/product_label_builder.dart';
import 'package:crafting_mpos/features/barcode_qr/models/generated_code.dart';
import 'package:crafting_mpos/features/barcode_qr/models/product_label_data.dart';

ProductLabelData createProductData({
  GeneratedCodeFormat format = GeneratedCodeFormat.code128,
}) {
  return ProductLabelData(
    productName: 'Mineral Water',
    variantName: '500ml Bottle',
    code: 'MPOS-123456',
    codeFormat: format,
    sellingPrice: 1250,
    unit: 'piece',
    sku: 'SKU-001',
    categoryName: 'Beverages',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CapabilityProfile profile;

  setUpAll(() async {
    profile = await CapabilityProfile.load();
  });

  group('ProductLabelBuilder', () {
    late ProductLabelBuilder builder;

    setUp(() {
      final configuration = PrinterConfiguration(
        printerName: 'Thermal Printer',
        printerAddress: '00:11:22:33:44:55',
      );

      final escPosBuilder = EscPosBuilder(
        configuration: configuration,
        capabilityProfile: profile,
      );

      builder = ProductLabelBuilder(escPosBuilder: escPosBuilder);
    });

    group('calculateImageDimensions', () {
      test('Calculates dimensions for 58mm printer', () {
        final dimensions = builder.calculateImageDimensions(
          const LabelLayoutConfig(
            template: ProductLabelTemplate.standardBarcode,
          ),
        );

        expect(dimensions.width, 384);
        expect(dimensions.width % 8, 0);
        expect(dimensions.height, 192);
      });

      test('Preserves configured aspect ratio', () {
        final dimensions = builder.calculateImageDimensions(
          const LabelLayoutConfig(
            template: ProductLabelTemplate.standardBarcode,
            width: 300,
            height: 100,
          ),
        );

        expect(dimensions.width, 384);
        expect(dimensions.height, 128);
      });

      test('Calculates dimensions for 80mm printer', () {
        final configuration = PrinterConfiguration(
          printerName: 'Thermal Printer',
          printerAddress: '00:11:22:33:44:55',
          paperWidth: PrinterPaperWidth.mm80,
        );

        final escPosBuilder = EscPosBuilder(
          configuration: configuration,
          capabilityProfile: profile,
        );

        final builder = ProductLabelBuilder(escPosBuilder: escPosBuilder);

        final dimensions = builder.calculateImageDimensions(
          const LabelLayoutConfig(
            template: ProductLabelTemplate.standardBarcode,
          ),
        );

        expect(dimensions.width, 576);
        expect(dimensions.width % 8, 0);
        expect(dimensions.height, 288);
      });

      test('Rejects non-finite dimensions', () {
        expect(
          () => builder.calculateImageDimensions(
            const LabelLayoutConfig(
              template: ProductLabelTemplate.standardBarcode,
              width: double.infinity,
            ),
          ),
          throwsArgumentError,
        );
      });

      test('Rejects raster dimensions exceeding maximum height', () {
        expect(
          () => builder.calculateImageDimensions(
            const LabelLayoutConfig(
              template: ProductLabelTemplate.standardBarcode,
              width: 100,
              height: 2000,
            ),
          ),
          throwsArgumentError,
        );
      });
    });
    group('build', () {
      test('Generates raster output for standard barcode label', () {
        final commands = builder.build(
          data: createProductData(),
          layout: const LabelLayoutConfig(
            template: ProductLabelTemplate.standardBarcode,
          ),
        );

        expect(commands, isNotEmpty);
        expect(commands, containsAllInOrder([29, 118, 48]));
      });

      test('Generates raster output for QR product label', () {
        final commands = builder.build(
          data: createProductData(format: GeneratedCodeFormat.qrCode),
          layout: const LabelLayoutConfig(
            template: ProductLabelTemplate.qrProduct,
          ),
        );

        expect(commands, isNotEmpty);
        expect(commands, containsAllInOrder([29, 118, 48]));
      });

      test('Generates raster output for compact price label', () {
        final commands = builder.build(
          data: createProductData(),
          layout: const LabelLayoutConfig(
            template: ProductLabelTemplate.compactPrice,
          ),
        );

        expect(commands, isNotEmpty);
        expect(commands, containsAllInOrder([29, 118, 48]));
      });

      test('Rejects QR code in standard barcode template', () {
        expect(
          () => builder.build(
            data: createProductData(format: GeneratedCodeFormat.qrCode),
            layout: const LabelLayoutConfig(
              template: ProductLabelTemplate.standardBarcode,
            ),
          ),
          throwsArgumentError,
        );
      });

      test('Rejects barcode in QR product template', () {
        expect(
          () => builder.build(
            data: createProductData(),
            layout: const LabelLayoutConfig(
              template: ProductLabelTemplate.qrProduct,
            ),
          ),
          throwsArgumentError,
        );
      });

      group('Price formatting', () {
        test('Generates label for whole rupee price', () {
          final commands = builder.build(
            data: ProductLabelData(
              productName: 'Water',
              variantName: '500ml',
              code: 'MPOS-001',
              codeFormat: GeneratedCodeFormat.code128,
              sellingPrice: 1200,
              unit: 'piece',
            ),
            layout: const LabelLayoutConfig(
              template: ProductLabelTemplate.compactPrice,
            ),
          );

          expect(commands, isNotEmpty);
        });

        test('Generates label for single-digit paisa', () {
          final commands = builder.build(
            data: ProductLabelData(
              productName: 'Water',
              variantName: '500ml',
              code: 'MPOS-002',
              codeFormat: GeneratedCodeFormat.code128,
              sellingPrice: 1205,
              unit: 'piece',
            ),
            layout: const LabelLayoutConfig(
              template: ProductLabelTemplate.compactPrice,
            ),
          );

          expect(commands, isNotEmpty);
        });

        test('Generates label for zero price', () {
          final commands = builder.build(
            data: ProductLabelData(
              productName: 'Water',
              variantName: '500ml',
              code: 'MPOS-003',
              codeFormat: GeneratedCodeFormat.code128,
              sellingPrice: 0,
              unit: 'piece',
            ),
            layout: const LabelLayoutConfig(
              template: ProductLabelTemplate.compactPrice,
            ),
          );

          expect(commands, isNotEmpty);
        });
      });

      test('Generates compact label with SKU and category', () {
        final commands = builder.build(
          data: createProductData(),
          layout: const LabelLayoutConfig(
            template: ProductLabelTemplate.compactPrice,
            showSku: true,
            showCategory: true,
          ),
        );

        expect(commands, isNotEmpty);
        expect(commands, containsAllInOrder([29, 118, 48]));
      });
    });
  });
}
