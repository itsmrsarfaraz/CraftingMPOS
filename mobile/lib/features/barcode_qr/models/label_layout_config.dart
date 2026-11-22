enum ProductLabelTemplate { standardBarcode, qrProduct, compactPrice }

class LabelLayoutConfig {
  const LabelLayoutConfig({
    required this.template,
    this.width = 240,
    this.height = 120,
    this.padding = 8,
    this.showProductName = true,
    this.showVariantName = true,
    this.showPrice = true,
    this.showSku = false,
    this.showCategory = false,
    this.showCodeValue = true,
  }) : assert(width > 0, 'Label width must be positive.'),
       assert(height > 0, 'Label height must be positive.'),
       assert(padding >= 0, 'Label padding cannot be negative.');

  final ProductLabelTemplate template;

  /// Label width in logical pixels.
  final double width;

  /// Label height in logical pixels.
  final double height;

  /// Inner spacing in logical pixels.
  final double padding;

  final bool showProductName;
  final bool showVariantName;
  final bool showPrice;
  final bool showSku;
  final bool showCategory;
  final bool showCodeValue;
}
