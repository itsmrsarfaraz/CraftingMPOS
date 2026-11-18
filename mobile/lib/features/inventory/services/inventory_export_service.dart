import 'dart:convert';

import '../models/inventory_report_item.dart';

class InventoryExportService {
  const InventoryExportService();

  /// Generates UTF-8 compatible CSV content with an Excel-friendly BOM.
  String generateCsv(List<InventoryReportItem> items) {
    final rows = <List<String>>[
      [
        'Product',
        'Variant',
        'SKU',
        'Category',
        'Unit',
        'Cost Price',
        'Selling Price',
        'Stock Tracking',
        'Quantity',
        'Stock Status',
        'Last Stock Updated',
      ],
    ];

    for (final item in items) {
      rows.add([
        item.productName,
        item.variantName,
        item.sku ?? '',
        item.categoryName ?? '',
        item.unit,
        _formatMoney(item.costPrice),
        _formatMoney(item.sellingPrice),
        item.trackStock ? 'Tracked' : 'Untracked',
        _formatQuantity(item.quantityMilliunits),
        _stockStatus(item),
        item.lastStockUpdatedAt?.toIso8601String() ?? '',
      ]);
    }

    final csv = rows.map(_encodeRow).join('\r\n');

    // UTF-8 BOM improves compatibility with Microsoft Excel.
    return '\uFEFF$csv';
  }

  /// Converts generated CSV content into UTF-8 bytes.
  List<int> generateCsvBytes(List<InventoryReportItem> items) {
    return utf8.encode(generateCsv(items));
  }

  String _encodeRow(List<String> fields) {
    return fields.map(_escapeCsvField).join(',');
  }

  String _escapeCsvField(String value) {
    final escaped = value.replaceAll('"', '""');

    if (value.contains(',') ||
        value.contains('"') ||
        value.contains('\r') ||
        value.contains('\n')) {
      return '"$escaped"';
    }

    return escaped;
  }

  /// Converts paisa into rupees without floating-point arithmetic.
  String _formatMoney(int paisa) {
    final isNegative = paisa < 0;
    final absoluteValue = paisa.abs();

    final rupees = absoluteValue ~/ 100;
    final remainingPaisa = absoluteValue % 100;

    return '${isNegative ? '-' : ''}$rupees.'
        '${remainingPaisa.toString().padLeft(2, '0')}';
  }

  /// Converts milliunits into a quantity with three decimal places.
  String _formatQuantity(int milliunits) {
    final isNegative = milliunits < 0;
    final absoluteValue = milliunits.abs();

    final wholeUnits = absoluteValue ~/ 1000;
    final remainingMilliunits = absoluteValue % 1000;

    return '${isNegative ? '-' : ''}$wholeUnits.'
        '${remainingMilliunits.toString().padLeft(3, '0')}';
  }

  String _stockStatus(InventoryReportItem item) {
    if (item.isUntracked) {
      return 'Untracked';
    }

    if (item.isOutOfStock) {
      return 'Out of Stock';
    }

    return 'In Stock';
  }
}
