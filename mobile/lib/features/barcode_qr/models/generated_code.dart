import 'package:barcode_widget/barcode_widget.dart';

enum GeneratedCodeFormat { code128, qrCode }

class GeneratedCode {
  const GeneratedCode({
    required this.data,
    required this.format,
    required this.barcode,
  });

  final String data;
  final GeneratedCodeFormat format;
  final Barcode barcode;
}
