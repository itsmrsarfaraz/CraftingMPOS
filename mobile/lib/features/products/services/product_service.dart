import 'dart:math';

import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../models/product_details.dart';
import '../models/product_list_item.dart';

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

    final normalizedBusinessId = businessId.trim();

    if (normalizedBusinessId.isEmpty) {
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
      final business =
          await (_database.select(_database.businessSettings)
                ..where((table) => table.id.equals(normalizedBusinessId)))
              .getSingleOrNull();

      if (business == null) {
        throw StateError('Business does not exist.');
      }

      if (normalizedCategoryId != null) {
        final category =
            await (_database.select(_database.categories)..where(
                  (table) =>
                      table.id.equals(normalizedCategoryId) &
                      table.businessId.equals(normalizedBusinessId),
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
              businessId: normalizedBusinessId,
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
              businessId: normalizedBusinessId,
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

  /// Creates an additional variant for an existing active product.
  ///
  /// Returns the newly created variant ID.
  Future<String> createVariant({
    required String businessId,
    required String productId,
    required String name,
    required int costPrice,
    required int sellingPrice,
    String? sku,
    String? attributes,
    String unit = 'piece',
    bool trackStock = true,
  }) async {
    final normalizedBusinessId = businessId.trim();
    final normalizedProductId = productId.trim();
    final normalizedName = name.trim();
    final normalizedSku = _normalizeOptional(sku);
    final normalizedAttributes = _normalizeOptional(attributes);
    final normalizedUnit = unit.trim();

    if (normalizedBusinessId.isEmpty) {
      throw ArgumentError.value(
        businessId,
        'businessId',
        'Business ID cannot be empty.',
      );
    }

    if (normalizedProductId.isEmpty) {
      throw ArgumentError.value(
        productId,
        'productId',
        'Product ID cannot be empty.',
      );
    }

    if (normalizedName.isEmpty || normalizedName.length > 150) {
      throw ArgumentError.value(
        name,
        'name',
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

    final variantId = _newId('variant');
    final now = DateTime.now();

    await _database.transaction(() async {
      final product =
          await (_database.select(_database.products)..where(
                (table) =>
                    table.id.equals(normalizedProductId) &
                    table.businessId.equals(normalizedBusinessId),
              ))
              .getSingleOrNull();

      if (product == null || !product.isActive) {
        throw StateError(
          'Product does not exist, is inactive, or belongs to another business.',
        );
      }

      if (normalizedSku != null) {
        final existingVariant =
            await (_database.select(_database.productVariants)..where(
                  (table) =>
                      table.businessId.equals(normalizedBusinessId) &
                      table.sku.equals(normalizedSku),
                ))
                .getSingleOrNull();

        if (existingVariant != null) {
          throw StateError('SKU already exists in this business.');
        }
      }

      await _database
          .into(_database.productVariants)
          .insert(
            ProductVariantsCompanion.insert(
              id: variantId,
              businessId: normalizedBusinessId,
              productId: normalizedProductId,
              name: normalizedName,
              sku: Value(normalizedSku),
              attributes: Value(normalizedAttributes),
              costPrice: costPrice,
              sellingPrice: sellingPrice,
              unit: Value(normalizedUnit),
              trackStock: Value(trackStock),
              createdAt: now,
              updatedAt: now,
            ),
          );
    });

    return variantId;
  }

  /// Updates an existing variant without changing its product association.
  ///
  /// Returns false if the variant does not belong to the business.
  /// Blank or null SKU and attributes values clear those fields.
  Future<bool> updateVariant({
    required String businessId,
    required String variantId,
    required String name,
    required int costPrice,
    required int sellingPrice,
    String? sku,
    String? attributes,
    String unit = 'piece',
    bool trackStock = true,
  }) async {
    final normalizedBusinessId = businessId.trim();
    final normalizedVariantId = variantId.trim();
    final normalizedName = name.trim();
    final normalizedSku = _normalizeOptional(sku);
    final normalizedAttributes = _normalizeOptional(attributes);
    final normalizedUnit = unit.trim();

    if (normalizedBusinessId.isEmpty) {
      throw ArgumentError.value(
        businessId,
        'businessId',
        'Business ID cannot be empty.',
      );
    }

    if (normalizedVariantId.isEmpty) {
      throw ArgumentError.value(
        variantId,
        'variantId',
        'Variant ID cannot be empty.',
      );
    }

    if (normalizedName.isEmpty || normalizedName.length > 150) {
      throw ArgumentError.value(
        name,
        'name',
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

    final result = await _database.transaction<bool>(() async {
      final variant =
          await (_database.select(_database.productVariants)..where(
                (table) =>
                    table.id.equals(normalizedVariantId) &
                    table.businessId.equals(normalizedBusinessId),
              ))
              .getSingleOrNull();

      if (variant == null) {
        return false;
      }

      if (normalizedSku != null) {
        final existingVariant =
            await (_database.select(_database.productVariants)..where(
                  (table) =>
                      table.businessId.equals(normalizedBusinessId) &
                      table.sku.equals(normalizedSku),
                ))
                .getSingleOrNull();

        if (existingVariant != null &&
            existingVariant.id != normalizedVariantId) {
          throw StateError('SKU already exists in this business.');
        }
      }

      final currentTime = DateTime.now();
      final minimumNextTime = variant.updatedAt.add(const Duration(seconds: 1));

      final now = currentTime.isAfter(minimumNextTime)
          ? currentTime
          : minimumNextTime;

      final updatedRows =
          await (_database.update(_database.productVariants)..where(
                (table) =>
                    table.id.equals(normalizedVariantId) &
                    table.businessId.equals(normalizedBusinessId),
              ))
              .write(
                ProductVariantsCompanion(
                  name: Value(normalizedName),
                  sku: Value(normalizedSku),
                  attributes: Value(normalizedAttributes),
                  costPrice: Value(costPrice),
                  sellingPrice: Value(sellingPrice),
                  unit: Value(normalizedUnit),
                  trackStock: Value(trackStock),
                  updatedAt: Value(now),
                ),
              );

      return updatedRows > 0;
    });

    return result;
  }

  /// Updates a product's information within its business.
  ///
  /// Nullable fields are explicitly replaced, so passing null clears them.
  /// Returns false if the product does not exist in the specified business.
  Future<bool> updateProduct({
    required String businessId,
    required String productId,
    required String name,
    required String? categoryId,
    required String? description,
    required String? imagePath,
  }) async {
    final normalizedBusinessId = businessId.trim();
    final normalizedProductId = productId.trim();
    final normalizedName = name.trim();
    final normalizedCategoryId = _normalizeOptional(categoryId);
    final normalizedDescription = _normalizeOptional(description);
    final normalizedImagePath = _normalizeOptional(imagePath);

    if (normalizedBusinessId.isEmpty) {
      throw ArgumentError.value(
        businessId,
        'businessId',
        'Business ID cannot be empty.',
      );
    }

    if (normalizedProductId.isEmpty) {
      throw ArgumentError.value(
        productId,
        'productId',
        'Product ID cannot be empty.',
      );
    }

    if (normalizedName.length < 2 || normalizedName.length > 150) {
      throw ArgumentError.value(
        name,
        'name',
        'Product name must contain between 2 and 150 characters.',
      );
    }

    final result = await _database.transaction<bool>(() async {
      final product =
          await (_database.select(_database.products)..where(
                (table) =>
                    table.id.equals(normalizedProductId) &
                    table.businessId.equals(normalizedBusinessId),
              ))
              .getSingleOrNull();
      if (product == null) {
        return false;
      }

      if (normalizedCategoryId != null) {
        final category =
            await (_database.select(_database.categories)..where(
                  (table) =>
                      table.id.equals(normalizedCategoryId) &
                      table.businessId.equals(normalizedBusinessId),
                ))
                .getSingleOrNull();

        if (category == null || !category.isActive) {
          throw StateError(
            'Category does not exist, is inactive, or belongs to another business.',
          );
        }
      }

      final currentTime = DateTime.now();
      final minimumNextTime = product.updatedAt.add(const Duration(seconds: 1));

      final now = currentTime.isAfter(minimumNextTime)
          ? currentTime
          : minimumNextTime;

      final updatedRows =
          await (_database.update(_database.products)..where(
                (table) =>
                    table.id.equals(normalizedProductId) &
                    table.businessId.equals(normalizedBusinessId),
              ))
              .write(
                ProductsCompanion(
                  name: Value(normalizedName),
                  categoryId: Value(normalizedCategoryId),
                  description: Value(normalizedDescription),
                  imagePath: Value(normalizedImagePath),
                  updatedAt: Value(now),
                ),
              );

      return updatedRows > 0;
    });
    return result;
  }

  /// Activates or deactivates a product within its business.
  ///
  /// Returns false if the product does not exist in the specified business.
  /// If the product already has the requested status, no update is performed.
  Future<bool> setProductStatus({
    required String businessId,
    required String productId,
    required bool isActive,
  }) async {
    final normalizedBusinessId = businessId.trim();
    final normalizedProductId = productId.trim();

    if (normalizedBusinessId.isEmpty) {
      throw ArgumentError.value(
        businessId,
        'businessId',
        'Business ID cannot be empty.',
      );
    }

    if (normalizedProductId.isEmpty) {
      throw ArgumentError.value(
        productId,
        'productId',
        'Product ID cannot be empty.',
      );
    }

    final result = await _database.transaction<bool>(() async {
      final product =
          await (_database.select(_database.products)..where(
                (table) =>
                    table.id.equals(normalizedProductId) &
                    table.businessId.equals(normalizedBusinessId),
              ))
              .getSingleOrNull();

      if (product == null) {
        return false;
      }

      // Avoid unnecessary database updates when the status is unchanged.
      if (product.isActive == isActive) {
        return true;
      }

      final currentTime = DateTime.now();
      final minimumNextTime = product.updatedAt.add(const Duration(seconds: 1));

      final now = currentTime.isAfter(minimumNextTime)
          ? currentTime
          : minimumNextTime;

      final updatedRows =
          await (_database.update(_database.products)..where(
                (table) =>
                    table.id.equals(normalizedProductId) &
                    table.businessId.equals(normalizedBusinessId),
              ))
              .write(
                ProductsCompanion(
                  isActive: Value(isActive),
                  updatedAt: Value(now),
                ),
              );

      return updatedRows > 0;
    });

    return result;
  }

  /// Activates or deactivates a product variant within its business.
  ///
  /// Returns false if the variant does not exist in the specified business.
  /// If the variant already has the requested status, no update is performed.
  Future<bool> setVariantStatus({
    required String businessId,
    required String variantId,
    required bool isActive,
  }) async {
    final normalizedBusinessId = businessId.trim();
    final normalizedVariantId = variantId.trim();

    if (normalizedBusinessId.isEmpty) {
      throw ArgumentError.value(
        businessId,
        'businessId',
        'Business ID cannot be empty.',
      );
    }

    if (normalizedVariantId.isEmpty) {
      throw ArgumentError.value(
        variantId,
        'variantId',
        'Variant ID cannot be empty.',
      );
    }

    final result = await _database.transaction<bool>(() async {
      final variant =
          await (_database.select(_database.productVariants)..where(
                (table) =>
                    table.id.equals(normalizedVariantId) &
                    table.businessId.equals(normalizedBusinessId),
              ))
              .getSingleOrNull();

      if (variant == null) {
        return false;
      }

      // Avoid unnecessary database updates when the status is unchanged.
      if (variant.isActive == isActive) {
        return true;
      }

      final currentTime = DateTime.now();
      final minimumNextTime = variant.updatedAt.add(const Duration(seconds: 1));

      final now = currentTime.isAfter(minimumNextTime)
          ? currentTime
          : minimumNextTime;

      final updatedRows =
          await (_database.update(_database.productVariants)..where(
                (table) =>
                    table.id.equals(normalizedVariantId) &
                    table.businessId.equals(normalizedBusinessId),
              ))
              .write(
                ProductVariantsCompanion(
                  isActive: Value(isActive),
                  updatedAt: Value(now),
                ),
              );

      return updatedRows > 0;
    });

    return result;
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
    final normalizedBusinessId = businessId.trim();
    final normalizedProductId = productId.trim();

    if (normalizedBusinessId.isEmpty) {
      throw ArgumentError.value(
        businessId,
        'businessId',
        'Business ID cannot be empty.',
      );
    }

    if (normalizedProductId.isEmpty) {
      throw ArgumentError.value(
        productId,
        'productId',
        'Product ID cannot be empty.',
      );
    }

    final product =
        await (_database.select(_database.products)..where(
              (table) =>
                  table.id.equals(normalizedProductId) &
                  table.businessId.equals(normalizedBusinessId),
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
                    table.businessId.equals(normalizedBusinessId),
              ))
              .getSingleOrNull();
    }

    final variants =
        await (_database.select(_database.productVariants)
              ..where(
                (table) =>
                    table.productId.equals(normalizedProductId) &
                    table.businessId.equals(normalizedBusinessId),
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

  /// Retrieves one variant belonging to a specific business.
  ///
  /// Inactive variants are included.
  ///
  /// Returns null if the variant does not exist or does not
  /// belong to the specified business.
  Future<ProductVariant?> getVariantDetails({
    required String businessId,
    required String variantId,
  }) async {
    final normalizedBusinessId = businessId.trim();
    final normalizedVariantId = variantId.trim();

    if (normalizedBusinessId.isEmpty) {
      throw ArgumentError.value(
        businessId,
        'businessId',
        'Business ID cannot be empty.',
      );
    }

    if (normalizedVariantId.isEmpty) {
      throw ArgumentError.value(
        variantId,
        'variantId',
        'Variant ID cannot be empty.',
      );
    }

    final variant =
        await (_database.select(_database.productVariants)..where(
              (table) =>
                  table.businessId.equals(normalizedBusinessId) &
                  table.id.equals(normalizedVariantId),
            ))
            .getSingleOrNull();

    return variant;
  }

  /// Retrieves variants belonging to a specific product and business.
  ///
  /// Set [isActive] to true or false to filter by status.
  /// Pass null (the default) to include all variants.
  ///
  /// Returns an empty unmodifiable list if no matching variants exist.
  Future<List<ProductVariant>> getProductVariants({
    required String businessId,
    required String productId,
    bool? isActive,
  }) async {
    final normalizedBusinessId = businessId.trim();
    final normalizedProductId = productId.trim();

    if (normalizedBusinessId.isEmpty) {
      throw ArgumentError.value(
        businessId,
        'businessId',
        'Business ID cannot be empty.',
      );
    }

    if (normalizedProductId.isEmpty) {
      throw ArgumentError.value(
        productId,
        'productId',
        'Product ID cannot be empty.',
      );
    }

    final query = _database.select(_database.productVariants)
      ..where(
        (table) =>
            table.businessId.equals(normalizedBusinessId) &
            table.productId.equals(normalizedProductId),
      );

    if (isActive != null) {
      query.where((table) => table.isActive.equals(isActive));
    }

    query.orderBy([
      (table) => OrderingTerm.asc(table.name),
      (table) => OrderingTerm.asc(table.id),
    ]);

    final variants = await query.get();

    return List.unmodifiable(variants);
  }

  /// Retrieves a paginated list of products for a business.
  ///
  /// Searches product names and active variant SKUs.
  /// Returns each product only once.
  ///
  /// Inactive variants do not affect SKU search results.
  Future<List<ProductListItem>> getProducts({
    required String businessId,
    String? search,
    String? categoryId,
    bool? isActive = true,
    int limit = 20,
    int offset = 0,
  }) async {
    final normalizedBusinessId = businessId.trim();

    if (normalizedBusinessId.isEmpty) {
      throw ArgumentError.value(
        businessId,
        'businessId',
        'Business ID cannot be empty.',
      );
    }

    if (limit < 1 || limit > 100) {
      throw ArgumentError.value(
        limit,
        'limit',
        'Limit must be between 1 and 100.',
      );
    }

    if (offset < 0) {
      throw ArgumentError.value(offset, 'offset', 'Offset cannot be negative.');
    }

    final normalizedSearch = _normalizeOptional(search);
    final normalizedCategoryId = _normalizeOptional(categoryId);

    final query = _database.select(_database.products)
      ..where((table) => table.businessId.equals(normalizedBusinessId));

    if (isActive != null) {
      query.where((table) => table.isActive.equals(isActive));
    }

    if (normalizedCategoryId != null) {
      query.where((table) => table.categoryId.equals(normalizedCategoryId));
    }

    if (normalizedSearch != null) {
      final pattern = '%$normalizedSearch%';

      final matchingVariant = _database.selectOnly(_database.productVariants)
        ..addColumns([_database.productVariants.id])
        ..where(
          _database.productVariants.businessId.equals(normalizedBusinessId) &
              _database.productVariants.productId.equalsExp(
                _database.products.id,
              ) &
              _database.productVariants.isActive.equals(true) &
              _database.productVariants.sku.like(pattern),
        );

      query.where(
        (table) => table.name.like(pattern) | existsQuery(matchingVariant),
      );
    }

    query
      ..orderBy([
        (table) => OrderingTerm.asc(table.name),
        (table) => OrderingTerm.asc(table.id),
      ])
      ..limit(limit, offset: offset);

    final products = await query.get();

    if (products.isEmpty) {
      return const [];
    }

    final categoryIds = products
        .map((product) => product.categoryId)
        .whereType<String>()
        .toSet();

    final categories = categoryIds.isEmpty
        ? <Category>[]
        : await (_database.select(_database.categories)..where(
                (table) =>
                    table.businessId.equals(normalizedBusinessId) &
                    table.id.isIn(categoryIds),
              ))
              .get();

    final categoriesById = {
      for (final category in categories) category.id: category,
    };

    return List.unmodifiable(
      products.map(
        (product) => ProductListItem(
          product: product,
          category: product.categoryId == null
              ? null
              : categoriesById[product.categoryId],
        ),
      ),
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
