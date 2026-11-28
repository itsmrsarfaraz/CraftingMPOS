import '../models/printer_connection_state.dart';
import '../models/receipt_data.dart';
import '../models/receipt_print_result.dart';
import 'printer_service.dart';
import 'receipt_builder.dart';

class ReceiptPrintingService {
  ReceiptPrintingService({
    required this.receiptBuilder,
    required this.printerService,
  });

  final ReceiptBuilder receiptBuilder;
  final PrinterService printerService;

  Future<ReceiptPrintResult> printReceipt(ReceiptData receipt) async {
    final bytes = receiptBuilder.build(receipt);
    final printed = await printerService.printBytes(bytes);

    if (printed) {
      return const ReceiptPrintResult(status: ReceiptPrintStatus.printed);
    }

    final status = printerService.state == PrinterConnectionState.connected
        ? ReceiptPrintStatus.transmissionFailed
        : ReceiptPrintStatus.printerNotConnected;

    return ReceiptPrintResult(status: status);
  }
}
