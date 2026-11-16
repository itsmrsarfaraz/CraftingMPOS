import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:crafting_mpos/core/database/app_database.dart';
import 'package:crafting_mpos/features/inventory/models/stock_movement_type.dart';
import 'package:crafting_mpos/features/inventory/services/stock_management_service.dart';

void main() {
  late AppDatabase database;
  late StockManagementService service;

  const businessId = 'business-001';
  const branchId = 'branch-001';
  const secondBranchId = 'branch-002';
  const variantId = 'variant-001';

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    service = StockManagementService(database);
  });

  tearDown(() async {
    await database.close();
  });

  Future<void> createFixture({bool trackStock = true}) async {
    final now = DateTime.now();

    await database.createBusinessSettings(
      BusinessSettingsCompanion.insert(
        id: businessId,
        businessName: 'Test Business',
        createdAt: now,
        updatedAt: now,
      ),
    );

    await database.createCategory(
      CategoriesCompanion.insert(
        id: 'category-001',
        businessId: businessId,
        name: 'General',
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
            categoryId: const Value('category-001'),
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
            trackStock: Value(trackStock),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<int> getStock(String branch) async {
    final stock =
        await (database.select(database.branchStocks)..where(
              (table) =>
                  table.businessId.equals(businessId) &
                  table.branchId.equals(branch) &
                  table.variantId.equals(variantId),
            ))
            .getSingleOrNull();

    return stock?.quantityMilliunits ?? 0;
  }

  Future<int> getMovementCount() async {
    final movements = await database.select(database.stockMovements).get();
    return movements.length;
  }

  group('Stock Management Service', () {
    test('Stock increase creates balance and ledger entry', () async {
      await createFixture();

      await service.recordMovement(
        businessId: businessId,
        branchId: branchId,
        variantId: variantId,
        type: StockMovementType.opening,
        quantityMilliunits: 10000,
        unitCostPaisa: 10000,
      );

      expect(await getStock(branchId), 10000);
      expect(await getMovementCount(), 1);

      final movement =
          (await database.select(database.stockMovements).get()).single;

      expect(movement.movementType, 'opening');
      expect(movement.quantityDeltaMilliunits, 10000);
    });

    test('Stock decrease reduces balance and records sale', () async {
      await createFixture();

      await service.recordMovement(
        businessId: businessId,
        branchId: branchId,
        variantId: variantId,
        type: StockMovementType.opening,
        quantityMilliunits: 10000,
      );

      await service.recordMovement(
        businessId: businessId,
        branchId: branchId,
        variantId: variantId,
        type: StockMovementType.sale,
        quantityMilliunits: 3000,
      );

      expect(await getStock(branchId), 7000);
      expect(await getMovementCount(), 2);

      final movements = await database.select(database.stockMovements).get();

      expect(
        movements.map((movement) => movement.quantityDeltaMilliunits),
        containsAll([10000, -3000]),
      );
    });

    test('Insufficient stock is rejected without changing data', () async {
      await createFixture();

      await service.recordMovement(
        businessId: businessId,
        branchId: branchId,
        variantId: variantId,
        type: StockMovementType.opening,
        quantityMilliunits: 5000,
      );

      await expectLater(
        service.recordMovement(
          businessId: businessId,
          branchId: branchId,
          variantId: variantId,
          type: StockMovementType.sale,
          quantityMilliunits: 6000,
        ),
        throwsA(isA<StateError>()),
      );

      expect(await getStock(branchId), 5000);
      expect(await getMovementCount(), 1);
    });

    test('Branch transfer updates both balances and links movements', () async {
      await createFixture();

      await service.recordMovement(
        businessId: businessId,
        branchId: branchId,
        variantId: variantId,
        type: StockMovementType.opening,
        quantityMilliunits: 10000,
      );

      await service.transferStock(
        businessId: businessId,
        sourceBranchId: branchId,
        destinationBranchId: secondBranchId,
        variantId: variantId,
        quantityMilliunits: 3000,
        note: 'Branch replenishment',
      );

      expect(await getStock(branchId), 7000);
      expect(await getStock(secondBranchId), 3000);
      expect(await getMovementCount(), 3);

      final movements = await database.select(database.stockMovements).get();

      final transferMovements = movements
          .where((movement) => movement.transferGroupId != null)
          .toList();

      expect(transferMovements, hasLength(2));

      expect(
        transferMovements.map((movement) => movement.movementType),
        containsAll(['transfer_out', 'transfer_in']),
      );

      expect(
        transferMovements.map((movement) => movement.quantityDeltaMilliunits),
        containsAll([-3000, 3000]),
      );

      expect(
        transferMovements.first.transferGroupId,
        transferMovements.last.transferGroupId,
      );
    });

    test('Failed transfer rolls back both branches and ledger', () async {
      await createFixture();

      await expectLater(
        service.transferStock(
          businessId: businessId,
          sourceBranchId: branchId,
          destinationBranchId: secondBranchId,
          variantId: variantId,
          quantityMilliunits: 3000,
        ),
        throwsA(isA<StateError>()),
      );

      expect(await getStock(branchId), 0);
      expect(await getStock(secondBranchId), 0);
      expect(await getMovementCount(), 0);
    });

    test('Untracked variant creates no stock or movement records', () async {
      await createFixture(trackStock: false);

      await service.recordMovement(
        businessId: businessId,
        branchId: branchId,
        variantId: variantId,
        type: StockMovementType.opening,
        quantityMilliunits: 10000,
      );

      expect(await getStock(branchId), 0);
      expect(await getMovementCount(), 0);
    });

    test('Transfer between the same branch is rejected', () async {
      await createFixture();

      await expectLater(
        service.transferStock(
          businessId: businessId,
          sourceBranchId: branchId,
          destinationBranchId: branchId,
          variantId: variantId,
          quantityMilliunits: 1000,
        ),
        throwsA(isA<ArgumentError>()),
      );

      expect(await getMovementCount(), 0);
    });

    test('Zero movement quantity is rejected', () async {
      await createFixture();

      await expectLater(
        service.recordMovement(
          businessId: businessId,
          branchId: branchId,
          variantId: variantId,
          type: StockMovementType.opening,
          quantityMilliunits: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );

      expect(await getMovementCount(), 0);
    });

    test('Inactive parent product rejects stock movement', () async {
      await createFixture();

      await (database.update(database.products)
            ..where((table) => table.id.equals('product-001')))
          .write(const ProductsCompanion(isActive: Value(false)));

      await expectLater(
        service.recordMovement(
          businessId: businessId,
          branchId: branchId,
          variantId: variantId,
          type: StockMovementType.opening,
          quantityMilliunits: 5000,
        ),
        throwsA(isA<StateError>()),
      );

      expect(await getStock(branchId), 0);
      expect(await getMovementCount(), 0);
    });
  });
}
