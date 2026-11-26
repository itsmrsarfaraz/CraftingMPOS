import 'package:flutter_test/flutter_test.dart';
import 'package:crafting_mpos/features/printer/models/receipt_item_line.dart';

void main() {
  group('ReceiptItemLine', () {
    test('Creates a valid receipt item', () {
      final item = ReceiptItemLine(
        productName: 'Milk',
        variantName: '1 Litre',
        quantityMilliunits: 2000,
        unit: 'piece',
        unitPricePaisa: 25000,
        lineTotalPaisa: 50000,
        sku: 'MILK-001',
      );

      expect(item.productName, 'Milk');
      expect(item.variantName, '1 Litre');
      expect(item.quantityMilliunits, 2000);
      expect(item.unitPricePaisa, 25000);
      expect(item.lineTotalPaisa, 50000);
      expect(item.sku, 'MILK-001');
    });

    test('Trims text values', () {
      final item = ReceiptItemLine(
        productName: ' Milk ',
        variantName: ' 1 Litre ',
        quantityMilliunits: 1000,
        unit: ' piece ',
        unitPricePaisa: 25000,
        lineTotalPaisa: 25000,
        sku: ' MILK-001 ',
      );

      expect(item.productName, 'Milk');
      expect(item.variantName, '1 Litre');
      expect(item.unit, 'piece');
      expect(item.sku, 'MILK-001');
    });

    test('Converts an empty SKU to null', () {
      final item = ReceiptItemLine(
        productName: 'Milk',
        variantName: '1 Litre',
        quantityMilliunits: 1000,
        unit: 'piece',
        unitPricePaisa: 25000,
        lineTotalPaisa: 25000,
        sku: '  ',
      );

      expect(item.sku, isNull);
    });

    test('Rejects an empty product name', () {
      expect(
        () => ReceiptItemLine(
          productName: ' ',
          variantName: '1 Litre',
          quantityMilliunits: 1000,
          unit: 'piece',
          unitPricePaisa: 25000,
          lineTotalPaisa: 25000,
        ),
        throwsArgumentError,
      );
    });

    test('Rejects an empty variant name', () {
      expect(
        () => ReceiptItemLine(
          productName: 'Milk',
          variantName: ' ',
          quantityMilliunits: 1000,
          unit: 'piece',
          unitPricePaisa: 25000,
          lineTotalPaisa: 25000,
        ),
        throwsArgumentError,
      );
    });

    test('Rejects zero quantity', () {
      expect(
        () => ReceiptItemLine(
          productName: 'Milk',
          variantName: '1 Litre',
          quantityMilliunits: 0,
          unit: 'piece',
          unitPricePaisa: 25000,
          lineTotalPaisa: 0,
        ),
        throwsArgumentError,
      );
    });

    test('Rejects negative quantity', () {
      expect(
        () => ReceiptItemLine(
          productName: 'Milk',
          variantName: '1 Litre',
          quantityMilliunits: -1000,
          unit: 'piece',
          unitPricePaisa: 25000,
          lineTotalPaisa: 0,
        ),
        throwsArgumentError,
      );
    });

    test('Rejects negative unit price', () {
      expect(
        () => ReceiptItemLine(
          productName: 'Milk',
          variantName: '1 Litre',
          quantityMilliunits: 1000,
          unit: 'piece',
          unitPricePaisa: -1,
          lineTotalPaisa: 25000,
        ),
        throwsArgumentError,
      );
    });

    test('Rejects negative line total', () {
      expect(
        () => ReceiptItemLine(
          productName: 'Milk',
          variantName: '1 Litre',
          quantityMilliunits: 1000,
          unit: 'piece',
          unitPricePaisa: 25000,
          lineTotalPaisa: -1,
        ),
        throwsArgumentError,
      );
    });
  });
}
