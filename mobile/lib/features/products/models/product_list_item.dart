import '../../../core/database/app_database.dart';

class ProductListItem {
  const ProductListItem({required this.product, required this.category});

  final Product product;
  final Category? category;
}
