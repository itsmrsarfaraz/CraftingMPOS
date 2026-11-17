import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';

class StockQueryService {
  StockQueryService(this._database);

  final AppDatabase _database;

  Future<int> getCurrentStock({
    required String businessId,
    required String branchId,
    required String variantId,
  }) async {
    final stock =
        await (_database.select(_database.branchStocks)..where(
              (table) =>
                  table.businessId.equals(businessId) &
                  table.branchId.equals(branchId) &
                  table.variantId.equals(variantId),
            ))
            .getSingleOrNull();

    return stock?.quantityMilliunits ?? 0;
  }

  Future<List<StockMovement>> getMovementHistory({
    required String businessId,
    required String variantId,
    String? branchId,
    int limit = 50,
    int offset = 0,
  }) async {
    if (limit <= 0) {
      throw ArgumentError.value(limit, 'limit', 'Must be greater than zero.');
    }

    if (offset < 0) {
      throw ArgumentError.value(offset, 'offset', 'Cannot be negative.');
    }

    final query = _database.select(_database.stockMovements)
      ..where(
        (table) =>
            table.businessId.equals(businessId) &
            table.variantId.equals(variantId),
      );

    if (branchId != null) {
      query.where((table) => table.branchId.equals(branchId));
    }

    query
      ..orderBy([(table) => OrderingTerm.desc(table.createdAt)])
      ..limit(limit, offset: offset);

    return query.get();
  }

  Future<int> getInventoryValuation({
    required String businessId,
    String? branchId,
  }) async {
    // 1. Validate stock independently of the product-variant join.
    final negativeStockQuery = _database.select(_database.branchStocks)
      ..where(
        (stock) =>
            stock.businessId.equals(businessId) &
            stock.quantityMilliunits.isSmallerThanValue(0),
      );

    if (branchId != null) {
      negativeStockQuery.where((stock) => stock.branchId.equals(branchId));
    }

    negativeStockQuery.limit(1);

    final negativeStock = await negativeStockQuery.getSingleOrNull();

    if (negativeStock != null) {
      throw StateError(
        'Negative stock detected for variant ${negativeStock.variantId}.',
      );
    }

    // 2. Join stock records with their product variants.
    final query = _database.select(_database.branchStocks).join([
      innerJoin(
        _database.productVariants,
        _database.productVariants.id.equalsExp(
              _database.branchStocks.variantId,
            ) &
            _database.productVariants.businessId.equalsExp(
              _database.branchStocks.businessId,
            ),
      ),
    ]);

    query.where(_database.branchStocks.businessId.equals(businessId));

    if (branchId != null) {
      query.where(_database.branchStocks.branchId.equals(branchId));
    }

    // 3. Calculate inventory valuation using integer arithmetic.
    final rows = await query.get();

    var totalValueInPaisa = BigInt.zero;

    for (final row in rows) {
      final stock = row.readTable(_database.branchStocks);
      final variant = row.readTable(_database.productVariants);

      totalValueInPaisa +=
          BigInt.from(stock.quantityMilliunits) *
          BigInt.from(variant.costPrice);
    }

    // 4. Round once after aggregating all stock values.
    final roundedValue =
        (totalValueInPaisa + BigInt.from(500)) ~/ BigInt.from(1000);

    // 5. Protect the supported integer range.
    const maxInt64 = 9223372036854775807;

    if (roundedValue > BigInt.from(maxInt64)) {
      throw StateError('Inventory valuation exceeds the supported range.');
    }

    return roundedValue.toInt();
  }
}
