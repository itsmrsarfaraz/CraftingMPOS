import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';

import '../models/generated_code.dart';

class BarcodePreview extends StatelessWidget {
  BarcodePreview({
    super.key,
    required this.generatedCode,
    this.height = 100,
    this.showValue = true,
  }) : assert(
         generatedCode.format == GeneratedCodeFormat.code128,
         'BarcodePreview requires CODE128 data.',
       );

  final GeneratedCode generatedCode;
  final double height;
  final bool showValue;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : 240.0;

        return BarcodeWidget(
          data: generatedCode.data,
          barcode: generatedCode.barcode,
          width: width,
          height: height,
          drawText: showValue,
          color: Colors.black,
          backgroundColor: Colors.white,
        );
      },
    );
  }
}
