class ReceiptItemLine {
  factory ReceiptItemLine({
    required String productName,
    required String variantName,
    required int quantityMilliunits,
    required String unit,
    required int unitPricePaisa,
    required int lineTotalPaisa,
    String? sku,
  }) {
    if (productName.trim().isEmpty) {
      throw ArgumentError.value(productName, 'productName');
    }

    if (variantName.trim().isEmpty) {
      throw ArgumentError.value(variantName, 'variantName');
    }

    if (quantityMilliunits <= 0) {
      throw ArgumentError.value(quantityMilliunits, 'quantityMilliunits');
    }

    if (unit.trim().isEmpty) {
      throw ArgumentError.value(unit, 'unit');
    }

    if (unitPricePaisa < 0) {
      throw ArgumentError.value(unitPricePaisa, 'unitPricePaisa');
    }

    if (lineTotalPaisa < 0) {
      throw ArgumentError.value(lineTotalPaisa, 'lineTotalPaisa');
    }

    return ReceiptItemLine._(
      productName: productName.trim(),
      variantName: variantName.trim(),
      quantityMilliunits: quantityMilliunits,
      unit: unit.trim(),
      unitPricePaisa: unitPricePaisa,
      lineTotalPaisa: lineTotalPaisa,
      sku: sku?.trim().isEmpty ?? true ? null : sku!.trim(),
    );
  }

  const ReceiptItemLine._({
    required this.productName,
    required this.variantName,
    required this.quantityMilliunits,
    required this.unit,
    required this.unitPricePaisa,
    required this.lineTotalPaisa,
    this.sku,
  });

  final String productName;
  final String variantName;
  final int quantityMilliunits;
  final String unit;
  final int unitPricePaisa;
  final int lineTotalPaisa;
  final String? sku;
}
