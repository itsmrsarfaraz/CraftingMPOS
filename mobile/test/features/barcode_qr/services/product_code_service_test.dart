import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

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
  });
}
