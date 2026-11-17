class InventorySummary {
  const InventorySummary({
    required this.totalProducts,
    required this.totalVariants,
    required this.trackedVariants,
    required this.totalStockMilliunits,
    required this.outOfStockVariants,
    required this.totalValuationPaisa,
  });

  final int totalProducts;
  final int totalVariants;
  final int trackedVariants;
  final int totalStockMilliunits;
  final int outOfStockVariants;
  final int totalValuationPaisa;
}
