enum ReceiptPrintStatus { printed, printerNotConnected, transmissionFailed }

class ReceiptPrintResult {
  const ReceiptPrintResult({required this.status});

  final ReceiptPrintStatus status;

  bool get isSuccess => status == ReceiptPrintStatus.printed;
}
