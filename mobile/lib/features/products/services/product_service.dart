import 'dart:math';

import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';

// ignore: unused_import
import '../models/product_details.dart';

class ProductService {
  ProductService(this._database);

  final AppDatabase _database;

  static final Random _random = Random.secure();

  static String _newId(String prefix) {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    final value = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();

    return '$prefix-$value';
  }

  /// Creates a product and its initial variant atomically.
  ///
  /// Returns the newly created product ID.
  Future<String> createProduct({
    required String businessId,
    required String name,
    required String variantName,
    required int costPrice,
    required int sellingPrice,
    String? categoryId,
    String? description,
    String? imagePath,
    String? sku,
    String unit = 'piece',
    bool trackStock = true,
  }) async {
    final normalizedName = name.trim();
    final normalizedVariantName = variantName.trim();
    final normalizedUnit = unit.trim();
    final normalizedSku = _normalizeOptional(sku);
    final normalizedDescription = _normalizeOptional(description);
    final normalizedImagePath = _normalizeOptional(imagePath);

    if (businessId.trim().isEmpty) {
      throw ArgumentError.value(
        businessId,
        'businessId',
        'Business ID cannot be empty.',
      );
    }

    if (normalizedName.length < 2 || normalizedName.length > 150) {
      throw ArgumentError.value(
        name,
        'name',
        'Product name must contain between 2 and 150 characters.',
      );
    }

    if (normalizedVariantName.isEmpty || normalizedVariantName.length > 150) {
      throw ArgumentError.value(
        variantName,
        'variantName',
        'Variant name must contain between 1 and 150 characters.',
      );
    }

    if (normalizedUnit.isEmpty) {
      throw ArgumentError.value(unit, 'unit', 'Unit cannot be empty.');
    }

    if (costPrice < 0) {
      throw ArgumentError.value(
        costPrice,
        'costPrice',
        'Cost price cannot be negative.',
      );
    }

    if (sellingPrice < 0) {
      throw ArgumentError.value(
        sellingPrice,
        'sellingPrice',
        'Selling price cannot be negative.',
      );
    }

    final normalizedCategoryId = _normalizeOptional(categoryId);

    final productId = _newId('product');
    final variantId = _newId('variant');
    final now = DateTime.now();

    await _database.transaction(() async {
      final business = await (_database.select(
        _database.businessSettings,
      )..where((table) => table.id.equals(businessId))).getSingleOrNull();

      if (business == null) {
        throw StateError('Business does not exist.');
      }

      if (normalizedCategoryId != null) {
        final category =
            await (_database.select(_database.categories)..where(
                  (table) =>
                      table.id.equals(normalizedCategoryId) &
                      table.businessId.equals(businessId),
                ))
                .getSingleOrNull();

        if (category == null || !category.isActive) {
          throw StateError(
            'Category does not exist, is inactive, or belongs to another business.',
          );
        }
      }

      await _database
          .into(_database.products)
          .insert(
            ProductsCompanion.insert(
              id: productId,
              businessId: businessId,
              categoryId: Value(normalizedCategoryId),
              name: normalizedName,
              description: Value(normalizedDescription),
              imagePath: Value(normalizedImagePath),
              createdAt: now,
              updatedAt: now,
            ),
          );

      await _database
          .into(_database.productVariants)
          .insert(
            ProductVariantsCompanion.insert(
              id: variantId,
              businessId: businessId,
              productId: productId,
              name: normalizedVariantName,
              sku: Value(normalizedSku),
              costPrice: costPrice,
              sellingPrice: sellingPrice,
              unit: Value(normalizedUnit),
              trackStock: Value(trackStock),
              createdAt: now,
              updatedAt: now,
            ),
          );
    });

    return productId;
  }

  /// Retrieves a product with its category and all variants.
  ///
  /// Returns null if the product does not exist or belongs
  /// to another business.
  ///
  /// Inactive variants are included.
  Future<ProductDetails?> getProductDetails({
    required String businessId,
    required String productId,
  }) async {
    if (businessId.trim().isEmpty) {
      throw ArgumentError.value(
        businessId,
        'businessId',
        'Business ID cannot be empty.',
      );
    }

    if (productId.trim().isEmpty) {
      throw ArgumentError.value(
        productId,
        'productId',
        'Product ID cannot be empty.',
      );
    }

    final product =
        await (_database.select(_database.products)..where(
              (table) =>
                  table.id.equals(productId) &
                  table.businessId.equals(businessId),
            ))
            .getSingleOrNull();

    if (product == null) {
      return null;
    }

    Category? category;

    if (product.categoryId != null) {
      category =
          await (_database.select(_database.categories)..where(
                (table) =>
                    table.id.equals(product.categoryId!) &
                    table.businessId.equals(businessId),
              ))
              .getSingleOrNull();
    }

    final variants =
        await (_database.select(_database.productVariants)
              ..where(
                (table) =>
                    table.productId.equals(productId) &
                    table.businessId.equals(businessId),
              )
              ..orderBy([
                (table) => OrderingTerm.asc(table.name),
                (table) => OrderingTerm.asc(table.id),
              ]))
            .get();

    return ProductDetails(
      product: product,
      category: category,
      variants: List.unmodifiable(variants),
    );
  }

  String? _normalizeOptional(String? value) {
    final normalized = value?.trim();

    if (normalized == null || normalized.isEmpty) {
      return null;
    }

    return normalized;
  }
}
