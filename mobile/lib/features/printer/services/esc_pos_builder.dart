import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

import '../models/printer_configuration.dart';

/// Creates ESC/POS commands for supported thermal printers.
class EscPosBuilder {
  /// Generates a text command with configurable formatting.
  List<int> buildText(
    Generator generator,
    String value, {
    PosAlign alignment = PosAlign.left,
    bool bold = false,
    bool doubleWidth = false,
    bool doubleHeight = false,
    int linesAfter = 0,
  }) {
    if (value.isEmpty) {
      throw ArgumentError.value(value, 'value', 'Text cannot be empty.');
    }

    if (linesAfter < 0) {
      throw ArgumentError.value(
        linesAfter,
        'linesAfter',
        'Lines after cannot be negative.',
      );
    }

    return generator.text(
      value,
      styles: PosStyles(
        align: alignment,
        bold: bold,
        width: doubleWidth ? PosTextSize.size2 : PosTextSize.size1,
        height: doubleHeight ? PosTextSize.size2 : PosTextSize.size1,
      ),
      linesAfter: linesAfter,
    );
  }

  /// Generates a native CODE128 barcode command.
  List<int> buildBarcode(
    Generator generator,
    String value, {
    PosAlign alignment = PosAlign.center,
    int height = 80,
    int width = 3,
    bool showText = true,
  }) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(
        value,
        'value',
        'Barcode value cannot be empty.',
      );
    }

    if (height < 1 || height > 255) {
      throw ArgumentError.value(
        height,
        'height',
        'Barcode height must be between 1 and 255.',
      );
    }

    if (width < 2 || width > 6) {
      throw ArgumentError.value(
        width,
        'width',
        'Barcode width must be between 2 and 6.',
      );
    }

    if (value.runes.any((rune) => rune < 32 || rune > 126)) {
      throw ArgumentError.value(
        value,
        'value',
        'CODE128 input must contain printable ASCII characters.',
      );
    }

    return generator.barcode(
      Barcode.code128(value.split('')),
      align: alignment,
      height: height,
      width: width,
      textPos: showText ? BarcodeText.below : BarcodeText.none,
    );
  }

  /// Generates a native ESC/POS QR code command.
  List<int> buildQrCode(
    Generator generator,
    String value, {
    PosAlign alignment = PosAlign.center,
    QRSize size = QRSize.size4,
    QRCorrection correction = QRCorrection.M,
  }) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(
        value,
        'value',
        'QR code data cannot be empty.',
      );
    }

    if (value.runes.any((rune) => rune > 255)) {
      throw ArgumentError.value(
        value,
        'value',
        'Native ESC/POS QR data must be Latin-1 compatible.',
      );
    }

    return generator.qrcode(
      value,
      align: alignment,
      size: size,
      cor: correction,
    );
  }

  /// Generates a paper feed command.
  List<int> buildFeed(Generator generator, {int lines = 3}) {
    if (lines < 0 || lines > 255) {
      throw ArgumentError.value(
        lines,
        'lines',
        'Feed lines must be between 0 and 255.',
      );
    }

    return generator.feed(lines);
  }

  /// Generates a paper cut command.
  List<int> buildCut(
    Generator generator, {
    PosCutMode mode = PosCutMode.partial,
  }) {
    return generator.cut(mode: mode);
  }

  EscPosBuilder({required this.configuration, required this.capabilityProfile});

  final PrinterConfiguration configuration;
  final CapabilityProfile capabilityProfile;

  PaperSize get paperSize {
    switch (configuration.paperWidth) {
      case PrinterPaperWidth.mm58:
        return PaperSize.mm58;
      case PrinterPaperWidth.mm80:
        return PaperSize.mm80;
    }
  }

  /// Creates a fresh generator for each independent print job.
  Generator createGenerator() {
    return Generator(paperSize, capabilityProfile);
  }

  /// Initializes a printer and returns its ESC/POS commands.
  List<int> initialize(Generator generator) {
    return generator.reset();
  }
}
