import 'package:barcode_widget/barcode_widget.dart';

import '../models/generated_code.dart';

class CodeGenerationService {
  static const int maxDataLength = 255;

  GeneratedCode generate({
    required String data,
    required GeneratedCodeFormat format,
    BarcodeQRCorrectionLevel qrCorrectionLevel =
        BarcodeQRCorrectionLevel.medium,
  }) {
    final normalizedData = data.trim();

    if (normalizedData.isEmpty) {
      throw ArgumentError.value(data, 'data', 'Code data cannot be empty.');
    }

    if (normalizedData.length > maxDataLength) {
      throw ArgumentError.value(
        data,
        'data',
        'Code data cannot exceed $maxDataLength characters.',
      );
    }

    final Barcode barcode = switch (format) {
      GeneratedCodeFormat.code128 => Barcode.code128(),
      GeneratedCodeFormat.qrCode => Barcode.qrCode(
        errorCorrectLevel: qrCorrectionLevel,
      ),
    };

    if (format == GeneratedCodeFormat.code128 &&
        normalizedData.runes.any((rune) => rune > 0xFF)) {
      throw ArgumentError.value(
        normalizedData,
        'data',
        'CODE128 supports only ASCII and Latin-1 characters.',
      );
    }

    if (!barcode.isValid(normalizedData)) {
      throw ArgumentError.value(
        normalizedData,
        'data',
        'The supplied data is invalid for ${format.name}.',
      );
    }

    return GeneratedCode(
      data: normalizedData,
      format: format,
      barcode: barcode,
    );
  }
}
