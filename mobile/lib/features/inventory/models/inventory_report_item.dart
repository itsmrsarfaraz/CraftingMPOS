class InventoryReportItem {
  const InventoryReportItem({
    required this.productId,
    required this.productName,
    required this.variantId,
    required this.variantName,
    required this.sku,
    required this.categoryId,
    required this.categoryName,
    required this.unit,
    required this.costPrice,
    required this.sellingPrice,
    required this.trackStock,
    required this.quantityMilliunits,
    required this.lastStockUpdatedAt,
  });

  final String productId;
  final String productName;

  final String variantId;
  final String variantName;
  final String? sku;

  final String? categoryId;
  final String? categoryName;

  final String unit;

  /// Monetary values are stored in paisa.
  final int costPrice;
  final int sellingPrice;

  final bool trackStock;

  /// Stock quantity is stored in milliunits.
  final int quantityMilliunits;

  /// Null when no stock record exists for the selected scope.
  final DateTime? lastStockUpdatedAt;

  bool get isOutOfStock => trackStock && quantityMilliunits == 0;

  bool get isInStock => trackStock && quantityMilliunits > 0;

  bool get isUntracked => !trackStock;
}
