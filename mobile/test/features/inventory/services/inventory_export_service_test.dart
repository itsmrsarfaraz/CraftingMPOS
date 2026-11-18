import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:crafting_mpos/features/inventory/models/inventory_report_item.dart';
import 'package:crafting_mpos/features/inventory/services/inventory_export_service.dart';

void main() {
  late InventoryExportService service;

  setUp(() {
    service = const InventoryExportService();
  });

  InventoryReportItem createItem({
    String productName = 'Test Product',
    String variantName = 'Default',
    String? sku = 'SKU-001',
    String? categoryName = 'Electronics',
    String unit = 'piece',
    int costPrice = 12550,
    int sellingPrice = 15075,
    bool trackStock = true,
    int quantityMilliunits = 2500,
    DateTime? lastStockUpdatedAt,
  }) {
    return InventoryReportItem(
      productId: 'product-001',
      productName: productName,
      variantId: 'variant-001',
      variantName: variantName,
      sku: sku,
      categoryId: 'category-001',
      categoryName: categoryName,
      unit: unit,
      costPrice: costPrice,
      sellingPrice: sellingPrice,
      trackStock: trackStock,
      quantityMilliunits: quantityMilliunits,
      lastStockUpdatedAt: lastStockUpdatedAt,
    );
  }

  group('InventoryExportService', () {
    test('exports CSV headers when report is empty', () {
      final csv = service.generateCsv([]);

      expect(csv.startsWith('\uFEFF'), isTrue);
      expect(
        csv.substring(1),
        'Product,Variant,SKU,Category,Unit,Cost Price,'
        'Selling Price,Stock Tracking,Quantity,Stock Status,'
        'Last Stock Updated',
      );
    });

    test('exports product and variant details', () {
      final csv = service.generateCsv([createItem()]);

      expect(csv, contains('Test Product,Default,SKU-001,Electronics'));
      expect(csv, contains('piece,125.50,150.75,Tracked,2.500,In Stock'));
    });

    test('formats zero monetary values correctly', () {
      final csv = service.generateCsv([
        createItem(costPrice: 0, sellingPrice: 0),
      ]);

      expect(csv, contains('piece,0.00,0.00'));
    });

    test('formats large monetary values without precision loss', () {
      final csv = service.generateCsv([
        createItem(costPrice: 999999999999, sellingPrice: 999999999999),
      ]);

      expect(csv, contains('9999999999.99'));
    });

    test('formats zero quantity correctly', () {
      final csv = service.generateCsv([createItem(quantityMilliunits: 0)]);

      expect(csv, contains('Tracked,0.000,Out of Stock'));
    });

    test('formats large quantities without precision loss', () {
      final csv = service.generateCsv([
        createItem(quantityMilliunits: 999999999999),
      ]);

      expect(csv, contains('999999999.999'));
    });

    test('exports untracked stock status', () {
      final csv = service.generateCsv([
        createItem(trackStock: false, quantityMilliunits: 0),
      ]);

      expect(csv, contains('Untracked,0.000,Untracked'));
    });

    test('exports nullable SKU and category as empty fields', () {
      final csv = service.generateCsv([
        createItem(sku: null, categoryName: null),
      ]);

      expect(csv, contains('Test Product,Default,,,piece'));
    });

    test('escapes commas in CSV fields', () {
      final csv = service.generateCsv([
        createItem(productName: 'Food, Drinks'),
      ]);

      expect(csv, contains('"Food, Drinks"'));
    });

    test('escapes quotation marks in CSV fields', () {
      final csv = service.generateCsv([
        createItem(productName: 'Premium "Special" Product'),
      ]);

      expect(csv, contains('"Premium ""Special"" Product"'));
    });

    test('escapes line breaks in CSV fields', () {
      final csv = service.generateCsv([
        createItem(productName: 'First Line\nSecond Line'),
      ]);

      expect(csv, contains('"First Line\nSecond Line"'));
    });

    test('exports stock update timestamp in ISO 8601 format', () {
      final updatedAt = DateTime.utc(2026, 11, 18, 10, 30);

      final csv = service.generateCsv([
        createItem(lastStockUpdatedAt: updatedAt),
      ]);

      expect(csv, contains(updatedAt.toIso8601String()));
    });

    test('exports an empty timestamp when stock was never updated', () {
      final csv = service.generateCsv([createItem(lastStockUpdatedAt: null)]);

      expect(csv, endsWith('In Stock,'));
    });

    test('generates UTF-8 CSV bytes with BOM', () {
      final bytes = service.generateCsvBytes([
        createItem(productName: 'Café Product'),
      ]);

      // UTF-8 BOM: EF BB BF.
      expect(bytes.take(3).toList(), [0xEF, 0xBB, 0xBF]);

      final decoded = utf8.decode(bytes);

      expect(decoded, contains('Café Product'));
    });

    test('exports multiple report items as separate CSV rows', () {
      final csv = service.generateCsv([
        createItem(productName: 'Product A'),
        createItem(
          productName: 'Product B',
          variantName: 'Large',
          sku: 'SKU-002',
        ),
      ]);

      final lines = csv.substring(1).split('\r\n');

      expect(lines, hasLength(3));
      expect(lines[1], contains('Product A'));
      expect(lines[2], contains('Product B'));
    });
  });
}
