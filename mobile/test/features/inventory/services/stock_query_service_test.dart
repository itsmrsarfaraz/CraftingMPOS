import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:crafting_mpos/core/database/app_database.dart';
import 'package:crafting_mpos/features/inventory/services/stock_query_service.dart';

void main() {
  late AppDatabase database;
  late StockQueryService service;

  const businessId = 'business-001';
  const branchId = 'branch-001';
  const secondBranchId = 'branch-002';
  const variantId = 'variant-001';

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    service = StockQueryService(database);
  });

  tearDown(() async {
    await database.close();
  });

  Future<void> createFixture() async {
    final now = DateTime.now();

    await database.createBusinessSettings(
      BusinessSettingsCompanion.insert(
        id: businessId,
        businessName: 'Test Business',
        createdAt: now,
        updatedAt: now,
      ),
    );

    await database.createBranch(
      BranchesCompanion.insert(
        id: branchId,
        businessId: businessId,
        name: 'Main Branch',
        code: 'MAIN',
        createdAt: now,
        updatedAt: now,
      ),
    );

    await database.createBranch(
      BranchesCompanion.insert(
        id: secondBranchId,
        businessId: businessId,
        name: 'Second Branch',
        code: 'SECOND',
        createdAt: now,
        updatedAt: now,
      ),
    );

    await database
        .into(database.products)
        .insert(
          ProductsCompanion.insert(
            id: 'product-001',
            businessId: businessId,
            name: 'Test Product',
            createdAt: now,
            updatedAt: now,
          ),
        );

    await database
        .into(database.productVariants)
        .insert(
          ProductVariantsCompanion.insert(
            id: variantId,
            businessId: businessId,
            productId: 'product-001',
            name: 'Default',
            costPrice: 10000,
            sellingPrice: 15000,
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<void> createStock({
    required String branch,
    required int quantity,
    String stockVariantId = variantId,
  }) async {
    await database
        .into(database.branchStocks)
        .insert(
          BranchStocksCompanion.insert(
            id: 'stock-$branch-$stockVariantId',
            businessId: businessId,
            branchId: branch,
            variantId: stockVariantId,
            quantityMilliunits: Value(quantity),
            updatedAt: DateTime.now(),
          ),
        );
  }

  Future<void> createVariant({
    required String id,
    required int costPrice,
  }) async {
    final now = DateTime.now();

    await database
        .into(database.productVariants)
        .insert(
          ProductVariantsCompanion.insert(
            id: id,
            businessId: businessId,
            productId: 'product-001',
            name: 'Variant $id',
            costPrice: costPrice,
            sellingPrice: costPrice + 5000,
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<void> createMovement({
    required String id,
    required String branch,
    required String movementType,
    required int quantityDelta,
    required DateTime createdAt,
  }) async {
    await database
        .into(database.stockMovements)
        .insert(
          StockMovementsCompanion.insert(
            id: id,
            businessId: businessId,
            branchId: branch,
            variantId: variantId,
            movementType: movementType,
            quantityDeltaMilliunits: quantityDelta,
            createdAt: createdAt,
          ),
        );
  }

  group('Stock Query Service', () {
    test('Returns zero when no stock record exists', () async {
      await createFixture();

      final quantity = await service.getCurrentStock(
        businessId: businessId,
        branchId: branchId,
        variantId: variantId,
      );

      expect(quantity, 0);
    });

    test('Returns the current stock quantity', () async {
      await createFixture();
      await createStock(branch: branchId, quantity: 12500);

      final quantity = await service.getCurrentStock(
        businessId: businessId,
        branchId: branchId,
        variantId: variantId,
      );

      expect(quantity, 12500);
    });

    test('Does not return stock from another branch', () async {
      await createFixture();
      await createStock(branch: branchId, quantity: 5000);
      await createStock(branch: secondBranchId, quantity: 9000);

      final quantity = await service.getCurrentStock(
        businessId: businessId,
        branchId: secondBranchId,
        variantId: variantId,
      );

      expect(quantity, 9000);
    });

    test('Does not return stock from another business', () async {
      await createFixture();

      final now = DateTime.now();

      await database.createBusinessSettings(
        BusinessSettingsCompanion.insert(
          id: 'business-002',
          businessName: 'Another Business',
          createdAt: now,
          updatedAt: now,
        ),
      );

      await database.createBranch(
        BranchesCompanion.insert(
          id: 'branch-003',
          businessId: 'business-002',
          name: 'Other Business Branch',
          code: 'OTHER',
          createdAt: now,
          updatedAt: now,
        ),
      );

      final quantity = await service.getCurrentStock(
        businessId: 'business-002',
        branchId: 'branch-003',
        variantId: variantId,
      );

      expect(quantity, 0);
    });
  });

  group('Stock Movement History', () {
    final oldest = DateTime(2026, 1, 1, 10);
    final middle = DateTime(2026, 1, 2, 10);
    final newest = DateTime(2026, 1, 3, 10);

    test('Returns movement history for a variant', () async {
      await createFixture();

      await createMovement(
        id: 'movement-001',
        branch: branchId,
        movementType: 'opening',
        quantityDelta: 10000,
        createdAt: oldest,
      );

      await createMovement(
        id: 'movement-002',
        branch: branchId,
        movementType: 'purchase',
        quantityDelta: 5000,
        createdAt: middle,
      );

      final movements = await service.getMovementHistory(
        businessId: businessId,
        variantId: variantId,
      );

      expect(movements, hasLength(2));
      expect(
        movements.map((movement) => movement.id),
        containsAll(['movement-001', 'movement-002']),
      );
    });

    test('Filters movement history by branch', () async {
      await createFixture();

      await createMovement(
        id: 'movement-001',
        branch: branchId,
        movementType: 'purchase',
        quantityDelta: 5000,
        createdAt: oldest,
      );

      await createMovement(
        id: 'movement-002',
        branch: secondBranchId,
        movementType: 'purchase',
        quantityDelta: 9000,
        createdAt: middle,
      );

      final movements = await service.getMovementHistory(
        businessId: businessId,
        variantId: variantId,
        branchId: secondBranchId,
      );

      expect(movements, hasLength(1));
      expect(movements.single.id, 'movement-002');
    });

    test('Returns newest movements first', () async {
      await createFixture();

      await createMovement(
        id: 'movement-oldest',
        branch: branchId,
        movementType: 'opening',
        quantityDelta: 1000,
        createdAt: oldest,
      );

      await createMovement(
        id: 'movement-middle',
        branch: branchId,
        movementType: 'purchase',
        quantityDelta: 2000,
        createdAt: middle,
      );

      await createMovement(
        id: 'movement-newest',
        branch: branchId,
        movementType: 'purchase',
        quantityDelta: 3000,
        createdAt: newest,
      );

      final movements = await service.getMovementHistory(
        businessId: businessId,
        variantId: variantId,
      );

      expect(movements.map((movement) => movement.id).toList(), [
        'movement-newest',
        'movement-middle',
        'movement-oldest',
      ]);
    });

    test('Supports limit and offset pagination', () async {
      await createFixture();

      await createMovement(
        id: 'movement-oldest',
        branch: branchId,
        movementType: 'opening',
        quantityDelta: 1000,
        createdAt: oldest,
      );

      await createMovement(
        id: 'movement-middle',
        branch: branchId,
        movementType: 'purchase',
        quantityDelta: 2000,
        createdAt: middle,
      );

      await createMovement(
        id: 'movement-newest',
        branch: branchId,
        movementType: 'purchase',
        quantityDelta: 3000,
        createdAt: newest,
      );

      final movements = await service.getMovementHistory(
        businessId: businessId,
        variantId: variantId,
        limit: 1,
        offset: 1,
      );

      expect(movements, hasLength(1));
      expect(movements.single.id, 'movement-middle');
    });

    test('Rejects invalid pagination values', () async {
      await createFixture();

      expect(
        () => service.getMovementHistory(
          businessId: businessId,
          variantId: variantId,
          limit: 0,
        ),
        throwsArgumentError,
      );

      expect(
        () => service.getMovementHistory(
          businessId: businessId,
          variantId: variantId,
          offset: -1,
        ),
        throwsArgumentError,
      );
    });
  });

  group('Inventory Valuation', () {
    test('Returns zero when inventory is empty', () async {
      await createFixture();

      final valuation = await service.getInventoryValuation(
        businessId: businessId,
      );

      expect(valuation, 0);
    });

    test(
      'Calculates valuation across multiple variants and branches',
      () async {
        await createFixture();

        await createVariant(id: 'variant-002', costPrice: 20000);

        await createStock(branch: branchId, quantity: 1500);

        await createStock(
          branch: secondBranchId,
          quantity: 2500,
          stockVariantId: 'variant-002',
        );

        final valuation = await service.getInventoryValuation(
          businessId: businessId,
        );

        // 1.500 × 10000 + 2.500 × 20000 = 65000 paisa.
        expect(valuation, 65000);
      },
    );

    test('Calculates valuation for a specific branch', () async {
      await createFixture();

      await createVariant(id: 'variant-002', costPrice: 20000);

      await createStock(branch: branchId, quantity: 1500);

      await createStock(
        branch: secondBranchId,
        quantity: 2500,
        stockVariantId: 'variant-002',
      );

      final valuation = await service.getInventoryValuation(
        businessId: businessId,
        branchId: branchId,
      );

      expect(valuation, 15000);
    });

    test('Rounds aggregate fractional paisa correctly', () async {
      await createFixture();

      await database
          .update(database.productVariants)
          .write(const ProductVariantsCompanion(costPrice: Value(500)));

      await createStock(branch: branchId, quantity: 1);

      final valuation = await service.getInventoryValuation(
        businessId: businessId,
      );

      // 500 × 1 / 1000 = 0.5 paisa, rounded to 1 paisa.
      expect(valuation, 1);
    });

    test('Includes inactive variants with existing stock', () async {
      await createFixture();

      await createStock(branch: branchId, quantity: 2000);

      await (database.update(database.productVariants)
            ..where((table) => table.id.equals(variantId)))
          .write(const ProductVariantsCompanion(isActive: Value(false)));

      final valuation = await service.getInventoryValuation(
        businessId: businessId,
      );

      expect(valuation, 20000);
    });

    test('Returns zero for a branch without stock', () async {
      await createFixture();

      await createStock(branch: branchId, quantity: 5000);

      final valuation = await service.getInventoryValuation(
        businessId: businessId,
        branchId: secondBranchId,
      );

      expect(valuation, 0);
    });

    test('Throws when negative stock exists', () async {
      await createFixture();

      await createStock(branch: branchId, quantity: -1000);

      expect(
        () => service.getInventoryValuation(businessId: businessId),
        throwsA(isA<StateError>()),
      );
    });

    test('Throws when inventory valuation exceeds int64 range', () async {
      await createFixture();

      await database
          .update(database.productVariants)
          .write(
            const ProductVariantsCompanion(
              costPrice: Value(9223372036854775807),
            ),
          );

      await createStock(branch: branchId, quantity: 2000);

      expect(
        () => service.getInventoryValuation(businessId: businessId),
        throwsA(isA<StateError>()),
      );
    });

    test('Does not include another business inventory', () async {
      await createFixture();

      await createStock(branch: branchId, quantity: 2000);

      final valuation = await service.getInventoryValuation(
        businessId: 'another-business',
      );

      expect(valuation, 0);
    });
  });
}
