import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';

import '../models/generated_code.dart';
import '../models/label_layout_config.dart';
import '../models/product_label_data.dart';

class QrProductLabel extends StatelessWidget {
  QrProductLabel({
    super.key,
    required this.data,
    this.config = const LabelLayoutConfig(
      template: ProductLabelTemplate.qrProduct,
      width: 240,
      height: 160,
      showCodeValue: false,
    ),
  }) : assert(
         config.template == ProductLabelTemplate.qrProduct,
         'QrProductLabel requires the qrProduct template.',
       ),
       assert(
         data.codeFormat == GeneratedCodeFormat.qrCode,
         'QrProductLabel requires QR code data.',
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (config.showProductName)
                  Text(
                    data.productName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                if (config.showVariantName)
                  Text(
                    data.variantName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black, fontSize: 9),
                  ),
                if (config.showCategory && data.categoryName != null)
                  Text(
                    data.categoryName!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black, fontSize: 8),
                  ),
                if (config.showPrice)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      _formatPrice(data.sellingPrice),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (config.showSku && data.sku != null)
                  Text(
                    'SKU: ${data.sku}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black, fontSize: 8),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: AspectRatio(
              aspectRatio: 1,
              child: BarcodeWidget(
                data: data.code,
                barcode: Barcode.qrCode(),
                drawText: config.showCodeValue,
                color: Colors.black,
                backgroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
