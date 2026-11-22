import 'generated_code.dart';

class ProductLabelData {
  const ProductLabelData({
    required this.productName,
    required this.variantName,
    required this.code,
    required this.codeFormat,
    required this.sellingPrice,
    required this.unit,
    this.sku,
    this.categoryName,
  });

  final String productName;
  final String variantName;
  final String code;
  final GeneratedCodeFormat codeFormat;

  /// Selling price stored in paisa.
  final int sellingPrice;

  final String unit;
  final String? sku;
  final String? categoryName;
}
