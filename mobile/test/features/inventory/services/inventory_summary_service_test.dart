import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:crafting_mpos/core/database/app_database.dart';
import 'package:crafting_mpos/features/inventory/services/inventory_summary_service.dart';

void main() {
  late AppDatabase database;
  late InventorySummaryService service;

  const businessId = 'business-001';
  const branchId = 'branch-001';
  const secondBranchId = 'branch-002';
  const productId = 'product-001';
  const variantId = 'variant-001';

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    service = InventorySummaryService(database);
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
            id: productId,
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
            productId: productId,
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

  group('Inventory Summary Service', () {
    test('Returns correct summary for a business with stock', () async {
      await createFixture();
      await createStock(branch: branchId, quantity: 12500);

      final summary = await service.getSummary(businessId: businessId);

      expect(summary.totalProducts, 1);
      expect(summary.totalVariants, 1);
      expect(summary.trackedVariants, 1);
      expect(summary.totalStockMilliunits, 12500);
      expect(summary.outOfStockVariants, 0);
      expect(summary.totalValuationPaisa, 125000);
    });

    test('Returns stock and valuation for the selected branch only', () async {
      await createFixture();

      await createStock(branch: branchId, quantity: 10000);

      await createStock(branch: secondBranchId, quantity: 20000);

      final summary = await service.getSummary(
        businessId: businessId,
        branchId: branchId,
      );

      expect(summary.totalProducts, 1);
      expect(summary.totalVariants, 1);
      expect(summary.trackedVariants, 1);
      expect(summary.totalStockMilliunits, 10000);
      expect(summary.outOfStockVariants, 0);
      expect(summary.totalValuationPaisa, 100000);
    });

    test('Excludes inactive products and their variants', () async {
      await createFixture();

      final now = DateTime.now();

      await database
          .into(database.products)
          .insert(
            ProductsCompanion.insert(
              id: 'product-inactive',
              businessId: businessId,
              name: 'Inactive Product',
              isActive: const Value(false),
              createdAt: now,
              updatedAt: now,
            ),
          );

      await database
          .into(database.productVariants)
          .insert(
            ProductVariantsCompanion.insert(
              id: 'variant-inactive-product',
              businessId: businessId,
              productId: 'product-inactive',
              name: 'Inactive Product Variant',
              costPrice: 5000,
              sellingPrice: 8000,
              createdAt: now,
              updatedAt: now,
            ),
          );

      final summary = await service.getSummary(businessId: businessId);

      expect(summary.totalProducts, 1);
      expect(summary.totalVariants, 1);
      expect(summary.trackedVariants, 1);
    });

    test('Excludes inactive variants from summary counts', () async {
      await createFixture();

      await database
          .into(database.productVariants)
          .insert(
            ProductVariantsCompanion.insert(
              id: 'variant-inactive',
              businessId: businessId,
              productId: productId,
              name: 'Inactive Variant',
              costPrice: 5000,
              sellingPrice: 8000,
              isActive: const Value(false),
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );

      final summary = await service.getSummary(businessId: businessId);

      expect(summary.totalProducts, 1);
      expect(summary.totalVariants, 1);
      expect(summary.trackedVariants, 1);
    });

    test('Excludes untracked variants from stock tracking counts', () async {
      await createFixture();

      await database
          .into(database.productVariants)
          .insert(
            ProductVariantsCompanion.insert(
              id: 'variant-untracked',
              businessId: businessId,
              productId: productId,
              name: 'Untracked Variant',
              costPrice: 5000,
              sellingPrice: 8000,
              trackStock: const Value(false),
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );

      final summary = await service.getSummary(businessId: businessId);

      expect(summary.totalVariants, 2);
      expect(summary.trackedVariants, 1);
      expect(summary.outOfStockVariants, 1);
    });

    test(
      'Counts tracked variants without stock records as out of stock',
      () async {
        await createFixture();

        final summary = await service.getSummary(businessId: businessId);

        expect(summary.totalVariants, 1);
        expect(summary.trackedVariants, 1);
        expect(summary.totalStockMilliunits, 0);
        expect(summary.outOfStockVariants, 1);
        expect(summary.totalValuationPaisa, 0);
      },
    );

    test('Does not include another business inventory', () async {
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
          name: 'Other Branch',
          code: 'OTHER',
          createdAt: now,
          updatedAt: now,
        ),
      );

      await database
          .into(database.products)
          .insert(
            ProductsCompanion.insert(
              id: 'product-002',
              businessId: 'business-002',
              name: 'Other Product',
              createdAt: now,
              updatedAt: now,
            ),
          );

      await database
          .into(database.productVariants)
          .insert(
            ProductVariantsCompanion.insert(
              id: 'variant-002',
              businessId: 'business-002',
              productId: 'product-002',
              name: 'Other Variant',
              costPrice: 20000,
              sellingPrice: 25000,
              createdAt: now,
              updatedAt: now,
            ),
          );

      await database
          .into(database.branchStocks)
          .insert(
            BranchStocksCompanion.insert(
              id: 'stock-other-business',
              businessId: 'business-002',
              branchId: 'branch-003',
              variantId: 'variant-002',
              quantityMilliunits: const Value(50000),
              updatedAt: now,
            ),
          );

      final summary = await service.getSummary(businessId: businessId);

      expect(summary.totalProducts, 1);
      expect(summary.totalVariants, 1);
      expect(summary.trackedVariants, 1);
      expect(summary.totalStockMilliunits, 0);
      expect(summary.outOfStockVariants, 1);
      expect(summary.totalValuationPaisa, 0);
    });

    test('Rejects a branch that does not exist', () async {
      await createFixture();

      expect(
        () => service.getSummary(
          businessId: businessId,
          branchId: 'branch-missing',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('Rejects a branch belonging to another business', () async {
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
          id: 'branch-foreign',
          businessId: 'business-002',
          name: 'Foreign Branch',
          code: 'FOREIGN',
          createdAt: now,
          updatedAt: now,
        ),
      );

      expect(
        () => service.getSummary(
          businessId: businessId,
          branchId: 'branch-foreign',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test(
      'Includes inactive variant stock in total stock and valuation',
      () async {
        await createFixture();

        final now = DateTime.now();

        await database
            .into(database.productVariants)
            .insert(
              ProductVariantsCompanion.insert(
                id: 'variant-inactive',
                businessId: businessId,
                productId: productId,
                name: 'Inactive Variant',
                costPrice: 5000,
                sellingPrice: 8000,
                isActive: const Value(false),
                createdAt: now,
                updatedAt: now,
              ),
            );

        await createStock(
          branch: branchId,
          quantity: 20000,
          stockVariantId: 'variant-inactive',
        );

        final summary = await service.getSummary(businessId: businessId);

        expect(summary.totalVariants, 1);
        expect(summary.trackedVariants, 1);
        expect(summary.totalStockMilliunits, 20000);
        expect(summary.outOfStockVariants, 1);
        expect(summary.totalValuationPaisa, 100000);
      },
    );

    test(
      'Includes untracked variant stock in total stock and valuation',
      () async {
        await createFixture();

        final now = DateTime.now();

        await database
            .into(database.productVariants)
            .insert(
              ProductVariantsCompanion.insert(
                id: 'variant-untracked',
                businessId: businessId,
                productId: productId,
                name: 'Untracked Variant',
                costPrice: 5000,
                sellingPrice: 8000,
                trackStock: const Value(false),
                createdAt: now,
                updatedAt: now,
              ),
            );

        await createStock(
          branch: branchId,
          quantity: 30000,
          stockVariantId: 'variant-untracked',
        );

        final summary = await service.getSummary(businessId: businessId);

        expect(summary.totalVariants, 2);
        expect(summary.trackedVariants, 1);
        expect(summary.totalStockMilliunits, 30000);
        expect(summary.outOfStockVariants, 1);
        expect(summary.totalValuationPaisa, 150000);
      },
    );

    test('Allows inventory reporting for inactive branches', () async {
      await createFixture();

      await createStock(branch: branchId, quantity: 10000);

      await (database.update(database.branches)
            ..where((table) => table.id.equals(branchId)))
          .write(const BranchesCompanion(isActive: Value(false)));

      final summary = await service.getSummary(
        businessId: businessId,
        branchId: branchId,
      );

      expect(summary.totalStockMilliunits, 10000);
      expect(summary.totalValuationPaisa, 100000);
      expect(summary.totalProducts, 1);
      expect(summary.totalVariants, 1);
    });
  });
}
