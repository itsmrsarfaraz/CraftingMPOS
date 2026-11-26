import 'package:barcode/barcode.dart';
import 'package:image/image.dart' as img;

import '../../barcode_qr/models/generated_code.dart';
import '../../barcode_qr/models/label_layout_config.dart';
import '../../barcode_qr/models/product_label_data.dart';
import '../../barcode_qr/services/code_generation_service.dart';
import 'esc_pos_builder.dart';

/// Builds ESC/POS raster commands for product labels.
class ProductLabelBuilder {
  ProductLabelBuilder({required this.escPosBuilder});

  static const int maxRasterHeight = 4096;

  final EscPosBuilder escPosBuilder;
  final CodeGenerationService codeGenerationService = CodeGenerationService();

  /// Generates a complete product label print job.
  List<int> build({
    required ProductLabelData data,
    required LabelLayoutConfig layout,
  }) {
    final expectedFormat = switch (layout.template) {
      ProductLabelTemplate.standardBarcode ||
      ProductLabelTemplate.compactPrice => GeneratedCodeFormat.code128,
      ProductLabelTemplate.qrProduct => GeneratedCodeFormat.qrCode,
    };

    if (data.codeFormat != expectedFormat) {
      throw ArgumentError(
        '${layout.template.name} requires ${expectedFormat.name} format.',
      );
    }
    final canvas = switch (layout.template) {
      ProductLabelTemplate.standardBarcode => _buildStandardBarcode(
        data: data,
        layout: layout,
      ),
      ProductLabelTemplate.qrProduct => _buildQrProduct(
        data: data,
        layout: layout,
      ),
      ProductLabelTemplate.compactPrice => _buildCompactPrice(
        data: data,
        layout: layout,
      ),
    };

    final generator = escPosBuilder.createGenerator();
    final commands = <int>[
      ...escPosBuilder.initialize(generator),
      ...generator.imageRaster(canvas),
    ];

    return commands;
  }

  /// Calculates the raster dimensions for the selected printer.
  ({int width, int height}) calculateImageDimensions(LabelLayoutConfig layout) {
    if (layout.width <= 0 ||
        layout.height <= 0 ||
        !layout.width.isFinite ||
        !layout.height.isFinite) {
      throw ArgumentError('Label dimensions must be finite and positive.');
    }

    final paperWidth = escPosBuilder.paperSize.width;
    final width = (paperWidth ~/ 8) * 8;
    final aspectRatio = layout.height / layout.width;
    final height = (width * aspectRatio).round();

    if (height < 1) {
      throw ArgumentError('Calculated label height must be positive.');
    }

    if (height > maxRasterHeight) {
      throw ArgumentError(
        'Calculated label height exceeds the maximum '
        'of $maxRasterHeight pixels.',
      );
    }

    return (width: width, height: height);
  }

  img.Image _createCanvas(LabelLayoutConfig layout) {
    final dimensions = calculateImageDimensions(layout);

    if (!layout.padding.isFinite ||
        layout.padding < 0 ||
        layout.padding * 2 >= layout.width ||
        layout.padding * 2 >= layout.height) {
      throw ArgumentError('Label padding is invalid.');
    }

    final image = img.Image(
      width: dimensions.width,
      height: dimensions.height,
      numChannels: 3,
    );

    img.fill(image, color: img.ColorRgb8(255, 255, 255));

    return image;
  }

  int _scaleX(double value, LabelLayoutConfig layout, img.Image canvas) {
    return (value * canvas.width / layout.width).round();
  }

  int _scaleY(double value, LabelLayoutConfig layout, img.Image canvas) {
    return (value * canvas.height / layout.height).round();
  }

