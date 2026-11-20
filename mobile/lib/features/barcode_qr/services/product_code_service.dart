import 'dart:math';

import 'package:drift/drift.dart';

import 'package:crafting_mpos/core/database/app_database.dart';

class ProductCodeService {
  ProductCodeService(this._database);

  final AppDatabase _database;

  static final Random _random = Random.secure();

  static String _newId(String prefix) {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));

    final value = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();

    return '$prefix-$value';
  }

  Future<String> createCode({
    required String businessId,
    required String variantId,
    required String code,
    String codeType = 'CODE128',
    bool isPrimary = false,
  }) async {
    final normalizedBusinessId = businessId.trim();
    final normalizedVariantId = variantId.trim();
    final normalizedCode = code.trim();
    final normalizedCodeType = codeType.trim().toUpperCase();

    if (normalizedBusinessId.isEmpty) {
      throw ArgumentError('Business ID cannot be empty.');
    }

    if (normalizedVariantId.isEmpty) {
      throw ArgumentError('Variant ID cannot be empty.');
    }

    if (normalizedCode.isEmpty || normalizedCode.length > 255) {
      throw ArgumentError('Code must contain between 1 and 255 characters.');
    }

    if (normalizedCodeType.isEmpty) {
      throw ArgumentError('Code type cannot be empty.');
    }

    return _database.transaction<String>(() async {
      final variant =
          await (_database.select(_database.productVariants)..where(
                (table) =>
                    table.businessId.equals(normalizedBusinessId) &
                    table.id.equals(normalizedVariantId),
              ))
              .getSingleOrNull();

      if (variant == null) {
        throw StateError('Product variant does not exist in this business.');
      }

      final existingCode =
          await (_database.select(_database.productCodes)..where(
                (table) =>
                    table.businessId.equals(normalizedBusinessId) &
                    table.code.equals(normalizedCode),
              ))
              .getSingleOrNull();

      if (existingCode != null) {
        throw StateError('This code is already registered in this business.');
      }

      if (isPrimary) {
        await (_database.update(_database.productCodes)..where(
              (table) =>
                  table.businessId.equals(normalizedBusinessId) &
                  table.variantId.equals(normalizedVariantId) &
                  table.isPrimary.equals(true),
            ))
            .write(const ProductCodesCompanion(isPrimary: Value(false)));
      }

      final id = _newId('code');

      await _database
          .into(_database.productCodes)
          .insert(
            ProductCodesCompanion.insert(
              id: id,
              businessId: normalizedBusinessId,
              variantId: normalizedVariantId,
              code: normalizedCode,
              codeType: Value(normalizedCodeType),
              isPrimary: Value(isPrimary),
              createdAt: DateTime.now(),
            ),
          );

      return id;
    });
  }

  Future<ProductCode?> getCodeByValue({
    required String businessId,
    required String code,
  }) async {
    final normalizedBusinessId = businessId.trim();
    final normalizedCode = code.trim();

    if (normalizedBusinessId.isEmpty) {
      throw ArgumentError('Business ID cannot be empty.');
    }

    if (normalizedCode.isEmpty) {
      throw ArgumentError('Code cannot be empty.');
    }

    return (_database.select(_database.productCodes)..where(
          (table) =>
              table.businessId.equals(normalizedBusinessId) &
              table.code.equals(normalizedCode),
        ))
        .getSingleOrNull();
  }
}
