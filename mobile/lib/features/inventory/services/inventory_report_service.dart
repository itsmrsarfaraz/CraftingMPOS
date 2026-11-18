import 'package:drift/drift.dart';

import 'package:crafting_mpos/core/database/app_database.dart';

import '../models/inventory_report_item.dart';
import '../models/inventory_stock_status.dart';

class InventoryReportService {
  InventoryReportService(this._database);

  final AppDatabase _database;

  Future<List<InventoryReportItem>> getReport({
    required String businessId,
    String? branchId,
    String? searchQuery,
    String? categoryId,
    InventoryStockStatus stockStatus = InventoryStockStatus.all,
    int limit = 50,
    int offset = 0,
  }) async {
    // Validate pagination arguments.
    if (limit <= 0) {
      throw ArgumentError.value(
        limit,
        'limit',
        'Limit must be greater than zero.',
      );
    }

    if (offset < 0) {
      throw ArgumentError.value(offset, 'offset', 'Offset cannot be negative.');
    }

    // Validate that the selected branch belongs to this business.
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

    // Build the product and variant query.
    final query = _database.select(_database.productVariants).join([
      innerJoin(
        _database.products,
        _database.products.id.equalsExp(_database.productVariants.productId) &
            _database.products.businessId.equalsExp(
              _database.productVariants.businessId,
            ),
      ),
      leftOuterJoin(
        _database.categories,
        _database.categories.id.equalsExp(_database.products.categoryId) &
            _database.categories.businessId.equalsExp(
              _database.products.businessId,
            ),
      ),
      leftOuterJoin(
        _database.branchStocks,
        _database.branchStocks.variantId.equalsExp(
              _database.productVariants.id,
            ) &
            _database.branchStocks.businessId.equalsExp(
              _database.productVariants.businessId,
            ) &
            (branchId == null
                ? const Constant(true)
                : _database.branchStocks.branchId.equals(branchId)),
      ),
    ]);

    query.where(
      _database.productVariants.businessId.equals(businessId) &
          _database.productVariants.isActive.equals(true) &
          _database.products.isActive.equals(true),
    );

    // Apply optional category filtering.
    if (categoryId != null) {
      query.where(_database.products.categoryId.equals(categoryId));
    }

    // Apply optional product name or SKU search.
    final normalizedSearch = searchQuery?.trim();

    if (normalizedSearch != null && normalizedSearch.isNotEmpty) {
      final searchPattern = '%${normalizedSearch.toLowerCase()}%';

      query.where(
        _database.products.name.lower().like(searchPattern) |
            _database.productVariants.sku.lower().like(searchPattern),
      );
    }

    final rows = await query.get();

    // Aggregate stock records into one report item per variant.
    final reportItems = <String, InventoryReportItem>{};
    final quantities = <String, BigInt>{};
    final latestUpdates = <String, DateTime>{};

    for (final row in rows) {
      final variant = row.readTable(_database.productVariants);
      final product = row.readTable(_database.products);
      final category = row.readTableOrNull(_database.categories);
      final stock = row.readTableOrNull(_database.branchStocks);

      reportItems.putIfAbsent(
        variant.id,
        () => InventoryReportItem(
          productId: product.id,
          productName: product.name,
          variantId: variant.id,
          variantName: variant.name,
          sku: variant.sku,
          categoryId: product.categoryId,
          categoryName: category?.name,
          unit: variant.unit,
          costPrice: variant.costPrice,
          sellingPrice: variant.sellingPrice,
          trackStock: variant.trackStock,
          quantityMilliunits: 0,
          lastStockUpdatedAt: null,
        ),
      );

      if (stock != null) {
        quantities.update(
          variant.id,
          (current) => current + BigInt.from(stock.quantityMilliunits),
          ifAbsent: () => BigInt.from(stock.quantityMilliunits),
        );

        final previousUpdate = latestUpdates[variant.id];

        if (previousUpdate == null || stock.updatedAt.isAfter(previousUpdate)) {
          latestUpdates[variant.id] = stock.updatedAt;
        }
      }
    }

    // Convert aggregated values into final report items.
    const maxInt64 = 9223372036854775807;
    final minInt64 = BigInt.from(-maxInt64 - 1);
    final maxInt64Big = BigInt.from(maxInt64);

    final items = reportItems.entries.map((entry) {
      final variantId = entry.key;
      final item = entry.value;
      final quantity = quantities[variantId] ?? BigInt.zero;

      if (quantity > maxInt64Big || quantity < minInt64) {
        throw StateError(
          'Inventory quantity exceeds the supported integer range.',
        );
      }

      return InventoryReportItem(
        productId: item.productId,
        productName: item.productName,
        variantId: item.variantId,
        variantName: item.variantName,
        sku: item.sku,
        categoryId: item.categoryId,
        categoryName: item.categoryName,
        unit: item.unit,
        costPrice: item.costPrice,
        sellingPrice: item.sellingPrice,
        trackStock: item.trackStock,
        quantityMilliunits: quantity.toInt(),
        lastStockUpdatedAt: latestUpdates[variantId],
      );
    }).toList();

    // Apply stock-status filtering after stock aggregation.
    final filteredItems = items.where((item) {
      switch (stockStatus) {
        case InventoryStockStatus.all:
          return true;

        case InventoryStockStatus.inStock:
          return item.isInStock;

        case InventoryStockStatus.outOfStock:
          return item.isOutOfStock;

        case InventoryStockStatus.untracked:
          return item.isUntracked;
      }
    }).toList();

    // Sort consistently before applying pagination.
    filteredItems.sort((a, b) {
      final productComparison = a.productName.toLowerCase().compareTo(
        b.productName.toLowerCase(),
      );

      if (productComparison != 0) {
        return productComparison;
      }

      final variantComparison = a.variantName.toLowerCase().compareTo(
        b.variantName.toLowerCase(),
      );

      if (variantComparison != 0) {
        return variantComparison;
      }

      return a.variantId.compareTo(b.variantId);
    });

    // Apply pagination after filtering and sorting.
    if (offset >= filteredItems.length) {
      return [];
    }

    final endIndex = (offset + limit).clamp(0, filteredItems.length);

    return filteredItems.sublist(offset, endIndex);
  }
}