  List<String> _wrapText({
    required String text,
    required img.BitmapFont font,
    required int maxWidth,
  }) {
    if (maxWidth <= 0) {
      throw ArgumentError.value(maxWidth, 'maxWidth');
    }

    final words = text.trim().split(RegExp(r'\s+'));
    final lines = <String>[];
    var currentLine = '';

    int measure(String value) {
      return value.codeUnits.fold<int>(0, (width, codeUnit) {
        final character = font.characters[codeUnit];

        if (character == null) {
          throw ArgumentError.value(
            value,
            'text',
            'Text contains characters unsupported by the printer font.',
          );
        }

        return width + character.xAdvance;
      });
    }

    for (final word in words) {
      if (word.isEmpty) continue;

      final candidate = currentLine.isEmpty ? word : '$currentLine $word';

      if (measure(candidate) <= maxWidth) {
        currentLine = candidate;
        continue;
      }

      if (currentLine.isNotEmpty) {
        lines.add(currentLine);
      }

      if (measure(word) > maxWidth) {
        throw ArgumentError.value(
          word,
          'text',
          'A word exceeds the available label width.',
        );
      }

      currentLine = word;
    }

    if (currentLine.isNotEmpty) {
      lines.add(currentLine);
    }

    return lines;
  }

  void _drawCode({
    required img.Image canvas,
    required Barcode barcode,
    required String data,
    required int x,
    required int y,
    required int width,
    required int height,
  }) {
    if (width <= 0 || height <= 0) {
      throw ArgumentError('Barcode dimensions must be positive.');
    }

    final elements = barcode.make(
      data,
      width: width.toDouble(),
      height: height.toDouble(),
      drawText: false,
    );

    for (final element in elements) {
      if (element is! BarcodeBar || !element.black) {
        continue;
      }

      final left = (x + element.left).floor();
      final top = (y + element.top).floor();
      final right = (x + element.left + element.width).ceil() - 1;
      final bottom = (y + element.top + element.height).ceil() - 1;

      if (right < 0 ||
          bottom < 0 ||
          left >= canvas.width ||
          top >= canvas.height) {
        continue;
      }

      img.fillRect(
        canvas,
        x1: left.clamp(0, canvas.width - 1),
        y1: top.clamp(0, canvas.height - 1),
        x2: right.clamp(0, canvas.width - 1),
        y2: bottom.clamp(0, canvas.height - 1),
        color: img.ColorRgb8(0, 0, 0),
      );
    }
  }

  String _formatPrice(int pricePaisa) {
    final rupees = pricePaisa ~/ 100;
    final paisa = (pricePaisa % 100).toString().padLeft(2, '0');

    return 'Rs. $rupees.$paisa';
  }

