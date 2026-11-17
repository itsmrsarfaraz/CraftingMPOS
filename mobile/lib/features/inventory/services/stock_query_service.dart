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
}
