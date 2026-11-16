enum StockMovementType {
  opening,
  purchase,
  sale,
  adjustmentIn,
  adjustmentOut,
  transferIn,
  transferOut,
  customerReturn,
  supplierReturn,
  damage;

  String get databaseValue {
    switch (this) {
      case StockMovementType.opening:
        return 'opening';
      case StockMovementType.purchase:
        return 'purchase';
      case StockMovementType.sale:
        return 'sale';
      case StockMovementType.adjustmentIn:
        return 'adjustment_in';
      case StockMovementType.adjustmentOut:
        return 'adjustment_out';
      case StockMovementType.transferIn:
        return 'transfer_in';
      case StockMovementType.transferOut:
        return 'transfer_out';
      case StockMovementType.customerReturn:
        return 'customer_return';
      case StockMovementType.supplierReturn:
        return 'supplier_return';
      case StockMovementType.damage:
        return 'damage';
    }
  }

  bool get increasesStock {
    switch (this) {
      case StockMovementType.opening:
      case StockMovementType.purchase:
      case StockMovementType.adjustmentIn:
      case StockMovementType.transferIn:
      case StockMovementType.customerReturn:
        return true;

      case StockMovementType.sale:
      case StockMovementType.adjustmentOut:
      case StockMovementType.transferOut:
      case StockMovementType.supplierReturn:
      case StockMovementType.damage:
        return false;
    }
  }

  bool get isTransfer =>
      this == StockMovementType.transferIn ||
      this == StockMovementType.transferOut;
}
