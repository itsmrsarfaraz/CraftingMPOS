import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';

import '../models/generated_code.dart';
import '../models/label_layout_config.dart';
import '../models/product_label_data.dart';

class CompactPriceLabel extends StatelessWidget {
  CompactPriceLabel({
    super.key,
    required this.data,
    this.config = const LabelLayoutConfig(
      template: ProductLabelTemplate.compactPrice,
      width: 200,
      height: 100,
      padding: 6,
      showProductName: true,
      showVariantName: false,
      showPrice: true,
      showSku: false,
      showCategory: false,
      showCodeValue: false,
    ),
  }) : assert(
         config.template == ProductLabelTemplate.compactPrice,
         'CompactPriceLabel requires the compactPrice template.',
       ),
       assert(
         data.codeFormat == GeneratedCodeFormat.code128,
         'CompactPriceLabel requires CODE128 data.',
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
        children: [
          if (config.showProductName)
            Text(
              data.productName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          if (config.showPrice)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                _formatPrice(data.sellingPrice),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          Expanded(
            child: BarcodeWidget(
              data: data.code,
              barcode: Barcode.code128(),
              drawText: config.showCodeValue,
              color: Colors.black,
              backgroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
