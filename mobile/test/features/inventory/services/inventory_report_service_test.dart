import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:crafting_mpos/core/database/app_database.dart';
import 'package:crafting_mpos/features/inventory/models/inventory_stock_status.dart';
import 'package:crafting_mpos/features/inventory/services/inventory_report_service.dart';

void main() {
  late AppDatabase database;
  late InventoryReportService service;

  const businessId = 'business-001';
  const branchId = 'branch-001';
  const secondBranchId = 'branch-002';
  const productId = 'product-001';
  const variantId = 'variant-001';

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    service = InventoryReportService(database);
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
        .into(database.categories)
        .insert(
          CategoriesCompanion.insert(
            id: 'category-001',
            businessId: businessId,
            name: 'Electronics',
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
            productId: productId,
            name: 'Default',
            sku: const Value('SKU-001'),
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
    DateTime? updatedAt,
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
            updatedAt: updatedAt ?? DateTime.now(),
          ),
        );
  }

  group('Inventory Report Service', () {
    test('Returns product and variant details with stock', () async {
      await createFixture();

      final updatedAt = DateTime(2026, 11, 18, 10);
      await createStock(
        branch: branchId,
        quantity: 12500,
        updatedAt: updatedAt,
      );

      final report = await service.getReport(businessId: businessId);

      expect(report, hasLength(1));

      final item = report.single;

      expect(item.productId, productId);
      expect(item.productName, 'Test Product');
      expect(item.variantId, variantId);
      expect(item.variantName, 'Default');
      expect(item.sku, 'SKU-001');
      expect(item.categoryId, 'category-001');
      expect(item.categoryName, 'Electronics');
      expect(item.unit, 'piece');
      expect(item.costPrice, 10000);
      expect(item.sellingPrice, 15000);
      expect(item.trackStock, isTrue);
      expect(item.quantityMilliunits, 12500);
      expect(item.lastStockUpdatedAt, updatedAt);
      expect(item.isInStock, isTrue);
      expect(item.isOutOfStock, isFalse);
      expect(item.isUntracked, isFalse);
    });

    test('Aggregates stock across all business branches', () async {
      await createFixture();

      await createStock(branch: branchId, quantity: 10000);
      await createStock(branch: secondBranchId, quantity: 20000);

      final report = await service.getReport(businessId: businessId);

      expect(report.single.quantityMilliunits, 30000);
    });

    test('Returns stock for the selected branch only', () async {
      await createFixture();

      await createStock(branch: branchId, quantity: 10000);
      await createStock(branch: secondBranchId, quantity: 20000);

      final report = await service.getReport(
        businessId: businessId,
        branchId: branchId,
      );

      expect(report.single.quantityMilliunits, 10000);
    });

    test('Returns zero quantity when no stock record exists', () async {
      await createFixture();

      final report = await service.getReport(businessId: businessId);

      expect(report.single.quantityMilliunits, 0);
      expect(report.single.lastStockUpdatedAt, isNull);
      expect(report.single.isOutOfStock, isTrue);
    });

    test('Filters tracked variants by stock status', () async {
      await createFixture();

      await database
          .into(database.productVariants)
          .insert(
            ProductVariantsCompanion.insert(
              id: 'variant-untracked',
              businessId: businessId,
              productId: productId,
              name: 'Untracked',
              trackStock: const Value(false),
              costPrice: 5000,
              sellingPrice: 8000,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );

      await database
          .into(database.productVariants)
          .insert(
            ProductVariantsCompanion.insert(
              id: 'variant-in-stock',
              businessId: businessId,
              productId: productId,
              name: 'In Stock',
              costPrice: 5000,
              sellingPrice: 8000,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );

      await createStock(
        branch: branchId,
        quantity: 10000,
        stockVariantId: 'variant-in-stock',
      );

      final all = await service.getReport(businessId: businessId);

      final inStock = await service.getReport(
        businessId: businessId,
        stockStatus: InventoryStockStatus.inStock,
      );

      final outOfStock = await service.getReport(
        businessId: businessId,
        stockStatus: InventoryStockStatus.outOfStock,
      );

      final untracked = await service.getReport(
        businessId: businessId,
        stockStatus: InventoryStockStatus.untracked,
      );

      expect(all, hasLength(3));
      expect(inStock.map((item) => item.variantId), ['variant-in-stock']);
      expect(outOfStock.map((item) => item.variantId), [variantId]);
      expect(untracked.map((item) => item.variantId), ['variant-untracked']);
    });

    test('Rejects invalid pagination arguments', () async {
      await createFixture();

      expect(
        () => service.getReport(businessId: businessId, limit: 0),
        throwsArgumentError,
      );

      expect(
        () => service.getReport(businessId: businessId, offset: -1),
        throwsArgumentError,
      );
    });

    test('Searches product names case-insensitively', () async {
      await createFixture();

      final report = await service.getReport(
        businessId: businessId,
        searchQuery: 'test pro',
      );

      expect(report, hasLength(1));
      expect(report.single.productName, 'Test Product');
    });

    test('Searches variant SKUs case-insensitively', () async {
      await createFixture();

      final report = await service.getReport(
        businessId: businessId,
        searchQuery: 'sku-001',
      );

      expect(report, hasLength(1));
      expect(report.single.sku, 'SKU-001');
    });

    test('Filters by category', () async {
      await createFixture();

      await database
          .into(database.categories)
          .insert(
            CategoriesCompanion.insert(
              id: 'category-002',
              businessId: businessId,
              name: 'Furniture',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );

      await database
          .into(database.products)
          .insert(
            ProductsCompanion.insert(
              id: 'product-002',
              businessId: businessId,
              categoryId: const Value('category-002'),
              name: 'Office Chair',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );

      await database
          .into(database.productVariants)
          .insert(
            ProductVariantsCompanion.insert(
              id: 'variant-002',
              businessId: businessId,
              productId: 'product-002',
              name: 'Black',
              costPrice: 20000,
              sellingPrice: 30000,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );

      final report = await service.getReport(
        businessId: businessId,
        categoryId: 'category-002',
      );

      expect(report, hasLength(1));
      expect(report.single.productName, 'Office Chair');
      expect(report.single.categoryName, 'Furniture');
    });

    test('Excludes inactive products and variants', () async {
      await createFixture();

      await database
          .into(database.products)
          .insert(
            ProductsCompanion.insert(
              id: 'product-inactive',
              businessId: businessId,
              name: 'Inactive Product',
              isActive: const Value(false),
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
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
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );

      await database
          .into(database.productVariants)
          .insert(
            ProductVariantsCompanion.insert(
              id: 'variant-inactive',
              businessId: businessId,
              productId: productId,
              name: 'Inactive Variant',
              isActive: const Value(false),
              costPrice: 5000,
              sellingPrice: 8000,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );

      final report = await service.getReport(businessId: businessId);

      expect(report, hasLength(1));
      expect(report.single.variantId, variantId);
    });

    test('Does not return inventory from another business', () async {
      await createFixture();

      await database.createBusinessSettings(
        BusinessSettingsCompanion.insert(
          id: 'business-002',
          businessName: 'Another Business',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      await database.createBranch(
        BranchesCompanion.insert(
          id: 'branch-003',
          businessId: 'business-002',
          name: 'Other Branch',
          code: 'OTHER',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      await database
          .into(database.products)
          .insert(
            ProductsCompanion.insert(
              id: 'product-other',
              businessId: 'business-002',
              name: 'Other Business Product',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );

      await database
          .into(database.productVariants)
          .insert(
            ProductVariantsCompanion.insert(
              id: 'variant-other',
              businessId: 'business-002',
              productId: 'product-other',
              name: 'Other Variant',
              costPrice: 5000,
              sellingPrice: 8000,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );

      final report = await service.getReport(businessId: businessId);

      expect(report, hasLength(1));
      expect(report.single.productId, productId);
    });

    test('Uses latest stock update across selected branches', () async {
      await createFixture();

      final earlier = DateTime(2026, 11, 17, 10);
      final later = DateTime(2026, 11, 18, 10);

      await createStock(branch: branchId, quantity: 10000, updatedAt: earlier);

      await createStock(
        branch: secondBranchId,
        quantity: 20000,
        updatedAt: later,
      );

      final report = await service.getReport(businessId: businessId);

      expect(report.single.lastStockUpdatedAt, later);
    });

    test('Paginates results with stable ordering', () async {
      await createFixture();

      await database
          .into(database.products)
          .insert(
            ProductsCompanion.insert(
              id: 'product-002',
              businessId: businessId,
              name: 'Another Product',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );

      await database
          .into(database.productVariants)
          .insert(
            ProductVariantsCompanion.insert(
              id: 'variant-002',
              businessId: businessId,
              productId: 'product-002',
              name: 'Default',
              costPrice: 5000,
              sellingPrice: 8000,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );

      final firstPage = await service.getReport(
        businessId: businessId,
        limit: 1,
      );

      final secondPage = await service.getReport(
        businessId: businessId,
        limit: 1,
        offset: 1,
      );

      expect(firstPage, hasLength(1));
      expect(secondPage, hasLength(1));
      expect(firstPage.single.productName, 'Another Product');
      expect(secondPage.single.productName, 'Test Product');
    });

    test('Rejects a branch belonging to another business', () async {
      await createFixture();

      await database.createBusinessSettings(
        BusinessSettingsCompanion.insert(
          id: 'business-002',
          businessName: 'Another Business',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      await database.createBranch(
        BranchesCompanion.insert(
          id: 'branch-other',
          businessId: 'business-002',
          name: 'Other Branch',
          code: 'OTHER',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      expect(
        () =>
            service.getReport(businessId: businessId, branchId: 'branch-other'),
        throwsArgumentError,
      );
    });
  });
}
