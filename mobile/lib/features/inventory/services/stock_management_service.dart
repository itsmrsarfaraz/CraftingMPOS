import 'dart:math';

import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../models/stock_movement_type.dart';

class StockManagementService {
  StockManagementService(this._database);

  final AppDatabase _database;

  static final Random _random = Random.secure();

  static String _newId(String prefix) {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    final value = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();

    return '$prefix-$value';
  }

  Future<void> recordMovement({
    required String businessId,
    required String branchId,
    required String variantId,
    required StockMovementType type,
    required int quantityMilliunits,
    int? unitCostPaisa,
    String? referenceType,
    String? referenceId,
    String? note,
    String? createdByUserId,
  }) async {
    if (quantityMilliunits <= 0) {
      throw ArgumentError.value(
        quantityMilliunits,
        'quantityMilliunits',
        'Quantity must be greater than zero.',
      );
    }

    if (type.isTransfer) {
      throw ArgumentError('Use transferStock() for branch transfers.');
    }

    if (unitCostPaisa != null && unitCostPaisa < 0) {
      throw ArgumentError.value(
        unitCostPaisa,
        'unitCostPaisa',
        'Unit cost cannot be negative.',
      );
    }

    await _database.transaction(() async {
      await _getActiveBranch(businessId, branchId);
      final variant = await _getActiveVariant(businessId, variantId);

      await _validateUser(businessId, createdByUserId);

      if (!variant.trackStock) {
        return;
      }

      final delta = type.increasesStock
          ? quantityMilliunits
          : -quantityMilliunits;

      await _applyStockDelta(
        businessId: businessId,
        branchId: branchId,
        variantId: variant.id,
        delta: delta,
      );

      await _database
          .into(_database.stockMovements)
          .insert(
            StockMovementsCompanion.insert(
              id: _newId('movement'),
              businessId: businessId,
              branchId: branchId,
              variantId: variantId,
              movementType: type.databaseValue,
              quantityDeltaMilliunits: delta,
              unitCostPaisa: Value(unitCostPaisa),
              referenceType: Value(referenceType),
              referenceId: Value(referenceId),
              note: Value(note),
              createdByUserId: Value(createdByUserId),
              createdAt: DateTime.now(),
            ),
          );
    });
  }

  Future<void> transferStock({
    required String businessId,
    required String sourceBranchId,
    required String destinationBranchId,
    required String variantId,
    required int quantityMilliunits,
    String? note,
    String? createdByUserId,
  }) async {
    if (quantityMilliunits <= 0) {
      throw ArgumentError.value(
        quantityMilliunits,
        'quantityMilliunits',
        'Transfer quantity must be greater than zero.',
      );
    }

    if (sourceBranchId == destinationBranchId) {
      throw ArgumentError('Source and destination branches must be different.');
    }

    await _database.transaction(() async {
      await _getActiveBranch(businessId, sourceBranchId);
      await _getActiveBranch(businessId, destinationBranchId);

      final variant = await _getActiveVariant(businessId, variantId);

      await _validateUser(businessId, createdByUserId);

      if (!variant.trackStock) {
        return;
      }

      final transferGroupId = _newId('transfer');
      final now = DateTime.now();

      await _applyStockDelta(
        businessId: businessId,
        branchId: sourceBranchId,
        variantId: variantId,
        delta: -quantityMilliunits,
      );

      await _applyStockDelta(
        businessId: businessId,
        branchId: destinationBranchId,
        variantId: variantId,
        delta: quantityMilliunits,
      );

      await _database
          .into(_database.stockMovements)
          .insert(
            StockMovementsCompanion.insert(
              id: _newId('movement'),
              businessId: businessId,
              branchId: sourceBranchId,
              variantId: variantId,
              movementType: StockMovementType.transferOut.databaseValue,
              quantityDeltaMilliunits: -quantityMilliunits,
              transferGroupId: Value(transferGroupId),
              note: Value(note),
              createdByUserId: Value(createdByUserId),
              createdAt: now,
            ),
          );

      await _database
          .into(_database.stockMovements)
          .insert(
            StockMovementsCompanion.insert(
              id: _newId('movement'),
              businessId: businessId,
              branchId: destinationBranchId,
              variantId: variantId,
              movementType: StockMovementType.transferIn.databaseValue,
              quantityDeltaMilliunits: quantityMilliunits,
              transferGroupId: Value(transferGroupId),
              note: Value(note),
              createdByUserId: Value(createdByUserId),
              createdAt: now,
            ),
          );
    });
  }

  Future<void> _getActiveBranch(String businessId, String branchId) async {
    final branch =
        await (_database.select(_database.branches)..where(
              (table) =>
                  table.id.equals(branchId) &
                  table.businessId.equals(businessId),
            ))
            .getSingleOrNull();

    if (branch == null || !branch.isActive) {
      throw StateError(
        'Branch does not exist, is inactive, or belongs to another business.',
      );
    }
  }

  Future<ProductVariant> _getActiveVariant(
    String businessId,
    String variantId,
  ) async {
    final variant =
        await (_database.select(_database.productVariants)..where(
              (table) =>
                  table.id.equals(variantId) &
                  table.businessId.equals(businessId),
            ))
            .getSingleOrNull();

    if (variant == null || !variant.isActive) {
      throw StateError(
        'Product variant does not exist, is inactive, or belongs to another business.',
      );
    }

    final product =
        await (_database.select(_database.products)..where(
              (table) =>
                  table.id.equals(variant.productId) &
                  table.businessId.equals(businessId),
            ))
            .getSingleOrNull();

    if (product == null || !product.isActive) {
      throw StateError(
        'Parent product does not exist, is inactive, or belongs to another business.',
      );
    }

    return variant;
  }

  Future<void> _validateUser(String businessId, String? userId) async {
    if (userId == null) {
      return;
    }

    final user =
        await (_database.select(_database.users)..where(
              (table) =>
                  table.id.equals(userId) & table.businessId.equals(businessId),
            ))
            .getSingleOrNull();

    if (user == null || !user.isActive) {
      throw StateError(
        'User does not exist, is inactive, or belongs to another business.',
      );
    }
  }

  Future<void> _applyStockDelta({
    required String businessId,
    required String branchId,
    required String variantId,
    required int delta,
  }) async {
    final existingStock =
        await (_database.select(_database.branchStocks)..where(
              (table) =>
                  table.businessId.equals(businessId) &
                  table.branchId.equals(branchId) &
                  table.variantId.equals(variantId),
            ))
            .getSingleOrNull();

    final currentQuantity = existingStock?.quantityMilliunits ?? 0;
    final newQuantity = currentQuantity + delta;

    if (newQuantity < 0) {
      throw StateError(
        'Insufficient stock. Available: $currentQuantity, requested: ${-delta}.',
      );
    }

    final now = DateTime.now();

    if (existingStock == null) {
      await _database
          .into(_database.branchStocks)
          .insert(
            BranchStocksCompanion.insert(
              id: _newId('stock'),
              businessId: businessId,
              branchId: branchId,
              variantId: variantId,
              quantityMilliunits: Value(newQuantity),
              updatedAt: now,
            ),
          );
    } else {
      await (_database.update(
        _database.branchStocks,
      )..where((table) => table.id.equals(existingStock.id))).write(
        BranchStocksCompanion(
          quantityMilliunits: Value(newQuantity),
          updatedAt: Value(now),
        ),
      );
    }
  }
}
