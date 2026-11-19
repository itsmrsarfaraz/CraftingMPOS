import '../../../core/database/app_database.dart';

class ProductDetails {
  const ProductDetails({
    required this.product,
    required this.category,
    required this.variants,
  });

  final Product product;
  final Category? category;
  final List<ProductVariant> variants;
}