  img.Image _buildCompactPrice({
    required ProductLabelData data,
    required LabelLayoutConfig layout,
  }) {
    final generatedCode = codeGenerationService.generate(
      data: data.code,
      format: GeneratedCodeFormat.code128,
    );

    final canvas = _createCanvas(layout);
    final marginX = _scaleX(layout.padding, layout, canvas);
    final marginY = _scaleY(layout.padding, layout, canvas);
    final availableWidth = canvas.width - marginX * 2;

    var y = marginY;

    if (layout.showProductName) {
      final lines = _wrapText(
        text: data.productName,
        font: img.arial14,
        maxWidth: availableWidth,
      );

      for (final line in lines) {
        _drawText(
          canvas: canvas,
          text: line,
          x: marginX,
          y: y,
          font: img.arial14,
          maxWidth: availableWidth,
        );
        y += img.arial14.lineHeight;
      }
    }

    if (layout.showVariantName && data.variantName.isNotEmpty) {
      final lines = _wrapText(
        text: data.variantName,
        font: img.arial14,
        maxWidth: availableWidth,
      );

      for (final line in lines) {
        _drawText(
          canvas: canvas,
          text: line,
          x: marginX,
          y: y,
          font: img.arial14,
          maxWidth: availableWidth,
        );
        y += img.arial14.lineHeight;
      }
    }

    for (final value in [
      if (layout.showCategory) data.categoryName,
      if (layout.showSku) data.sku,
    ]) {
      if (value == null || value.trim().isEmpty) continue;

      final lines = _wrapText(
        text: value,
        font: img.arial14,
        maxWidth: availableWidth,
      );

      for (final line in lines) {
        _drawText(
          canvas: canvas,
          text: line,
          x: marginX,
          y: y,
          font: img.arial14,
          maxWidth: availableWidth,
        );

        y += img.arial14.lineHeight;
      }
    }

    if (layout.showPrice) {
      final price = _formatPrice(data.sellingPrice);

      _drawText(
        canvas: canvas,
        text: price,
        x: marginX,
        y: y,
        font: img.arial24,
        maxWidth: availableWidth,
      );

      y += img.arial24.lineHeight;
    }

    final remainingHeight = canvas.height - marginY - y;
    final barcodeHeight = remainingHeight - img.arial14.lineHeight;

    if (barcodeHeight < 20) {
      throw ArgumentError(
        'Label height is insufficient for product details and barcode.',
      );
    }

    _drawCode(
      canvas: canvas,
      barcode: generatedCode.barcode,
      data: generatedCode.data,
      x: marginX,
      y: y,
      width: availableWidth,
      height: barcodeHeight,
    );

    y += barcodeHeight;

    if (layout.showCodeValue) {
      _drawText(
        canvas: canvas,
        text: generatedCode.data,
        x: marginX,
        y: y,
        font: img.arial14,
        maxWidth: availableWidth,
      );
    }

    return canvas;
  }

  img.Image _buildQrProduct({
    required ProductLabelData data,
    required LabelLayoutConfig layout,
  }) {
    final generatedCode = codeGenerationService.generate(
      data: data.code,
      format: GeneratedCodeFormat.qrCode,
    );

    final canvas = _createCanvas(layout);
    final marginX = _scaleX(layout.padding, layout, canvas);
    final marginY = _scaleY(layout.padding, layout, canvas);

    final availableWidth = canvas.width - marginX * 2;
    final availableHeight = canvas.height - marginY * 2;

    final qrSize = (availableHeight * 0.75).floor();

    if (qrSize < 40 || qrSize > availableWidth) {
      throw ArgumentError('Label dimensions are insufficient for the QR code.');
    }

    _drawCode(
      canvas: canvas,
      barcode: generatedCode.barcode,
      data: generatedCode.data,
      x: marginX,
      y: marginY,
      width: qrSize,
      height: qrSize,
    );

    final textX = marginX + qrSize + marginX;
    final textWidth = canvas.width - textX - marginX;

    if (textWidth <= 0) {
      throw ArgumentError('Insufficient space for product information.');
    }

    var y = marginY;

    void drawLines(String text, img.BitmapFont font) {
      final lines = _wrapText(text: text, font: font, maxWidth: textWidth);

      for (final line in lines) {
        if (y + font.lineHeight > canvas.height - marginY) {
          throw ArgumentError(
            'Product information exceeds the available QR label height.',
          );
        }

        _drawText(
          canvas: canvas,
          text: line,
          x: textX,
          y: y,
          font: font,
          maxWidth: textWidth,
        );

        y += font.lineHeight;
      }
    }

    if (layout.showProductName) {
      drawLines(data.productName, img.arial24);
    }

    if (layout.showVariantName && data.variantName.isNotEmpty) {
      drawLines(data.variantName, img.arial14);
    }

    if (layout.showPrice) {
      drawLines(_formatPrice(data.sellingPrice), img.arial14);
    }

    if (layout.showSku && data.sku != null && data.sku!.isNotEmpty) {
      drawLines('SKU: ${data.sku}', img.arial14);
    }

    if (layout.showCategory &&
        data.categoryName != null &&
        data.categoryName!.isNotEmpty) {
      drawLines(data.categoryName!, img.arial14);
    }

    if (layout.showCodeValue) {
      drawLines(generatedCode.data, img.arial14);
    }

    return canvas;
  }

