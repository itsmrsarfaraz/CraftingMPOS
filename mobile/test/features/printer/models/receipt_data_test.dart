import 'package:flutter_test/flutter_test.dart';
import 'package:crafting_mpos/features/printer/models/receipt_data.dart';
import 'package:crafting_mpos/features/printer/models/receipt_item_line.dart';

void main() {
  late ReceiptItemLine item;

  setUp(() {
    item = ReceiptItemLine(
      productName: 'Milk',
      variantName: '1 Litre',
      quantityMilliunits: 1000,
      unit: 'piece',
      unitPricePaisa: 25000,
      lineTotalPaisa: 25000,
    );
  });

  ReceiptData createReceipt({
    List<ReceiptItemLine>? items,
    int subtotalPaisa = 25000,
    int discountPaisa = 0,
    int taxPaisa = 0,
    int grandTotalPaisa = 25000,
    int amountPaidPaisa = 25000,
    int changePaisa = 0,
  }) {
    return ReceiptData(
      storeName: ' My Store ',
      receiptNumber: ' R-001 ',
      issuedAt: DateTime(2026, 11, 25, 12),
      items: items ?? [item],
      subtotalPaisa: subtotalPaisa,
      discountPaisa: discountPaisa,
      taxPaisa: taxPaisa,
      grandTotalPaisa: grandTotalPaisa,
      paymentMethod: ' Cash ',
      amountPaidPaisa: amountPaidPaisa,
      changePaisa: changePaisa,
    );
  }

  group('ReceiptData', () {
    test('Creates a valid receipt', () {
      final receipt = createReceipt();

      expect(receipt.storeName, 'My Store');
      expect(receipt.receiptNumber, 'R-001');
      expect(receipt.paymentMethod, 'Cash');
      expect(receipt.items.length, 1);
      expect(receipt.grandTotalPaisa, 25000);
    });

    test('Rejects an empty store name', () {
      expect(
        () => ReceiptData(
          storeName: ' ',
          receiptNumber: 'R-001',
          issuedAt: DateTime(2026),
          items: [item],
          subtotalPaisa: 25000,
          discountPaisa: 0,
          taxPaisa: 0,
          grandTotalPaisa: 25000,
          paymentMethod: 'Cash',
          amountPaidPaisa: 25000,
          changePaisa: 0,
        ),
        throwsArgumentError,
      );
    });

    test('Rejects an empty receipt number', () {
      expect(
        () => ReceiptData(
          storeName: 'Store',
          receiptNumber: ' ',
          issuedAt: DateTime(2026),
          items: [item],
          subtotalPaisa: 25000,
          discountPaisa: 0,
          taxPaisa: 0,
          grandTotalPaisa: 25000,
          paymentMethod: 'Cash',
          amountPaidPaisa: 25000,
          changePaisa: 0,
        ),
        throwsArgumentError,
      );
    });

    test('Rejects an empty item list', () {
      expect(() => createReceipt(items: []), throwsArgumentError);
    });

    test('Rejects negative monetary values', () {
      expect(() => createReceipt(discountPaisa: -1), throwsArgumentError);
    });

    test('Rejects an empty payment method', () {
      expect(
        () => ReceiptData(
          storeName: 'Store',
          receiptNumber: 'R-001',
          issuedAt: DateTime(2026),
          items: [item],
          subtotalPaisa: 25000,
          discountPaisa: 0,
          taxPaisa: 0,
          grandTotalPaisa: 25000,
          paymentMethod: ' ',
          amountPaidPaisa: 25000,
          changePaisa: 0,
        ),
        throwsArgumentError,
      );
    });

    test('Rejects payment below the grand total', () {
      expect(() => createReceipt(amountPaidPaisa: 20000), throwsArgumentError);
    });

    test('Rejects incorrect change', () {
      expect(
        () => createReceipt(
          grandTotalPaisa: 20000,
          amountPaidPaisa: 25000,
          changePaisa: 1000,
        ),
        throwsArgumentError,
      );
    });

    test('Calculates valid change consistently', () {
      final receipt = createReceipt(
        grandTotalPaisa: 20000,
        amountPaidPaisa: 25000,
        changePaisa: 5000,
      );

      expect(receipt.changePaisa, 5000);
    });

    test('Prevents modification of receipt items', () {
      final originalItems = [item];
      final receipt = createReceipt(items: originalItems);

      originalItems.clear();

      expect(receipt.items, hasLength(1));

      expect(() => receipt.items.add(item), throwsUnsupportedError);
    });
  });
}
