import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;

import 'package:crafting_mpos/core/database/app_database.dart';
import 'package:crafting_mpos/features/products/services/product_service.dart';
import 'package:crafting_mpos/features/barcode_qr/services/product_code_service.dart';

void main() {
  late AppDatabase database;
  late ProductService productService;
  late ProductCodeService codeService;

  const businessId = 'business-001';
  const otherBusinessId = 'business-002';

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    productService = ProductService(database);
    codeService = ProductCodeService(database);
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

  Future<String> createProduct({
    required String ownerBusinessId,
    required String name,
  }) async {
    return productService.createProduct(
      businessId: ownerBusinessId,
      name: name,
      variantName: 'Default',
      costPrice: 5000,
      sellingPrice: 7000,
    );
  }

  Future<String> createFixture() async {
    await createBusiness(businessId);
    return createProduct(ownerBusinessId: businessId, name: 'Mineral Water');
  }

  Future<String> createOtherBusinessVariant() async {
    await createBusiness(otherBusinessId);
    return createProduct(
      ownerBusinessId: otherBusinessId,
      name: 'Other Product',
    );
  }

  Future<List<ProductCode>> getCodes() {
    return database.select(database.productCodes).get();
  }

  group('ProductCodeService', () {
    test('Registers a code successfully', () async {
      final productId = await createFixture();

      final variants = await productService.getProductVariants(
        businessId: businessId,
        productId: productId,
      );

      final variantId = variants.single.id;

      final codeId = await codeService.createCode(
        businessId: businessId,
        variantId: variantId,
        code: '1234567890123',
      );

      final codes = await getCodes();

      expect(codeId, isNotEmpty);
      expect(codes, hasLength(1));
      expect(codes.single.id, codeId);
      expect(codes.single.businessId, businessId);
      expect(codes.single.variantId, variantId);
      expect(codes.single.code, '1234567890123');
      expect(codes.single.codeType, 'CODE128');
      expect(codes.single.isPrimary, false);
    });

    test('Trims code and normalizes code type', () async {
      final productId = await createFixture();

      final variant = (await productService.getProductVariants(
        businessId: businessId,
        productId: productId,
      )).single;

      await codeService.createCode(
        businessId: ' $businessId ',
        variantId: ' ${variant.id} ',
        code: '  QR-PAYLOAD-001  ',
        codeType: '  qr  ',
      );

      final codes = await getCodes();

      expect(codes.single.businessId, businessId);
      expect(codes.single.variantId, variant.id);
      expect(codes.single.code, 'QR-PAYLOAD-001');
      expect(codes.single.codeType, 'QR');
    });

    test('Rejects an empty business ID', () async {
      final productId = await createFixture();

      final variant = (await productService.getProductVariants(
        businessId: businessId,
        productId: productId,
      )).single;

      expect(
        () => codeService.createCode(
          businessId: ' ',
          variantId: variant.id,
          code: 'CODE-001',
        ),
        throwsArgumentError,
      );
    });

    test('Rejects an empty variant ID', () async {
      await createFixture();

      expect(
        () => codeService.createCode(
          businessId: businessId,
          variantId: ' ',
          code: 'CODE-001',
        ),
        throwsArgumentError,
      );
    });

    test('Rejects an empty code', () async {
      final productId = await createFixture();

      final variant = (await productService.getProductVariants(
        businessId: businessId,
        productId: productId,
      )).single;

      expect(
        () => codeService.createCode(
          businessId: businessId,
          variantId: variant.id,
          code: ' ',
        ),
        throwsArgumentError,
      );
    });

    test('Rejects a code longer than 255 characters', () async {
      final productId = await createFixture();

      final variant = (await productService.getProductVariants(
        businessId: businessId,
        productId: productId,
      )).single;

      expect(
        () => codeService.createCode(
          businessId: businessId,
          variantId: variant.id,
          code: 'A' * 256,
        ),
        throwsArgumentError,
      );
    });

    test('Rejects an empty code type', () async {
      final productId = await createFixture();

      final variant = (await productService.getProductVariants(
        businessId: businessId,
        productId: productId,
      )).single;

      expect(
        () => codeService.createCode(
          businessId: businessId,
          variantId: variant.id,
          code: 'CODE-001',
          codeType: ' ',
        ),
        throwsArgumentError,
      );
    });

    test('Rejects a variant belonging to another business', () async {
      await createFixture();
      final foreignProductId = await createOtherBusinessVariant();

      final foreignVariant = (await productService.getProductVariants(
        businessId: otherBusinessId,
        productId: foreignProductId,
      )).single;

      expect(
        () => codeService.createCode(
          businessId: businessId,
          variantId: foreignVariant.id,
          code: 'CODE-001',
        ),
        throwsStateError,
      );

      expect(await getCodes(), isEmpty);
    });

    test('Rejects a duplicate code within the same business', () async {
      final productId = await createFixture();

      final variant = (await productService.getProductVariants(
        businessId: businessId,
        productId: productId,
      )).single;

      await codeService.createCode(
        businessId: businessId,
        variantId: variant.id,
        code: 'DUPLICATE-001',
      );

      expect(
        () => codeService.createCode(
          businessId: businessId,
          variantId: variant.id,
          code: 'DUPLICATE-001',
        ),
        throwsStateError,
      );

      expect(await getCodes(), hasLength(1));
    });

    test('Allows the same code in different businesses', () async {
      final productId = await createFixture();
      final otherProductId = await createOtherBusinessVariant();

      final variant = (await productService.getProductVariants(
        businessId: businessId,
        productId: productId,
      )).single;

      final otherVariant = (await productService.getProductVariants(
        businessId: otherBusinessId,
        productId: otherProductId,
      )).single;

      await codeService.createCode(
        businessId: businessId,
        variantId: variant.id,
        code: 'SHARED-CODE-001',
      );

      await codeService.createCode(
        businessId: otherBusinessId,
        variantId: otherVariant.id,
        code: 'SHARED-CODE-001',
      );

      expect(await getCodes(), hasLength(2));
    });

    test(
      'Demotes the previous primary code when registering a new one',
      () async {
        final productId = await createFixture();

        final variant = (await productService.getProductVariants(
          businessId: businessId,
          productId: productId,
        )).single;

        await codeService.createCode(
          businessId: businessId,
          variantId: variant.id,
          code: 'PRIMARY-001',
          isPrimary: true,
        );

        await codeService.createCode(
          businessId: businessId,
          variantId: variant.id,
          code: 'PRIMARY-002',
          isPrimary: true,
        );

        final codes = await getCodes();

        expect(codes, hasLength(2));
        expect(codes.where((code) => code.isPrimary).map((code) => code.code), [
          'PRIMARY-002',
        ]);
      },
    );

    test('A non-primary code does not replace the primary code', () async {
      final productId = await createFixture();

      final variant = (await productService.getProductVariants(
        businessId: businessId,
        productId: productId,
      )).single;

      await codeService.createCode(
        businessId: businessId,
        variantId: variant.id,
        code: 'PRIMARY-001',
        isPrimary: true,
      );

      await codeService.createCode(
        businessId: businessId,
        variantId: variant.id,
        code: 'SECONDARY-001',
      );

      final codes = await getCodes();

      expect(codes.where((code) => code.isPrimary), hasLength(1));
      expect(codes.singleWhere((code) => code.isPrimary).code, 'PRIMARY-001');
    });

    test(
      'Duplicate registration does not remove the existing primary',
      () async {
        final productId = await createFixture();

        final variant = (await productService.getProductVariants(
          businessId: businessId,
          productId: productId,
        )).single;

        await codeService.createCode(
          businessId: businessId,
          variantId: variant.id,
          code: 'PRIMARY-001',
          isPrimary: true,
        );

        await expectLater(
          codeService.createCode(
            businessId: businessId,
            variantId: variant.id,
            code: 'PRIMARY-001',
            isPrimary: true,
          ),
          throwsStateError,
        );

        final codes = await getCodes();

        expect(codes, hasLength(1));
        expect(codes.single.isPrimary, true);
        expect(codes.single.code, 'PRIMARY-001');
      },
    );

    test('Retrieves a code by its exact value', () async {
      final productId = await createFixture();

      final variant = (await productService.getProductVariants(
        businessId: businessId,
        productId: productId,
      )).single;

      final codeId = await codeService.createCode(
        businessId: businessId,
        variantId: variant.id,
        code: 'SCAN-001',
      );

      final result = await codeService.getCodeByValue(
        businessId: businessId,
        code: 'SCAN-001',
      );

      expect(result, isNotNull);
      expect(result!.id, codeId);
      expect(result.code, 'SCAN-001');
      expect(result.businessId, businessId);
      expect(result.variantId, variant.id);
    });

    test('Returns null when the code does not exist', () async {
      await createFixture();

      final result = await codeService.getCodeByValue(
        businessId: businessId,
        code: 'MISSING-001',
      );

      expect(result, isNull);
    });

    test('Does not retrieve a code belonging to another business', () async {
      await createFixture();
      final otherProductId = await createOtherBusinessVariant();

      final otherVariant = (await productService.getProductVariants(
        businessId: otherBusinessId,
        productId: otherProductId,
      )).single;

      await codeService.createCode(
        businessId: otherBusinessId,
        variantId: otherVariant.id,
        code: 'PRIVATE-CODE-001',
      );

      final result = await codeService.getCodeByValue(
        businessId: businessId,
        code: 'PRIVATE-CODE-001',
      );

      expect(result, isNull);
    });

    test('Trims business ID and code before lookup', () async {
      final productId = await createFixture();

      final variant = (await productService.getProductVariants(
        businessId: businessId,
        productId: productId,
      )).single;

      await codeService.createCode(
        businessId: businessId,
        variantId: variant.id,
        code: 'TRIM-001',
      );

      final result = await codeService.getCodeByValue(
        businessId: ' $businessId ',
        code: ' TRIM-001 ',
      );

      expect(result, isNotNull);
      expect(result!.code, 'TRIM-001');
    });

    test('Rejects an empty business ID during lookup', () async {
      expect(
        () => codeService.getCodeByValue(businessId: ' ', code: 'SCAN-001'),
        throwsArgumentError,
      );
    });

    test('Rejects an empty code during lookup', () async {
      expect(
        () => codeService.getCodeByValue(businessId: businessId, code: ' '),
        throwsArgumentError,
      );
    });

    test('Retrieves all codes for a variant with primary code first', () async {
      final productId = await createFixture();

      final variant = (await productService.getProductVariants(
        businessId: businessId,
        productId: productId,
      )).single;

      await codeService.createCode(
        businessId: businessId,
        variantId: variant.id,
        code: 'SECONDARY-NEWER',
      );

      await codeService.createCode(
        businessId: businessId,
        variantId: variant.id,
        code: 'PRIMARY-001',
        isPrimary: true,
      );

      await codeService.createCode(
        businessId: businessId,
        variantId: variant.id,
        code: 'SECONDARY-OLDER',
      );

      final now = DateTime.now();

      await (database.update(
        database.productCodes,
      )..where((table) => table.code.equals('SECONDARY-NEWER'))).write(
        ProductCodesCompanion(
          createdAt: Value(now.add(const Duration(seconds: 2))),
        ),
      );

      await (database.update(database.productCodes)
            ..where((table) => table.code.equals('SECONDARY-OLDER')))
          .write(ProductCodesCompanion(createdAt: Value(now)));

      final codes = await codeService.getVariantCodes(
        businessId: businessId,
        variantId: variant.id,
      );

      expect(codes, hasLength(3));
      expect(codes.map((code) => code.code).toList(), [
        'PRIMARY-001',
        'SECONDARY-OLDER',
        'SECONDARY-NEWER',
      ]);
      expect(codes.first.isPrimary, true);
    });

    test('Retrieves only codes belonging to the requested variant', () async {
      final firstProductId = await createFixture();

      final secondProductId = await productService.createProduct(
        businessId: businessId,
        name: 'Cooking Oil',
        variantName: '1 Litre',
        costPrice: 10000,
        sellingPrice: 12000,
      );

      final firstVariant = (await productService.getProductVariants(
        businessId: businessId,
        productId: firstProductId,
      )).single;

      final secondVariant = (await productService.getProductVariants(
        businessId: businessId,
        productId: secondProductId,
      )).single;

      await codeService.createCode(
        businessId: businessId,
        variantId: firstVariant.id,
        code: 'WATER-001',
      );

      await codeService.createCode(
        businessId: businessId,
        variantId: secondVariant.id,
        code: 'OIL-001',
      );

      final codes = await codeService.getVariantCodes(
        businessId: businessId,
        variantId: firstVariant.id,
      );

      expect(codes, hasLength(1));
      expect(codes.single.code, 'WATER-001');
    });

    test('Does not retrieve codes belonging to another business', () async {
      await createFixture();
      final otherProductId = await createOtherBusinessVariant();

      final otherVariant = (await productService.getProductVariants(
        businessId: otherBusinessId,
        productId: otherProductId,
      )).single;

      await codeService.createCode(
        businessId: otherBusinessId,
        variantId: otherVariant.id,
        code: 'PRIVATE-001',
      );

      final codes = await codeService.getVariantCodes(
        businessId: businessId,
        variantId: otherVariant.id,
      );

      expect(codes, isEmpty);
    });

    test('Returns an empty list when a variant has no codes', () async {
      final productId = await createFixture();

      final variant = (await productService.getProductVariants(
        businessId: businessId,
        productId: productId,
      )).single;

      final codes = await codeService.getVariantCodes(
        businessId: businessId,
        variantId: variant.id,
      );

      expect(codes, isEmpty);
    });

    test('Returns an immutable list', () async {
      final productId = await createFixture();

      final variant = (await productService.getProductVariants(
        businessId: businessId,
        productId: productId,
      )).single;

      await codeService.createCode(
        businessId: businessId,
        variantId: variant.id,
        code: 'IMMUTABLE-001',
      );

      final codes = await codeService.getVariantCodes(
        businessId: businessId,
        variantId: variant.id,
      );

      expect(() => codes.clear(), throwsUnsupportedError);
    });

    test(
      'Rejects an empty business ID during variant code retrieval',
      () async {
        expect(
          () => codeService.getVariantCodes(
            businessId: ' ',
            variantId: 'variant-001',
          ),
          throwsArgumentError,
        );
      },
    );

    test('Rejects an empty variant ID during variant code retrieval', () async {
      expect(
        () =>
            codeService.getVariantCodes(businessId: businessId, variantId: ' '),
        throwsArgumentError,
      );
    });

    test('sets a new primary code and demotes the previous primary', () async {
      final productId = await createFixture();
      final variant = (await productService.getProductVariants(
        businessId: businessId,
        productId: productId,
      )).single;

      final firstId = await codeService.createCode(
        businessId: businessId,
        variantId: variant.id,
        code: 'PRIMARY-001',
        isPrimary: true,
      );

      final secondId = await codeService.createCode(
        businessId: businessId,
        variantId: variant.id,
        code: 'SECONDARY-001',
      );

      final result = await codeService.setPrimaryCode(
        businessId: businessId,
        codeId: secondId,
      );

      final codes = await codeService.getVariantCodes(
        businessId: businessId,
        variantId: variant.id,
      );

      expect(result, isTrue);
      expect(
        codes.singleWhere((code) => code.id == firstId).isPrimary,
        isFalse,
      );
      expect(
        codes.singleWhere((code) => code.id == secondId).isPrimary,
        isTrue,
      );
    });

    test('returns false when the code does not exist', () async {
      final result = await codeService.setPrimaryCode(
        businessId: businessId,
        codeId: 'missing-code',
      );

      expect(result, isFalse);
    });

    test('does not promote a code belonging to another business', () async {
      await createFixture();
      final otherProductId = await createOtherBusinessVariant();
      final otherVariant = (await productService.getProductVariants(
        businessId: otherBusinessId,
        productId: otherProductId,
      )).single;

      final foreignCodeId = await codeService.createCode(
        businessId: otherBusinessId,
        variantId: otherVariant.id,
        code: 'FOREIGN-001',
      );

      final result = await codeService.setPrimaryCode(
        businessId: businessId,
        codeId: foreignCodeId,
      );

      final foreignCode = await codeService.getCodeByValue(
        businessId: otherBusinessId,
        code: 'FOREIGN-001',
      );

      expect(result, isFalse);
      expect(foreignCode!.isPrimary, isFalse);
    });

    test('keeps the current primary code unchanged', () async {
      final productId = await createFixture();
      final variant = (await productService.getProductVariants(
        businessId: businessId,
        productId: productId,
      )).single;

      final primaryId = await codeService.createCode(
        businessId: businessId,
        variantId: variant.id,
        code: 'CURRENT-PRIMARY',
        isPrimary: true,
      );

      final secondaryId = await codeService.createCode(
        businessId: businessId,
        variantId: variant.id,
        code: 'CURRENT-SECONDARY',
      );

      final result = await codeService.setPrimaryCode(
        businessId: businessId,
        codeId: primaryId,
      );

      final codes = await codeService.getVariantCodes(
        businessId: businessId,
        variantId: variant.id,
      );

      expect(result, isTrue);
      expect(
        codes.singleWhere((code) => code.id == primaryId).isPrimary,
        isTrue,
      );
      expect(
        codes.singleWhere((code) => code.id == secondaryId).isPrimary,
        isFalse,
      );
    });

    test('rejects an empty business ID', () async {
      expect(
        () => codeService.setPrimaryCode(businessId: ' ', codeId: 'some-code'),
        throwsArgumentError,
      );
    });

    test('rejects an empty code ID', () async {
      expect(
        () => codeService.setPrimaryCode(businessId: businessId, codeId: ' '),
        throwsArgumentError,
      );
    });

    test('deletes a code successfully', () async {
      final productId = await createFixture();
      final variant = (await productService.getProductVariants(
        businessId: businessId,
        productId: productId,
      )).single;

      final codeId = await codeService.createCode(
        businessId: businessId,
        variantId: variant.id,
        code: 'DELETE-001',
      );

      final result = await codeService.deleteCode(
        businessId: businessId,
        codeId: codeId,
      );

      final deletedCode = await codeService.getCodeByValue(
        businessId: businessId,
        code: 'DELETE-001',
      );

      expect(result, isTrue);
      expect(deletedCode, isNull);
    });

    test('returns false when deleting a missing code', () async {
      await createFixture();

      final result = await codeService.deleteCode(
        businessId: businessId,
        codeId: 'missing-code',
      );

      expect(result, isFalse);
    });

    test('does not delete a code belonging to another business', () async {
      await createFixture();
      final otherProductId = await createOtherBusinessVariant();

      final otherVariant = (await productService.getProductVariants(
        businessId: otherBusinessId,
        productId: otherProductId,
      )).single;

      final foreignCodeId = await codeService.createCode(
        businessId: otherBusinessId,
        variantId: otherVariant.id,
        code: 'FOREIGN-DELETE-001',
      );

      final result = await codeService.deleteCode(
        businessId: businessId,
        codeId: foreignCodeId,
      );

      final foreignCode = await codeService.getCodeByValue(
        businessId: otherBusinessId,
        code: 'FOREIGN-DELETE-001',
      );

      expect(result, isFalse);
      expect(foreignCode, isNotNull);
    });

    test(
      'does not promote another code when deleting the primary code',
      () async {
        final productId = await createFixture();
        final variant = (await productService.getProductVariants(
          businessId: businessId,
          productId: productId,
        )).single;

        final primaryId = await codeService.createCode(
          businessId: businessId,
          variantId: variant.id,
          code: 'PRIMARY-DELETE-001',
          isPrimary: true,
        );

        final secondaryId = await codeService.createCode(
          businessId: businessId,
          variantId: variant.id,
          code: 'SECONDARY-DELETE-001',
        );

        final result = await codeService.deleteCode(
          businessId: businessId,
          codeId: primaryId,
        );

        final remainingCodes = await codeService.getVariantCodes(
          businessId: businessId,
          variantId: variant.id,
        );

        expect(result, isTrue);
        expect(remainingCodes, hasLength(1));
        expect(remainingCodes.single.id, secondaryId);
        expect(remainingCodes.single.isPrimary, isFalse);
      },
    );

    test('rejects an empty business ID when deleting a code', () async {
      expect(
        () => codeService.deleteCode(businessId: ' ', codeId: 'some-code'),
        throwsArgumentError,
      );
    });

    test('rejects an empty code ID when deleting a code', () async {
      expect(
        () => codeService.deleteCode(businessId: businessId, codeId: ' '),
        throwsArgumentError,
      );
    });
  });
}
