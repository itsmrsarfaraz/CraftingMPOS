import 'package:barcode_widget/barcode_widget.dart';
import 'package:crafting_mpos/features/barcode_qr/models/generated_code.dart';
import 'package:crafting_mpos/features/barcode_qr/services/code_generation_service.dart';
import 'package:crafting_mpos/features/barcode_qr/widgets/barcode_preview.dart';
import 'package:crafting_mpos/features/barcode_qr/widgets/qr_code_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late CodeGenerationService service;
  late GeneratedCode barcode;
  late GeneratedCode qrCode;

  setUp(() {
    service = CodeGenerationService();

    barcode = service.generate(
      data: 'MPOS-123456',
      format: GeneratedCodeFormat.code128,
    );

    qrCode = service.generate(
      data: 'MPOS-123456',
      format: GeneratedCodeFormat.qrCode,
    );
  });

  group('BarcodePreview', () {
    testWidgets('renders CODE128 barcode', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: BarcodePreview(generatedCode: barcode)),
        ),
      );

      expect(find.byType(BarcodePreview), findsOneWidget);
      expect(find.byType(BarcodeWidget), findsOneWidget);

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    });

    testWidgets('uses configurable height', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BarcodePreview(generatedCode: barcode, height: 140),
          ),
        ),
      );

      final widget = tester.widget<BarcodeWidget>(find.byType(BarcodeWidget));

      expect(widget.height, 140);

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    });

    testWidgets('shows encoded value by default', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: BarcodePreview(generatedCode: barcode)),
        ),
      );

      final widget = tester.widget<BarcodeWidget>(find.byType(BarcodeWidget));

      expect(widget.drawText, isTrue);

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    });

    testWidgets('can hide encoded value', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BarcodePreview(generatedCode: barcode, showValue: false),
          ),
        ),
      );

      final widget = tester.widget<BarcodeWidget>(find.byType(BarcodeWidget));

      expect(widget.drawText, isFalse);
    });

    test('rejects QR code data', () {
      expect(() => BarcodePreview(generatedCode: qrCode), throwsAssertionError);
    });
  });

  group('QrCodePreview', () {
    testWidgets('renders QR code', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: QrCodePreview(generatedCode: qrCode)),
        ),
      );

      expect(find.byType(QrCodePreview), findsOneWidget);
      expect(find.byType(BarcodeWidget), findsOneWidget);
    });

    testWidgets('uses configurable size', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: QrCodePreview(generatedCode: qrCode, size: 220)),
        ),
      );

      final widget = tester.widget<BarcodeWidget>(find.byType(BarcodeWidget));

      expect(widget.width, 220);
      expect(widget.height, 220);
    });

    testWidgets('hides encoded value by default', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: QrCodePreview(generatedCode: qrCode)),
        ),
      );

      final widget = tester.widget<BarcodeWidget>(find.byType(BarcodeWidget));

      expect(widget.drawText, isFalse);
    });

    testWidgets('can show encoded value', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QrCodePreview(generatedCode: qrCode, showValue: true),
          ),
        ),
      );

      final widget = tester.widget<BarcodeWidget>(find.byType(BarcodeWidget));

      expect(widget.drawText, isTrue);
    });

    test('rejects CODE128 data', () {
      expect(() => QrCodePreview(generatedCode: barcode), throwsAssertionError);
    });
  });
}
