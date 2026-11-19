import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:crafting_mpos/core/database/app_database.dart';
import 'package:crafting_mpos/features/products/services/product_service.dart';
import 'package:crafting_mpos/features/products/models/product_details.dart';

void main() {
  late AppDatabase database;
  late ProductService service;

  const businessId = 'business-001';
  const otherBusinessId = 'business-002';
  const categoryId = 'category-001';

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    service = ProductService(database);
  });

  tearDown(() async {
    await database.close();
  });

  Future<void> createBusiness(String id) async {
    final now = DateTime.now();

    await database.createBusinessSettings(
      BusinessSettingsCompanion.insert(
        id: id,
        businessName: 'Test Business $id',
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> createCategory({
    required String id,
    required String ownerBusinessId,
    bool isActive = true,
  }) async {
    final now = DateTime.now();

    await database.createCategory(
      CategoriesCompanion.insert(
        id: id,
        businessId: ownerBusinessId,
        name: 'General',
        isActive: Value(isActive),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> createFixture() async {
    await createBusiness(businessId);
    await createCategory(id: categoryId, ownerBusinessId: businessId);
  }

  Future<int> productCount() async {
    final products = await database.select(database.products).get();
    return products.length;
  }

  Future<int> variantCount() async {
    final variants = await database.select(database.productVariants).get();
    return variants.length;
  }

  group('ProductService', () {
    test('Creates product and initial variant successfully', () async {
      await createFixture();

      final productId = await service.createProduct(
        businessId: businessId,
        name: '  Mineral Water  ',
        variantName: '  1 Litre  ',
        categoryId: categoryId,
        description: '  Drinking water  ',
        sku: '  WATER-001  ',
        costPrice: 5000,
        sellingPrice: 7000,
      );

      final product = await (database.select(
        database.products,
      )..where((table) => table.id.equals(productId))).getSingle();

      final variant = await (database.select(
        database.productVariants,
      )..where((table) => table.productId.equals(productId))).getSingle();

      expect(product.businessId, businessId);
      expect(product.name, 'Mineral Water');
      expect(product.categoryId, categoryId);
      expect(product.description, 'Drinking water');
      expect(product.isActive, isTrue);

      expect(variant.businessId, businessId);
      expect(variant.name, '1 Litre');
      expect(variant.sku, 'WATER-001');
      expect(variant.costPrice, 5000);
      expect(variant.sellingPrice, 7000);
      expect(variant.unit, 'piece');
      expect(variant.trackStock, isTrue);
      expect(variant.isActive, isTrue);

      expect(await productCount(), 1);
      expect(await variantCount(), 1);
    });

    test('Creates product without optional category and text fields', () async {
      await createBusiness(businessId);

      final productId = await service.createProduct(
        businessId: businessId,
        name: 'Notebook',
        variantName: 'Standard',
        costPrice: 10000,
        sellingPrice: 15000,
      );

      final product = await (database.select(
        database.products,
      )..where((table) => table.id.equals(productId))).getSingle();

      final variant = await (database.select(
        database.productVariants,
      )..where((table) => table.productId.equals(productId))).getSingle();

      expect(product.categoryId, isNull);
      expect(product.description, isNull);
      expect(product.imagePath, isNull);
      expect(variant.sku, isNull);
      expect(variant.unit, 'piece');
    });

    test('Rejects a category belonging to another business', () async {
      await createBusiness(businessId);
      await createBusiness(otherBusinessId);

      await createCategory(id: categoryId, ownerBusinessId: otherBusinessId);

      await expectLater(
        service.createProduct(
          businessId: businessId,
          name: 'Notebook',
          variantName: 'Standard',
          categoryId: categoryId,
          costPrice: 10000,
          sellingPrice: 15000,
        ),
        throwsA(isA<StateError>()),
      );

      expect(await productCount(), 0);
      expect(await variantCount(), 0);
    });

    test('Rejects an inactive category', () async {
      await createFixture();

      await database.updateCategory(
        businessId,
        categoryId,
        CategoriesCompanion(isActive: const Value(false)),
      );

      await expectLater(
        service.createProduct(
          businessId: businessId,
          name: 'Notebook',
          variantName: 'Standard',
          categoryId: categoryId,
          costPrice: 10000,
          sellingPrice: 15000,
        ),
        throwsA(isA<StateError>()),
      );

      expect(await productCount(), 0);
      expect(await variantCount(), 0);
    });

    test('Rejects an unknown business', () async {
      await expectLater(
        service.createProduct(
          businessId: businessId,
          name: 'Notebook',
          variantName: 'Standard',
          costPrice: 10000,
          sellingPrice: 15000,
        ),
        throwsA(isA<StateError>()),
      );

      expect(await productCount(), 0);
      expect(await variantCount(), 0);
    });

    test('Rejects invalid names and prices before insertion', () async {
      await createBusiness(businessId);

      final invalidCalls = [
        () => service.createProduct(
          businessId: businessId,
          name: 'A',
          variantName: 'Standard',
          costPrice: 100,
          sellingPrice: 200,
        ),
        () => service.createProduct(
          businessId: businessId,
          name: 'Notebook',
          variantName: ' ',
          costPrice: 100,
          sellingPrice: 200,
        ),
        () => service.createProduct(
          businessId: businessId,
          name: 'Notebook',
          variantName: 'Standard',
          costPrice: -1,
          sellingPrice: 200,
        ),
        () => service.createProduct(
          businessId: businessId,
          name: 'Notebook',
          variantName: 'Standard',
          costPrice: 100,
          sellingPrice: -1,
        ),
      ];

      for (final create in invalidCalls) {
        await expectLater(create(), throwsArgumentError);
      }

      expect(await productCount(), 0);
      expect(await variantCount(), 0);
    });

    test('Rolls back product when initial variant insertion fails', () async {
      await createFixture();

      // Create an existing variant with a SKU that will conflict.
      final now = DateTime.now();

      await database
          .into(database.products)
          .insert(
            ProductsCompanion.insert(
              id: 'existing-product',
              businessId: businessId,
              name: 'Existing Product',
              createdAt: now,
              updatedAt: now,
            ),
          );

      await database
          .into(database.productVariants)
          .insert(
            ProductVariantsCompanion.insert(
              id: 'existing-variant',
              businessId: businessId,
              productId: 'existing-product',
              name: 'Standard',
              sku: const Value('DUPLICATE-SKU'),
              costPrice: 1000,
              sellingPrice: 2000,
              createdAt: now,
              updatedAt: now,
            ),
          );

      expect(await productCount(), 1);
      expect(await variantCount(), 1);

      await expectLater(
        service.createProduct(
          businessId: businessId,
          name: 'New Product',
          variantName: 'Standard',
          sku: 'DUPLICATE-SKU',
          costPrice: 3000,
          sellingPrice: 4000,
        ),
        throwsA(anything),
      );

      // The failed transaction must not leave an orphaned product.
      expect(await productCount(), 1);
      expect(await variantCount(), 1);

      final remainingProduct = await (database.select(
        database.products,
      )..where((table) => table.id.equals('existing-product'))).getSingle();

      expect(remainingProduct.name, 'Existing Product');
    });

    test('Retrieves product with category and multiple variants', () async {
      await createFixture();

      final productId = await service.createProduct(
        businessId: businessId,
        name: 'Mineral Water',
        variantName: '500 ml',
        categoryId: categoryId,
        costPrice: 3000,
        sellingPrice: 5000,
      );

      final now = DateTime.now();

      await database
          .into(database.productVariants)
          .insert(
            ProductVariantsCompanion.insert(
              id: 'variant-1-litre',
              businessId: businessId,
              productId: productId,
              name: '1 Litre',
              sku: const Value('WATER-1L'),
              costPrice: 5000,
              sellingPrice: 7000,
              createdAt: now,
              updatedAt: now,
            ),
          );

      final details = await service.getProductDetails(
        businessId: businessId,
        productId: productId,
      );

      expect(details, isA<ProductDetails>());
      expect(details!.product.id, productId);
      expect(details.product.name, 'Mineral Water');
      expect(details.category?.id, categoryId);
      expect(details.category?.name, 'General');

      expect(details.variants, hasLength(2));
      expect(details.variants.map((variant) => variant.name).toList(), [
        '1 Litre',
        '500 ml',
      ]);
      expect(details.variants[0].id, 'variant-1-litre');
      expect(details.variants[1].productId, productId);
    });

    test('Includes inactive variants in product details', () async {
      await createFixture();

      final productId = await service.createProduct(
        businessId: businessId,
        name: 'Notebook',
        variantName: 'Standard',
        costPrice: 10000,
        sellingPrice: 15000,
      );

      final variant = await (database.select(
        database.productVariants,
      )..where((table) => table.productId.equals(productId))).getSingle();

      await (database.update(database.productVariants)
            ..where((table) => table.id.equals(variant.id)))
          .write(const ProductVariantsCompanion(isActive: Value(false)));

      final details = await service.getProductDetails(
        businessId: businessId,
        productId: productId,
      );

      expect(details, isNotNull);
      expect(details!.variants, hasLength(1));
      expect(details.variants.single.isActive, isFalse);
    });

    test('Retrieves product without a category', () async {
      await createBusiness(businessId);

      final productId = await service.createProduct(
        businessId: businessId,
        name: 'Notebook',
        variantName: 'Standard',
        costPrice: 10000,
        sellingPrice: 15000,
      );

      final details = await service.getProductDetails(
        businessId: businessId,
        productId: productId,
      );

      expect(details, isNotNull);
      expect(details!.product.id, productId);
      expect(details.category, isNull);
      expect(details.variants, hasLength(1));
    });

    test('Returns null for an unknown product', () async {
      await createBusiness(businessId);

      final details = await service.getProductDetails(
        businessId: businessId,
        productId: 'unknown-product',
      );

      expect(details, isNull);
    });

    test('Does not expose another business product', () async {
      await createBusiness(businessId);
      await createBusiness(otherBusinessId);

      final productId = await service.createProduct(
        businessId: businessId,
        name: 'Private Product',
        variantName: 'Standard',
        costPrice: 1000,
        sellingPrice: 2000,
      );

      final details = await service.getProductDetails(
        businessId: otherBusinessId,
        productId: productId,
      );

      expect(details, isNull);
    });

    test('Rejects empty business ID and product ID', () async {
      await createBusiness(businessId);

      await expectLater(
        service.getProductDetails(businessId: ' ', productId: 'some-product'),
        throwsArgumentError,
      );

      await expectLater(
        service.getProductDetails(businessId: businessId, productId: ' '),
        throwsArgumentError,
      );
    });

    test('Returns an unmodifiable variants list', () async {
      await createFixture();

      final productId = await service.createProduct(
        businessId: businessId,
        name: 'Notebook',
        variantName: 'Standard',
        costPrice: 10000,
        sellingPrice: 15000,
      );

      final details = await service.getProductDetails(
        businessId: businessId,
        productId: productId,
      );

      expect(
        () => details!.variants.add(details.variants.first),
        throwsUnsupportedError,
      );
    });
  });
}
