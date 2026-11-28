import '../../barcode_qr/models/label_layout_config.dart';
import '../../barcode_qr/models/product_label_data.dart';
import '../models/printer_connection_state.dart';
import '../models/receipt_print_result.dart';
import 'printer_service.dart';
import 'product_label_builder.dart';

class ProductLabelPrintingService {
  ProductLabelPrintingService({
    required this.productLabelBuilder,
    required this.printerService,
  });

  final ProductLabelBuilder productLabelBuilder;
  final PrinterService printerService;

  Future<ReceiptPrintResult> printLabel({
    required ProductLabelData data,
    required LabelLayoutConfig layout,
  }) async {
    final bytes = productLabelBuilder.build(data: data, layout: layout);

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