  img.Image _buildStandardBarcode({
    required ProductLabelData data,
    required LabelLayoutConfig layout,
  }) {
    final generatedCode = codeGenerationService.generate(
      data: data.code,
      format: data.codeFormat,
    );

    if (generatedCode.format != GeneratedCodeFormat.code128) {
      throw ArgumentError('Standard barcode labels require CODE128 format.');
    }

    final canvas = _createCanvas(layout);
    final margin = _scaleX(layout.padding, layout, canvas);
    final verticalMargin = _scaleY(layout.padding, layout, canvas);
    final availableWidth = canvas.width - (margin * 2);

    var y = verticalMargin;

    // Product name.
    if (layout.showProductName) {
      final lines = _wrapText(
        text: data.productName,
        font: img.arial24,
        maxWidth: availableWidth,
      );

      for (final line in lines) {
        _drawText(
          canvas: canvas,
          text: line,
          x: margin,
          y: y,
          font: img.arial24,
          maxWidth: availableWidth,
        );
        y += img.arial24.lineHeight;
      }
    }

    // Variant name.
    if (layout.showVariantName && data.variantName.isNotEmpty) {
      final lines = _wrapText(
        text: data.variantName,
        font: img.arial14,
        maxWidth: availableWidth,
      );

      for (final line in lines) {
        _drawText(
          canvas: canvas,
          text: line,
          x: margin,
          y: y,
          font: img.arial14,
          maxWidth: availableWidth,
        );
        y += img.arial14.lineHeight;
      }
    }

    // Optional category and SKU.
    for (final value in [
      if (layout.showCategory) data.categoryName,
      if (layout.showSku) data.sku,
    ]) {
      if (value == null || value.trim().isEmpty) continue;

      final lines = _wrapText(
        text: value,
        font: img.arial14,
        maxWidth: availableWidth,
      );

      for (final line in lines) {
        _drawText(
          canvas: canvas,
          text: line,
          x: margin,
          y: y,
          font: img.arial14,
          maxWidth: availableWidth,
        );
        y += img.arial14.lineHeight;
      }
    }

    y += 4;

    // Barcode.
    final remainingHeight = canvas.height - verticalMargin - y;
    final barcodeHeight = remainingHeight - img.arial14.lineHeight;

    if (barcodeHeight < 20) {
      throw ArgumentError(
        'Label height is insufficient for the product details and barcode.',
      );
    }

    _drawCode(
      canvas: canvas,
      barcode: generatedCode.barcode,
      data: generatedCode.data,
      x: margin,
      y: y,
      width: availableWidth,
      height: barcodeHeight,
    );

    y += barcodeHeight;

    // Human-readable barcode value.
    if (layout.showCodeValue) {
      _drawText(
        canvas: canvas,
        text: generatedCode.data,
        x: margin,
        y: y,
        font: img.arial14,
        maxWidth: availableWidth,
      );
    }

    return canvas;
  }

  void _drawText({
    required img.Image canvas,
    required String text,
    required int x,
    required int y,
    required img.BitmapFont font,
    int? maxWidth,
  }) {
    for (final codeUnit in text.codeUnits) {
      if (!font.characters.containsKey(codeUnit)) {
        throw ArgumentError.value(
          text,
          'text',
          'Text contains characters unsupported by the printer font.',
        );
      }
    }

    final textWidth = text.codeUnits.fold<int>(
      0,
      (width, codeUnit) => width + font.characters[codeUnit]!.xAdvance,
    );

    if (maxWidth != null && textWidth > maxWidth) {
      throw ArgumentError.value(
        text,
        'text',
        'Text exceeds the available label width.',
      );
    }

    img.drawString(
      canvas,
      text,
      font: font,
      x: x,
      y: y,
      color: img.ColorRgb8(0, 0, 0),
    );
  }
}
