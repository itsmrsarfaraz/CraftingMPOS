import 'package:drift/drift.dart';

import 'package:crafting_mpos/core/database/app_database.dart';

import '../models/inventory_summary.dart';
import 'stock_query_service.dart';

class InventorySummaryService {
  InventorySummaryService(this._database)
    : _stockQueryService = StockQueryService(_database);

  final AppDatabase _database;
  final StockQueryService _stockQueryService;

  Future<InventorySummary> getSummary({
    required String businessId,
    String? branchId,
  }) async {
    // Validate that the selected branch belongs to this business.
    // Inactive branches remain valid for historical reporting.
    if (branchId != null) {
      final branch =
          await (_database.select(_database.branches)..where(
                (table) =>
                    table.id.equals(branchId) &
                    table.businessId.equals(businessId),
              ))
              .getSingleOrNull();

      if (branch == null) {
        throw ArgumentError.value(
          branchId,
          'branchId',
          'Branch does not exist or does not belong to this business.',
        );
      }
    }

    // Count active products.
    final activeProducts =
        await (_database.select(_database.products)..where(
              (product) =>
                  product.businessId.equals(businessId) &
                  product.isActive.equals(true),
            ))
            .get();

    // Fetch active variants belonging to active products.
    final variantQuery = _database.select(_database.productVariants).join([
      innerJoin(
        _database.products,
        _database.products.id.equalsExp(_database.productVariants.productId) &
            _database.products.businessId.equalsExp(
              _database.productVariants.businessId,
            ),
      ),
    ]);

    variantQuery.where(
      _database.productVariants.businessId.equals(businessId) &
          _database.productVariants.isActive.equals(true) &
          _database.products.isActive.equals(true),
    );

    final variantRows = await variantQuery.get();

    final variants = variantRows
        .map((row) => row.readTable(_database.productVariants))
        .toList();

    // Fetch persisted stock for the business or selected branch.
    // This intentionally includes inactive and untracked variants.
    final stockQuery = _database.select(_database.branchStocks)
      ..where((stock) => stock.businessId.equals(businessId));

    if (branchId != null) {
      stockQuery.where((stock) => stock.branchId.equals(branchId));
    }

    final stockRows = await stockQuery.get();

    var totalStockMilliunits = BigInt.zero;
    final stockByVariant = <String, BigInt>{};

    for (final stock in stockRows) {
      final quantity = BigInt.from(stock.quantityMilliunits);

      totalStockMilliunits += quantity;

      stockByVariant.update(
        stock.variantId,
        (current) => current + quantity,
        ifAbsent: () => quantity,
      );
    }

    // Calculate tracked and out-of-stock variants.
    var trackedVariants = 0;
    var outOfStockVariants = 0;

    for (final variant in variants) {
      if (!variant.trackStock) {
        continue;
      }

      trackedVariants++;

      final currentStock = stockByVariant[variant.id] ?? BigInt.zero;

      if (currentStock == BigInt.zero) {
        outOfStockVariants++;
      }
    }

    // Reuse the existing valuation implementation.
    final totalValuationPaisa = await _stockQueryService.getInventoryValuation(
      businessId: businessId,
      branchId: branchId,
    );

    // Protect the returned stock quantity from integer overflow.
    const maxInt64 = 9223372036854775807;
    final minInt64 = BigInt.from(-maxInt64 - 1);
    final maxInt64Big = BigInt.from(maxInt64);

    if (totalStockMilliunits > maxInt64Big || totalStockMilliunits < minInt64) {
      throw StateError('Total inventory quantity exceeds the supported range.');
    }

    return InventorySummary(
      totalProducts: activeProducts.length,
      totalVariants: variants.length,
      trackedVariants: trackedVariants,
      totalStockMilliunits: totalStockMilliunits.toInt(),
      outOfStockVariants: outOfStockVariants,
      totalValuationPaisa: totalValuationPaisa,
    );
  }
}
