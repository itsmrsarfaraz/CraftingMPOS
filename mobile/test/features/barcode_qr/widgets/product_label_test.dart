import 'package:barcode_widget/barcode_widget.dart';
import 'package:crafting_mpos/features/barcode_qr/models/generated_code.dart';
import 'package:crafting_mpos/features/barcode_qr/models/label_layout_config.dart';
import 'package:crafting_mpos/features/barcode_qr/models/product_label_data.dart';
import 'package:crafting_mpos/features/barcode_qr/widgets/compact_price_label.dart';
import 'package:crafting_mpos/features/barcode_qr/widgets/qr_product_label.dart';
import 'package:crafting_mpos/features/barcode_qr/widgets/standard_barcode_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ProductLabelData barcodeData;
  late ProductLabelData qrData;

  setUp(() {
    barcodeData = const ProductLabelData(
      productName: 'Mineral Water',
      variantName: '500ml Bottle',
      code: 'MPOS-123456',
      codeFormat: GeneratedCodeFormat.code128,
      sellingPrice: 1250,
      unit: 'piece',
      sku: 'SKU-001',
      categoryName: 'Beverages',
    );

    qrData = const ProductLabelData(
      productName: 'Mineral Water',
      variantName: '500ml Bottle',
      code: 'MPOS-123456',
      codeFormat: GeneratedCodeFormat.qrCode,
      sellingPrice: 1250,
      unit: 'piece',
      sku: 'SKU-001',
      categoryName: 'Beverages',
    );
  });

  group('StandardBarcodeLabel', () {
    testWidgets('renders product information and CODE128 barcode', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: StandardBarcodeLabel(data: barcodeData)),
        ),
      );

      expect(find.byType(StandardBarcodeLabel), findsOneWidget);
      expect(find.byType(BarcodeWidget), findsOneWidget);
      expect(find.text('Mineral Water'), findsOneWidget);
      expect(find.text('500ml Bottle'), findsOneWidget);
      final barcodeWidget = tester.widget<BarcodeWidget>(
        find.byType(BarcodeWidget),
      );

      expect(barcodeWidget.drawText, isTrue);
      expect(find.text('Rs. 12.50'), findsOneWidget);
    });

    testWidgets('shows optional SKU and category', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StandardBarcodeLabel(
              data: barcodeData,
              config: const LabelLayoutConfig(
                template: ProductLabelTemplate.standardBarcode,
                showSku: true,
                showCategory: true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('SKU: SKU-001'), findsOneWidget);
      expect(find.text('Beverages'), findsOneWidget);
    });

    testWidgets('respects visibility configuration', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StandardBarcodeLabel(
              data: barcodeData,
              config: const LabelLayoutConfig(
                template: ProductLabelTemplate.standardBarcode,
                showProductName: false,
                showVariantName: false,
                showPrice: false,
                showCodeValue: false,
              ),
            ),
          ),
        ),
      );

      final barcodeWidget = tester.widget<BarcodeWidget>(
        find.byType(BarcodeWidget),
      );

      expect(find.text('Mineral Water'), findsNothing);
      expect(find.text('500ml Bottle'), findsNothing);
      expect(find.text('Rs. 12.50'), findsNothing);
      expect(find.text('MPOS-123456'), findsNothing);
      expect(barcodeWidget.drawText, isFalse);
    });

    testWidgets('uses configured dimensions', (tester) async {
      const config = LabelLayoutConfig(
        template: ProductLabelTemplate.standardBarcode,
        width: 300,
        height: 150,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StandardBarcodeLabel(data: barcodeData, config: config),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(StandardBarcodeLabel),
              matching: find.byType(Container),
            )
            .first,
      );

      expect(container.constraints?.maxWidth, 300);
      expect(container.constraints?.maxHeight, 150);
      expect(container.decoration, isA<BoxDecoration>());
    });

    test('rejects QR code data', () {
      expect(() => StandardBarcodeLabel(data: qrData), throwsAssertionError);
    });
  });

  group('QrProductLabel', () {
    testWidgets('renders product information and QR code', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: QrProductLabel(data: qrData)),
        ),
      );

      expect(find.byType(QrProductLabel), findsOneWidget);
      expect(find.byType(BarcodeWidget), findsOneWidget);
      expect(find.text('Mineral Water'), findsOneWidget);
      expect(find.text('500ml Bottle'), findsOneWidget);
      expect(find.text('Rs. 12.50'), findsOneWidget);
    });

    testWidgets('shows optional SKU and category', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QrProductLabel(
              data: qrData,
              config: const LabelLayoutConfig(
                template: ProductLabelTemplate.qrProduct,
                showSku: true,
                showCategory: true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('SKU: SKU-001'), findsOneWidget);
      expect(find.text('Beverages'), findsOneWidget);
    });

    testWidgets('hides encoded QR value by default', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: QrProductLabel(data: qrData)),
        ),
      );

      final barcodeWidget = tester.widget<BarcodeWidget>(
        find.byType(BarcodeWidget),
      );

      expect(barcodeWidget.drawText, isFalse);
    });

    testWidgets('respects visibility configuration', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QrProductLabel(
              data: qrData,
              config: const LabelLayoutConfig(
                template: ProductLabelTemplate.qrProduct,
                showProductName: false,
                showVariantName: false,
                showPrice: false,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Mineral Water'), findsNothing);
      expect(find.text('500ml Bottle'), findsNothing);
      expect(find.text('Rs. 12.50'), findsNothing);
    });

    testWidgets('uses configured dimensions', (tester) async {
      const config = LabelLayoutConfig(
        template: ProductLabelTemplate.qrProduct,
        width: 280,
        height: 180,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QrProductLabel(data: qrData, config: config),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(QrProductLabel),
              matching: find.byType(Container),
            )
            .first,
      );

      expect(container.constraints?.maxWidth, 280);
      expect(container.constraints?.maxHeight, 180);
    });

    test('rejects CODE128 data', () {
      expect(() => QrProductLabel(data: barcodeData), throwsAssertionError);
    });
  });

  group('CompactPriceLabel', () {
    testWidgets('renders product name, prominent price and CODE128 barcode', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: CompactPriceLabel(data: barcodeData)),
        ),
      );

      expect(find.byType(CompactPriceLabel), findsOneWidget);
      expect(find.byType(BarcodeWidget), findsOneWidget);
      expect(find.text('Mineral Water'), findsOneWidget);
      expect(find.text('Rs. 12.50'), findsOneWidget);
    });

    testWidgets('hides variant, SKU and encoded value by default', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: CompactPriceLabel(data: barcodeData)),
        ),
      );

      final barcodeWidget = tester.widget<BarcodeWidget>(
        find.byType(BarcodeWidget),
      );

      expect(find.text('500ml Bottle'), findsNothing);
      expect(find.text('SKU: SKU-001'), findsNothing);
      expect(find.text('MPOS-123456'), findsNothing);
      expect(barcodeWidget.drawText, isFalse);
    });

    testWidgets('respects visibility configuration', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompactPriceLabel(
              data: barcodeData,
              config: const LabelLayoutConfig(
                template: ProductLabelTemplate.compactPrice,
                showProductName: false,
                showPrice: false,
                showCodeValue: true,
              ),
            ),
          ),
        ),
      );

      final barcodeWidget = tester.widget<BarcodeWidget>(
        find.byType(BarcodeWidget),
      );

      expect(find.text('Mineral Water'), findsNothing);
      expect(find.text('Rs. 12.50'), findsNothing);
      expect(barcodeWidget.drawText, isTrue);
    });

    testWidgets('uses configured dimensions', (tester) async {
      const config = LabelLayoutConfig(
        template: ProductLabelTemplate.compactPrice,
        width: 220,
        height: 110,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompactPriceLabel(data: barcodeData, config: config),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(CompactPriceLabel),
              matching: find.byType(Container),
            )
            .first,
      );

      expect(container.constraints?.maxWidth, 220);
      expect(container.constraints?.maxHeight, 110);
    });

    test('rejects QR code data', () {
      expect(() => CompactPriceLabel(data: qrData), throwsAssertionError);
    });
  });
}
