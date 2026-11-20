import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:crafting_mpos/core/database/app_database.dart';
import 'package:crafting_mpos/features/products/services/product_service.dart';
import 'package:crafting_mpos/features/products/models/product_details.dart';
import 'package:crafting_mpos/features/products/models/product_list_item.dart';

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
    String name = 'General',
    bool isActive = true,
  }) async {
    final now = DateTime.now();

    await database.createCategory(
      CategoriesCompanion.insert(
        id: id,
        businessId: ownerBusinessId,
        name: name,
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

    group('createVariant', () {
      test('Creates an additional variant for an active product', () async {
        await createFixture();

        final productId = await service.createProduct(
          businessId: businessId,
          name: 'Mineral Water',
          variantName: '500 ml',
          costPrice: 3000,
          sellingPrice: 4000,
        );

        final variantId = await service.createVariant(
          businessId: businessId,
          productId: productId,
          name: '1 Litre',
          sku: 'WATER-001',
          attributes: '{"size":"1 litre"}',
          costPrice: 5000,
          sellingPrice: 7000,
          unit: 'bottle',
          trackStock: false,
        );

        final variant = await (database.select(
          database.productVariants,
        )..where((table) => table.id.equals(variantId))).getSingle();

        expect(variantId, startsWith('variant-'));
        expect(variant.businessId, businessId);
        expect(variant.productId, productId);
        expect(variant.name, '1 Litre');
        expect(variant.sku, 'WATER-001');
        expect(variant.attributes, '{"size":"1 litre"}');
        expect(variant.costPrice, 5000);
        expect(variant.sellingPrice, 7000);
        expect(variant.unit, 'bottle');
        expect(variant.trackStock, isFalse);
        expect(variant.isActive, isTrue);
        expect(variant.createdAt, isNotNull);
        expect(variant.updatedAt, isNotNull);

        expect(await productCount(), 1);
        expect(await variantCount(), 2);
      });

      test('Normalizes variant text and empty optional fields', () async {
        await createFixture();

        final productId = await service.createProduct(
          businessId: businessId,
          name: 'Notebook',
          variantName: 'Standard',
          costPrice: 1000,
          sellingPrice: 1500,
        );

        final variantId = await service.createVariant(
          businessId: ' $businessId ',
          productId: ' $productId ',
          name: '  Premium  ',
          sku: '   ',
          attributes: '   ',
          unit: '  pack  ',
          costPrice: 2000,
          sellingPrice: 3000,
        );

        final variant = await (database.select(
          database.productVariants,
        )..where((table) => table.id.equals(variantId))).getSingle();

        expect(variant.name, 'Premium');
        expect(variant.sku, isNull);
        expect(variant.attributes, isNull);
        expect(variant.unit, 'pack');
      });

      test('Rejects a product belonging to another business', () async {
        await createFixture();
        await createBusiness(otherBusinessId);

        final productId = await service.createProduct(
          businessId: businessId,
          name: 'Notebook',
          variantName: 'Standard',
          costPrice: 1000,
          sellingPrice: 1500,
        );

        await expectLater(
          service.createVariant(
            businessId: otherBusinessId,
            productId: productId,
            name: 'Premium',
            costPrice: 2000,
            sellingPrice: 3000,
          ),
          throwsA(isA<StateError>()),
        );

        expect(await variantCount(), 1);
      });

      test('Rejects an unknown product', () async {
        await createBusiness(businessId);

        await expectLater(
          service.createVariant(
            businessId: businessId,
            productId: 'unknown-product',
            name: 'Premium',
            costPrice: 2000,
            sellingPrice: 3000,
          ),
          throwsA(isA<StateError>()),
        );

        expect(await variantCount(), 0);
      });

      test('Rejects adding a variant to an inactive product', () async {
        await createFixture();

        final productId = await service.createProduct(
          businessId: businessId,
          name: 'Notebook',
          variantName: 'Standard',
          costPrice: 1000,
          sellingPrice: 1500,
        );

        await (database.update(database.products)..where(
              (table) =>
                  table.businessId.equals(businessId) &
                  table.id.equals(productId),
            ))
            .write(ProductsCompanion(isActive: const Value(false)));

        await expectLater(
          service.createVariant(
            businessId: businessId,
            productId: productId,
            name: 'Premium',
            costPrice: 2000,
            sellingPrice: 3000,
          ),
          throwsA(isA<StateError>()),
        );

        expect(await variantCount(), 1);
      });

      test('Rejects duplicate SKU within the same business', () async {
        await createFixture();

        final firstProductId = await service.createProduct(
          businessId: businessId,
          name: 'Notebook',
          variantName: 'Standard',
          sku: 'SHARED-SKU',
          costPrice: 1000,
          sellingPrice: 1500,
        );

        final secondProductId = await service.createProduct(
          businessId: businessId,
          name: 'Pen',
          variantName: 'Standard',
          costPrice: 500,
          sellingPrice: 800,
        );

        await expectLater(
          service.createVariant(
            businessId: businessId,
            productId: secondProductId,
            name: 'Premium',
            sku: ' SHARED-SKU ',
            costPrice: 2000,
            sellingPrice: 3000,
          ),
          throwsA(isA<StateError>()),
        );

        expect(await productCount(), 2);
        expect(await variantCount(), 2);
        expect(firstProductId, isNotEmpty);
      });

      test('Allows the same SKU in different businesses', () async {
        await createFixture();
        await createBusiness(otherBusinessId);

        final firstProductId = await service.createProduct(
          businessId: businessId,
          name: 'Notebook',
          variantName: 'Standard',
          sku: 'SHARED-SKU',
          costPrice: 1000,
          sellingPrice: 1500,
        );

        final secondProductId = await service.createProduct(
          businessId: otherBusinessId,
          name: 'Notebook',
          variantName: 'Standard',
          costPrice: 1000,
          sellingPrice: 1500,
        );

        final variantId = await service.createVariant(
          businessId: otherBusinessId,
          productId: secondProductId,
          name: 'Premium',
          sku: 'SHARED-SKU',
          costPrice: 2000,
          sellingPrice: 3000,
        );

        final variant = await (database.select(
          database.productVariants,
        )..where((table) => table.id.equals(variantId))).getSingle();

        expect(variant.businessId, otherBusinessId);
        expect(variant.productId, secondProductId);
        expect(await variantCount(), 3);
        expect(firstProductId, isNotEmpty);
      });

      test('Rejects invalid input before inserting a variant', () async {
        await createFixture();

        final productId = await service.createProduct(
          businessId: businessId,
          name: 'Notebook',
          variantName: 'Standard',
          costPrice: 1000,
          sellingPrice: 1500,
        );

        final invalidCalls = [
          () => service.createVariant(
            businessId: ' ',
            productId: productId,
            name: 'Premium',
            costPrice: 100,
            sellingPrice: 200,
          ),
          () => service.createVariant(
            businessId: businessId,
            productId: ' ',
            name: 'Premium',
            costPrice: 100,
            sellingPrice: 200,
          ),
          () => service.createVariant(
            businessId: businessId,
            productId: productId,
            name: ' ',
            costPrice: 100,
            sellingPrice: 200,
          ),
          () => service.createVariant(
            businessId: businessId,
            productId: productId,
            name: 'Premium',
            unit: ' ',
            costPrice: 100,
            sellingPrice: 200,
          ),
          () => service.createVariant(
            businessId: businessId,
            productId: productId,
            name: 'Premium',
            costPrice: -1,
            sellingPrice: 200,
          ),
          () => service.createVariant(
            businessId: businessId,
            productId: productId,
            name: 'Premium',
            costPrice: 100,
            sellingPrice: -1,
          ),
        ];

        for (final create in invalidCalls) {
          await expectLater(create(), throwsArgumentError);
        }

        expect(await variantCount(), 1);
      });
    });

    group('updateProduct', () {
      test('Updates product information successfully', () async {
        await createFixture();

        final productId = await service.createProduct(
          businessId: businessId,
          name: 'Old Product',
          variantName: 'Standard',
          categoryId: categoryId,
          description: 'Old description',
          costPrice: 5000,
          sellingPrice: 7000,
        );

        final original = await (database.select(
          database.products,
        )..where((table) => table.id.equals(productId))).getSingle();

        final result = await service.updateProduct(
          businessId: businessId,
          productId: productId,
          name: '  Updated Product  ',
          categoryId: categoryId,
          description: '  Updated description  ',
          imagePath: '  images/product.png  ',
        );

        final updated = await (database.select(
          database.products,
        )..where((table) => table.id.equals(productId))).getSingle();

        expect(result, isTrue);
        expect(updated.name, 'Updated Product');
        expect(updated.categoryId, categoryId);
        expect(updated.description, 'Updated description');
        expect(updated.imagePath, 'images/product.png');
        expect(updated.updatedAt.isAfter(original.updatedAt), isTrue);
      });

      test(
        'Clears optional product fields when null or blank is passed',
        () async {
          await createFixture();

          final productId = await service.createProduct(
            businessId: businessId,
            name: 'Product',
            variantName: 'Standard',
            categoryId: categoryId,
            description: 'Description',
            costPrice: 5000,
            sellingPrice: 7000,
          );

          final result = await service.updateProduct(
            businessId: businessId,
            productId: productId,
            name: 'Updated Product',
            categoryId: null,
            description: '  ',
            imagePath: null,
          );

          final updated = await (database.select(
            database.products,
          )..where((table) => table.id.equals(productId))).getSingle();

          expect(result, isTrue);
          expect(updated.categoryId, isNull);
          expect(updated.description, isNull);
          expect(updated.imagePath, isNull);
        },
      );

      test('Returns false for an unknown product', () async {
        await createBusiness(businessId);

        final result = await service.updateProduct(
          businessId: businessId,
          productId: 'unknown-product',
          name: 'Updated Product',
          categoryId: null,
          description: null,
          imagePath: null,
        );

        expect(result, isFalse);
        expect(await productCount(), 0);
      });

      test('Does not update another business product', () async {
        await createFixture();
        await createBusiness(otherBusinessId);

        final productId = await service.createProduct(
          businessId: businessId,
          name: 'Original Product',
          variantName: 'Standard',
          costPrice: 5000,
          sellingPrice: 7000,
        );

        final result = await service.updateProduct(
          businessId: otherBusinessId,
          productId: productId,
          name: 'Unauthorized Update',
          categoryId: null,
          description: null,
          imagePath: null,
        );

        final product = await (database.select(
          database.products,
        )..where((table) => table.id.equals(productId))).getSingle();

        expect(result, isFalse);
        expect(product.name, 'Original Product');
      });

      test('Rejects a category belonging to another business', () async {
        await createFixture();
        await createBusiness(otherBusinessId);

        await createCategory(
          id: 'other-category',
          ownerBusinessId: otherBusinessId,
        );

        final productId = await service.createProduct(
          businessId: businessId,
          name: 'Original Product',
          variantName: 'Standard',
          costPrice: 5000,
          sellingPrice: 7000,
        );

        await expectLater(
          service.updateProduct(
            businessId: businessId,
            productId: productId,
            name: 'Updated Product',
            categoryId: 'other-category',
            description: null,
            imagePath: null,
          ),
          throwsA(isA<StateError>()),
        );

        final product = await (database.select(
          database.products,
        )..where((table) => table.id.equals(productId))).getSingle();

        expect(product.name, 'Original Product');
        expect(product.categoryId, isNull);
      });

      test('Rejects an inactive category', () async {
        await createFixture();

        await database.updateCategory(
          businessId,
          categoryId,
          CategoriesCompanion(isActive: const Value(false)),
        );

        final productId = await service.createProduct(
          businessId: businessId,
          name: 'Original Product',
          variantName: 'Standard',
          costPrice: 5000,
          sellingPrice: 7000,
        );

        await expectLater(
          service.updateProduct(
            businessId: businessId,
            productId: productId,
            name: 'Updated Product',
            categoryId: categoryId,
            description: null,
            imagePath: null,
          ),
          throwsA(isA<StateError>()),
        );
      });

      test(
        'Rejects invalid business ID, product ID, and product name',
        () async {
          await createFixture();

          final productId = await service.createProduct(
            businessId: businessId,
            name: 'Original Product',
            variantName: 'Standard',
            costPrice: 5000,
            sellingPrice: 7000,
          );

          final invalidCalls = [
            () => service.updateProduct(
              businessId: ' ',
              productId: productId,
              name: 'Updated Product',
              categoryId: null,
              description: null,
              imagePath: null,
            ),
            () => service.updateProduct(
              businessId: businessId,
              productId: ' ',
              name: 'Updated Product',
              categoryId: null,
              description: null,
              imagePath: null,
            ),
            () => service.updateProduct(
              businessId: businessId,
              productId: productId,
              name: ' A ',
              categoryId: null,
              description: null,
              imagePath: null,
            ),
            () => service.updateProduct(
              businessId: businessId,
              productId: productId,
              name: ' ',
              categoryId: null,
              description: null,
              imagePath: null,
            ),
          ];

          for (final update in invalidCalls) {
            await expectLater(update(), throwsArgumentError);
          }

          final product = await (database.select(
            database.products,
          )..where((table) => table.id.equals(productId))).getSingle();

          expect(product.name, 'Original Product');
        },
      );

      test('Trims business ID and product ID', () async {
        await createFixture();

        final productId = await service.createProduct(
          businessId: businessId,
          name: 'Original Product',
          variantName: 'Standard',
          costPrice: 5000,
          sellingPrice: 7000,
        );

        final result = await service.updateProduct(
          businessId: ' $businessId ',
          productId: ' $productId ',
          name: 'Updated Product',
          categoryId: null,
          description: null,
          imagePath: null,
        );

        expect(result, isTrue);

        final product = await (database.select(
          database.products,
        )..where((table) => table.id.equals(productId))).getSingle();

        expect(product.name, 'Updated Product');
      });
    });

    group('setProductStatus', () {
      test('Activates an inactive product', () async {
        await createFixture();

        final productId = await service.createProduct(
          businessId: businessId,
          name: 'Test Product',
          variantName: 'Standard',
          costPrice: 5000,
          sellingPrice: 7000,
        );

        await service.setProductStatus(
          businessId: businessId,
          productId: productId,
          isActive: false,
        );

        final result = await service.setProductStatus(
          businessId: businessId,
          productId: productId,
          isActive: true,
        );

        final product = await (database.select(
          database.products,
        )..where((table) => table.id.equals(productId))).getSingle();

        expect(result, isTrue);
        expect(product.isActive, isTrue);
      });

      test('Deactivates an active product', () async {
        await createFixture();

        final productId = await service.createProduct(
          businessId: businessId,
          name: 'Test Product',
          variantName: 'Standard',
          costPrice: 5000,
          sellingPrice: 7000,
        );

        final result = await service.setProductStatus(
          businessId: businessId,
          productId: productId,
          isActive: false,
        );

        final product = await (database.select(
          database.products,
        )..where((table) => table.id.equals(productId))).getSingle();

        expect(result, isTrue);
        expect(product.isActive, isFalse);
      });

      test('Does not update timestamp when status is unchanged', () async {
        await createFixture();

        final productId = await service.createProduct(
          businessId: businessId,
          name: 'Test Product',
          variantName: 'Standard',
          costPrice: 5000,
          sellingPrice: 7000,
        );

        final original = await (database.select(
          database.products,
        )..where((table) => table.id.equals(productId))).getSingle();

        final result = await service.setProductStatus(
          businessId: businessId,
          productId: productId,
          isActive: true,
        );

        final unchanged = await (database.select(
          database.products,
        )..where((table) => table.id.equals(productId))).getSingle();

        expect(result, isTrue);
        expect(unchanged.updatedAt, original.updatedAt);
      });

      test('Returns false for an unknown product', () async {
        await createBusiness(businessId);

        final result = await service.setProductStatus(
          businessId: businessId,
          productId: 'unknown-product',
          isActive: false,
        );

        expect(result, isFalse);
      });

      test('Does not modify another business product', () async {
        await createFixture();
        await createBusiness(otherBusinessId);

        final productId = await service.createProduct(
          businessId: businessId,
          name: 'Original Product',
          variantName: 'Standard',
          costPrice: 5000,
          sellingPrice: 7000,
        );

        final result = await service.setProductStatus(
          businessId: otherBusinessId,
          productId: productId,
          isActive: false,
        );

        final product = await (database.select(
          database.products,
        )..where((table) => table.id.equals(productId))).getSingle();

        expect(result, isFalse);
        expect(product.isActive, isTrue);
      });

      test('Rejects empty business ID and product ID', () async {
        await createFixture();

        final productId = await service.createProduct(
          businessId: businessId,
          name: 'Test Product',
          variantName: 'Standard',
          costPrice: 5000,
          sellingPrice: 7000,
        );

        await expectLater(
          service.setProductStatus(
            businessId: ' ',
            productId: productId,
            isActive: false,
          ),
          throwsArgumentError,
        );

        await expectLater(
          service.setProductStatus(
            businessId: businessId,
            productId: ' ',
            isActive: false,
          ),
          throwsArgumentError,
        );
      });

      test('Preserves product variants when deactivated', () async {
        await createFixture();

        final productId = await service.createProduct(
          businessId: businessId,
          name: 'Test Product',
          variantName: 'Standard',
          costPrice: 5000,
          sellingPrice: 7000,
        );

        final variantsBefore = await variantCount();

        final result = await service.setProductStatus(
          businessId: businessId,
          productId: productId,
          isActive: false,
        );

        final variantsAfter = await variantCount();

        expect(result, isTrue);
        expect(variantsAfter, variantsBefore);
      });
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

    test('Lists active products with their categories by default', () async {
      await createFixture();

      await service.createProduct(
        businessId: businessId,
        name: 'Mineral Water',
        variantName: '1 Litre',
        categoryId: categoryId,
        costPrice: 5000,
        sellingPrice: 7000,
      );

      await service.createProduct(
        businessId: businessId,
        name: 'Notebook',
        variantName: 'Standard',
        costPrice: 10000,
        sellingPrice: 15000,
      );

      final products = await service.getProducts(businessId: businessId);

      expect(products, hasLength(2));
      expect(products, everyElement(isA<ProductListItem>()));

      expect(products.map((item) => item.product.name).toList(), [
        'Mineral Water',
        'Notebook',
      ]);

      expect(products.first.category?.id, categoryId);
      expect(products.last.category, isNull);
      expect(products.every((item) => item.product.isActive), isTrue);
    });

    test('Searches products by name', () async {
      await createFixture();

      await service.createProduct(
        businessId: businessId,
        name: 'Mineral Water',
        variantName: '1 Litre',
        costPrice: 5000,
        sellingPrice: 7000,
      );

      await service.createProduct(
        businessId: businessId,
        name: 'Notebook',
        variantName: 'Standard',
        costPrice: 10000,
        sellingPrice: 15000,
      );

      final products = await service.getProducts(
        businessId: businessId,
        search: 'water',
      );

      expect(products, hasLength(1));
      expect(products.single.product.name, 'Mineral Water');
    });

    test('Searches products by variant SKU without duplicates', () async {
      await createFixture();

      final productId = await service.createProduct(
        businessId: businessId,
        name: 'Mineral Water',
        variantName: '1 Litre',
        sku: 'WATER-1L',
        costPrice: 5000,
        sellingPrice: 7000,
      );

      await database
          .into(database.productVariants)
          .insert(
            ProductVariantsCompanion.insert(
              id: 'variant-water-500ml',
              businessId: businessId,
              productId: productId,
              name: '500 ML',
              sku: const Value('WATER-500ML'),
              costPrice: 3000,
              sellingPrice: 4000,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );

      final products = await service.getProducts(
        businessId: businessId,
        search: 'WATER',
      );

      expect(products, hasLength(1));
      expect(products.single.product.id, productId);
    });

    test('Filters products by category', () async {
      await createFixture();

      await createCategory(
        id: 'category-002',
        ownerBusinessId: businessId,
        name: 'Stationery',
      );

      await service.createProduct(
        businessId: businessId,
        name: 'Mineral Water',
        variantName: '1 Litre',
        categoryId: categoryId,
        costPrice: 5000,
        sellingPrice: 7000,
      );

      await service.createProduct(
        businessId: businessId,
        name: 'Notebook',
        variantName: 'Standard',
        categoryId: 'category-002',
        costPrice: 10000,
        sellingPrice: 15000,
      );

      final products = await service.getProducts(
        businessId: businessId,
        categoryId: categoryId,
      );

      expect(products, hasLength(1));
      expect(products.single.product.name, 'Mineral Water');
      expect(products.single.category?.id, categoryId);
    });

    test('Filters products by active status', () async {
      await createFixture();

      await service.createProduct(
        businessId: businessId,
        name: 'Active Product',
        variantName: 'Standard',
        costPrice: 5000,
        sellingPrice: 7000,
      );

      final inactiveProductId = await service.createProduct(
        businessId: businessId,
        name: 'Inactive Product',
        variantName: 'Standard',
        costPrice: 8000,
        sellingPrice: 10000,
      );

      await (database.update(database.products)
            ..where((table) => table.id.equals(inactiveProductId)))
          .write(const ProductsCompanion(isActive: Value(false)));

      final activeProducts = await service.getProducts(businessId: businessId);

      final inactiveProducts = await service.getProducts(
        businessId: businessId,
        isActive: false,
      );

      final allProducts = await service.getProducts(
        businessId: businessId,
        isActive: null,
      );

      expect(activeProducts, hasLength(1));
      expect(activeProducts.single.product.name, 'Active Product');

      expect(inactiveProducts, hasLength(1));
      expect(inactiveProducts.single.product.name, 'Inactive Product');

      expect(allProducts, hasLength(2));
    });

    test('Does not expose products belonging to another business', () async {
      await createFixture();
      await createBusiness(otherBusinessId);

      await service.createProduct(
        businessId: businessId,
        name: 'Business One Product',
        variantName: 'Standard',
        costPrice: 5000,
        sellingPrice: 7000,
      );

      await service.createProduct(
        businessId: otherBusinessId,
        name: 'Business Two Product',
        variantName: 'Standard',
        costPrice: 8000,
        sellingPrice: 10000,
      );

      final products = await service.getProducts(
        businessId: businessId,
        isActive: null,
      );

      final searchResults = await service.getProducts(
        businessId: businessId,
        search: 'Business Two Product',
        isActive: null,
      );

      expect(products, hasLength(1));
      expect(products.single.product.name, 'Business One Product');

      expect(searchResults, isEmpty);
    });

    test('Paginates products with stable alphabetical sorting', () async {
      await createFixture();

      for (final name in ['Zebra', 'Apple', 'Mango', 'Banana']) {
        await service.createProduct(
          businessId: businessId,
          name: name,
          variantName: 'Standard',
          costPrice: 5000,
          sellingPrice: 7000,
        );
      }

      final firstPage = await service.getProducts(
        businessId: businessId,
        limit: 2,
        offset: 0,
      );

      final secondPage = await service.getProducts(
        businessId: businessId,
        limit: 2,
        offset: 2,
      );

      expect(firstPage.map((item) => item.product.name).toList(), [
        'Apple',
        'Banana',
      ]);

      expect(secondPage.map((item) => item.product.name).toList(), [
        'Mango',
        'Zebra',
      ]);

      final firstPageIds = firstPage.map((item) => item.product.id).toSet();
      final secondPageIds = secondPage.map((item) => item.product.id).toSet();

      expect(firstPageIds.intersection(secondPageIds), isEmpty);
    });

    test('Rejects invalid pagination limits', () async {
      await createFixture();

      await expectLater(
        service.getProducts(businessId: businessId, limit: 0),
        throwsArgumentError,
      );

      await expectLater(
        service.getProducts(businessId: businessId, limit: 101),
        throwsArgumentError,
      );
    });

    test('Rejects negative pagination offsets', () async {
      await createFixture();

      await expectLater(
        service.getProducts(businessId: businessId, offset: -1),
        throwsArgumentError,
      );
    });

    test('Rejects empty or whitespace-only business IDs', () async {
      await expectLater(
        service.getProducts(businessId: ''),
        throwsArgumentError,
      );

      await expectLater(
        service.getProducts(businessId: '   '),
        throwsArgumentError,
      );
    });

    test('Returns an unmodifiable product list', () async {
      await createFixture();

      await service.createProduct(
        businessId: businessId,
        name: 'Test Product',
        variantName: 'Standard',
        costPrice: 5000,
        sellingPrice: 7000,
      );

      final products = await service.getProducts(businessId: businessId);

      expect(products, hasLength(1));

      expect(() => products.clear(), throwsUnsupportedError);
    });

    test('Does not find products through inactive variant SKUs', () async {
      await createFixture();

      final productId = await service.createProduct(
        businessId: businessId,
        name: 'Inactive SKU Product',
        variantName: 'Standard',
        sku: 'OLD-SKU-001',
        costPrice: 5000,
        sellingPrice: 7000,
      );

      await (database.update(database.productVariants)
            ..where((table) => table.productId.equals(productId)))
          .write(const ProductVariantsCompanion(isActive: Value(false)));

      final skuResults = await service.getProducts(
        businessId: businessId,
        search: 'OLD-SKU-001',
      );

      final nameResults = await service.getProducts(
        businessId: businessId,
        search: 'Inactive SKU Product',
      );

      expect(skuResults, isEmpty);
      expect(nameResults, hasLength(1));
    });

    test(
      'Trims business and product IDs when retrieving product details',
      () async {
        await createFixture();

        final productId = await service.createProduct(
          businessId: businessId,
          name: 'Test Product',
          variantName: 'Standard',
          costPrice: 5000,
          sellingPrice: 7000,
        );

        final details = await service.getProductDetails(
          businessId: ' $businessId ',
          productId: ' $productId ',
        );

        expect(details, isNotNull);
        expect(details!.product.id, productId);
      },
    );

    test('Trims business ID when retrieving product listings', () async {
      await createFixture();

      await service.createProduct(
        businessId: businessId,
        name: 'Test Product',
        variantName: 'Standard',
        costPrice: 5000,
        sellingPrice: 7000,
      );

      final products = await service.getProducts(businessId: ' $businessId ');

      expect(products, hasLength(1));
      expect(products.single.product.name, 'Test Product');
    });

    test('Trims business ID when creating a product', () async {
      await createFixture();

      final productId = await service.createProduct(
        businessId: ' $businessId ',
        name: 'Normalized Product',
        variantName: 'Standard',
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
      expect(variant.businessId, businessId);
    });
  });
}
