import 'package:barcode_widget/barcode_widget.dart';
import 'package:crafting_mpos/features/barcode_qr/models/generated_code.dart';
import 'package:crafting_mpos/features/barcode_qr/services/code_generation_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late CodeGenerationService service;

  setUp(() {
    service = CodeGenerationService();
  });

  group('CodeGenerationService', () {
    group('CODE128', () {
      test('generates a valid CODE128 barcode', () {
        final result = service.generate(
          data: 'MPOS-123456',
          format: GeneratedCodeFormat.code128,
        );

        expect(result.data, 'MPOS-123456');
        expect(result.format, GeneratedCodeFormat.code128);
        expect(result.barcode.isValid(result.data), isTrue);
      });
      test('rejects unsupported Unicode characters', () {
        expect(
          () => service.generate(
            data: 'Product 😀',
            format: GeneratedCodeFormat.code128,
          ),
          throwsArgumentError,
        );
      });
    });

    group('QR Code', () {
      test('generates a valid QR code', () {
        final result = service.generate(
          data: 'MPOS-123456',
          format: GeneratedCodeFormat.qrCode,
        );

        expect(result.data, 'MPOS-123456');
        expect(result.format, GeneratedCodeFormat.qrCode);
        expect(result.barcode.isValid(result.data), isTrue);
      });

      test('supports Urdu Unicode data', () {
        final result = service.generate(
          data: 'CraftingMPOS - پاکستان',
          format: GeneratedCodeFormat.qrCode,
        );

        expect(result.data, 'CraftingMPOS - پاکستان');
        expect(result.barcode.isValid(result.data), isTrue);
      });

      test('supports custom error correction level', () {
        final result = service.generate(
          data: 'MPOS-123456',
          format: GeneratedCodeFormat.qrCode,
          qrCorrectionLevel: BarcodeQRCorrectionLevel.high,
        );

        expect(result.barcode.isValid(result.data), isTrue);
      });
    });

    group('Input validation', () {
      test('rejects empty data', () {
        expect(
          () => service.generate(data: '', format: GeneratedCodeFormat.code128),
          throwsArgumentError,
        );
      });

      test('rejects whitespace-only data', () {
        expect(
          () =>
              service.generate(data: '   ', format: GeneratedCodeFormat.qrCode),
          throwsArgumentError,
        );
      });

      test('trims surrounding whitespace', () {
        final result = service.generate(
          data: '  MPOS-123456  ',
          format: GeneratedCodeFormat.code128,
        );

        expect(result.data, 'MPOS-123456');
      });

      test('rejects data exceeding 255 characters', () {
        expect(
          () => service.generate(
            data: 'A' * 256,
            format: GeneratedCodeFormat.qrCode,
          ),
          throwsArgumentError,
        );
      });
    });
  });
}
