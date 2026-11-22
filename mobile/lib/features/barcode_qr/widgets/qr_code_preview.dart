import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';

import '../models/generated_code.dart';

class QrCodePreview extends StatelessWidget {
  QrCodePreview({
    super.key,
    required this.generatedCode,
    this.size = 180,
    this.showValue = false,
  }) : assert(
         generatedCode.format == GeneratedCodeFormat.qrCode,
         'QrCodePreview requires QR code data.',
       );

  final GeneratedCode generatedCode;
  final double size;
  final bool showValue;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: BarcodeWidget(
        data: generatedCode.data,
        barcode: generatedCode.barcode,
        width: size,
        height: size,
        drawText: showValue,
        color: Colors.black,
        backgroundColor: Colors.white,
      ),
    );
  }
}
