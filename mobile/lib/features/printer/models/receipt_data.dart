import 'receipt_item_line.dart';

class ReceiptData {
  factory ReceiptData({
    required String storeName,
    required String receiptNumber,
    required DateTime issuedAt,
    required List<ReceiptItemLine> items,
    required int subtotalPaisa,
    required int discountPaisa,
    required int taxPaisa,
    required int grandTotalPaisa,
    required String paymentMethod,
    required int amountPaidPaisa,
    required int changePaisa,
    String? storeAddress,
    String? storePhone,
    String? footerMessage,
  }) {
    if (storeName.trim().isEmpty) {
      throw ArgumentError.value(storeName, 'storeName');
    }

    if (receiptNumber.trim().isEmpty) {
      throw ArgumentError.value(receiptNumber, 'receiptNumber');
    }

    if (items.isEmpty) {
      throw ArgumentError.value(items, 'items');
    }

    if (subtotalPaisa < 0 ||
        discountPaisa < 0 ||
        taxPaisa < 0 ||
        grandTotalPaisa < 0 ||
        amountPaidPaisa < 0 ||
        changePaisa < 0) {
      throw ArgumentError('Receipt monetary values cannot be negative.');
    }

    if (paymentMethod.trim().isEmpty) {
      throw ArgumentError.value(paymentMethod, 'paymentMethod');
    }

    if (amountPaidPaisa < grandTotalPaisa) {
      throw ArgumentError.value(
        amountPaidPaisa,
        'amountPaidPaisa',
        'Amount paid cannot be less than the grand total.',
      );
    }

    if (changePaisa != amountPaidPaisa - grandTotalPaisa) {
      throw ArgumentError.value(
        changePaisa,
        'changePaisa',
        'Change must equal amount paid minus grand total.',
      );
    }

    return ReceiptData._(
      storeName: storeName.trim(),
      receiptNumber: receiptNumber.trim(),
      issuedAt: issuedAt,
      items: List<ReceiptItemLine>.unmodifiable(items),
      subtotalPaisa: subtotalPaisa,
      discountPaisa: discountPaisa,
      taxPaisa: taxPaisa,
      grandTotalPaisa: grandTotalPaisa,
      paymentMethod: paymentMethod.trim(),
      amountPaidPaisa: amountPaidPaisa,
      changePaisa: changePaisa,
      storeAddress: storeAddress?.trim(),
      storePhone: storePhone?.trim(),
      footerMessage: footerMessage?.trim(),
    );
  }

  const ReceiptData._({
    required this.storeName,
    required this.receiptNumber,
    required this.issuedAt,
    required this.items,
    required this.subtotalPaisa,
    required this.discountPaisa,
    required this.taxPaisa,
    required this.grandTotalPaisa,
    required this.paymentMethod,
    required this.amountPaidPaisa,
    required this.changePaisa,
    this.storeAddress,
    this.storePhone,
    this.footerMessage,
  });

  final String storeName;
  final String receiptNumber;
  final DateTime issuedAt;
  final List<ReceiptItemLine> items;

  final int subtotalPaisa;
  final int discountPaisa;
  final int taxPaisa;
  final int grandTotalPaisa;

  final String paymentMethod;
  final int amountPaidPaisa;
  final int changePaisa;

  final String? storeAddress;
  final String? storePhone;
  final String? footerMessage;
}
