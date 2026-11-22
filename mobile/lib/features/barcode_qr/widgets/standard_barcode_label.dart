import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';

import '../models/generated_code.dart';
import '../models/label_layout_config.dart';
import '../models/product_label_data.dart';

class StandardBarcodeLabel extends StatelessWidget {
  StandardBarcodeLabel({
    super.key,
    required this.data,
    this.config = const LabelLayoutConfig(
      template: ProductLabelTemplate.standardBarcode,
    ),
  }) : assert(
         config.template == ProductLabelTemplate.standardBarcode,
         'StandardBarcodeLabel requires the standardBarcode template.',
       ),
       assert(
         data.codeFormat == GeneratedCodeFormat.code128,
         'StandardBarcodeLabel requires CODE128 data.',
       );

  final ProductLabelData data;
  final LabelLayoutConfig config;

  String _formatPrice(int paisa) {
    final rupees = paisa ~/ 100;
    final remainingPaisa = (paisa % 100).toString().padLeft(2, '0');

    return 'Rs. $rupees.$remainingPaisa';
  }

  @override
  Widget build(BuildContext context) {
    final barcode = Barcode.code128();

    return Container(
      width: config.width,
      height: config.height,
      padding: EdgeInsets.all(config.padding),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (config.showProductName)
            Text(
              data.productName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          if (config.showVariantName)
            Text(
              data.variantName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.black, fontSize: 10),
            ),
          if (config.showCategory && data.categoryName != null)
            Text(
              data.categoryName!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.black, fontSize: 9),
            ),
          Expanded(
            child: BarcodeWidget(
              data: data.code,
              barcode: barcode,
              width: double.infinity,
              height: double.infinity,
              drawText: config.showCodeValue,
              color: Colors.black,
              backgroundColor: Colors.white,
            ),
          ),
          if (config.showPrice)
            Text(
              _formatPrice(data.sellingPrice),
              style: const TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          if (config.showSku && data.sku != null)
            Text(
              'SKU: ${data.sku}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.black, fontSize: 9),
            ),
        ],
      ),
    );
  }
}
