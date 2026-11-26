import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

import '../models/receipt_data.dart';
import 'esc_pos_builder.dart';

/// Builds ESC/POS commands for sales receipts.
class ReceiptBuilder {
  ReceiptBuilder({required this.escPosBuilder});

  final EscPosBuilder escPosBuilder;

  /// Generates a complete receipt print job.
  List<int> build(ReceiptData receipt) {
    final generator = escPosBuilder.createGenerator();
    final commands = <int>[...escPosBuilder.initialize(generator)];

    commands.addAll(
      escPosBuilder.buildText(
        generator,
        receipt.storeName,
        alignment: PosAlign.center,
        bold: true,
        doubleWidth: true,
        doubleHeight: true,
        linesAfter: 1,
      ),
    );

    if (receipt.storeAddress?.isNotEmpty ?? false) {
      commands.addAll(
        escPosBuilder.buildText(
          generator,
          receipt.storeAddress!,
          alignment: PosAlign.center,
        ),
      );
    }

    if (receipt.storePhone?.isNotEmpty ?? false) {
      commands.addAll(
        escPosBuilder.buildText(
          generator,
          receipt.storePhone!,
          alignment: PosAlign.center,
        ),
      );
    }

    commands.addAll(
      escPosBuilder.buildText(
        generator,
        'Receipt: ${receipt.receiptNumber}',
        linesAfter: 1,
      ),
    );

    commands.addAll(
      escPosBuilder.buildText(
        generator,
        'Date: ${_formatDate(receipt.issuedAt)}',
      ),
    );

    commands.addAll(
      escPosBuilder.buildText(generator, '--------------------------------'),
    );

    for (final item in receipt.items) {
      commands.addAll(
        generator.row([
          PosColumn(
            text: '${item.productName} - ${item.variantName}',
            width: 12,
            styles: const PosStyles(bold: true),
          ),
        ], multiLine: true),
      );

      commands.addAll(
        _buildRow(
          generator,
          '${_formatQuantity(item.quantityMilliunits)} ${item.unit} x ${_formatMoney(item.unitPricePaisa).replaceFirst('Rs. ', '')}',
          _formatMoney(item.lineTotalPaisa).replaceFirst('Rs. ', ''),
        ),
      );

      commands.addAll(escPosBuilder.buildFeed(generator, lines: 1));
    }

    commands.addAll(
      escPosBuilder.buildText(generator, '--------------------------------'),
    );

    commands.addAll(
      _buildRow(generator, 'Subtotal', _formatMoney(receipt.subtotalPaisa)),
    );

    commands.addAll(
      _buildRow(generator, 'Discount', _formatMoney(receipt.discountPaisa)),
    );

    commands.addAll(
      _buildRow(generator, 'Tax', _formatMoney(receipt.taxPaisa)),
    );

    commands.addAll(
      escPosBuilder.buildText(generator, '--------------------------------'),
    );

    commands.addAll(
      escPosBuilder.buildText(
        generator,
        'TOTAL: ${_formatMoney(receipt.grandTotalPaisa)}',
        alignment: PosAlign.right,
        bold: true,
        doubleWidth: true,
        doubleHeight: true,
        linesAfter: 1,
      ),
    );

    commands.addAll(
      escPosBuilder.buildText(generator, 'Payment: ${receipt.paymentMethod}'),
    );

    commands.addAll(
      _buildRow(generator, 'Paid', _formatMoney(receipt.amountPaidPaisa)),
    );

    commands.addAll(
      _buildRow(generator, 'Change', _formatMoney(receipt.changePaisa)),
    );

    if (receipt.footerMessage?.isNotEmpty ?? false) {
      commands.addAll(
        escPosBuilder.buildText(
          generator,
          receipt.footerMessage!,
          alignment: PosAlign.center,
          linesAfter: 1,
        ),
      );
    }

    commands.addAll(escPosBuilder.buildFeed(generator, lines: 3));
    commands.addAll(escPosBuilder.buildCut(generator));

    return commands;
  }

  String _formatMoney(int paisa) {
    final rupees = paisa ~/ 100;
    final remainingPaisa = (paisa % 100).toString().padLeft(2, '0');

    return 'Rs. $rupees.$remainingPaisa';
  }

  String _formatQuantity(int milliunits) {
    final wholeUnits = milliunits ~/ 1000;
    final remainingMilliunits = milliunits % 1000;

    if (remainingMilliunits == 0) {
      return wholeUnits.toString();
    }

    final decimal = remainingMilliunits
        .toString()
        .padLeft(3, '0')
        .replaceFirst(RegExp(r'0+$'), '');

    return '$wholeUnits.$decimal';
  }

  String _formatDate(DateTime dateTime) {
    final date =
        '${dateTime.year.toString().padLeft(4, '0')}-'
        '${dateTime.month.toString().padLeft(2, '0')}-'
        '${dateTime.day.toString().padLeft(2, '0')}';

    final time =
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';

    return '$date $time';
  }
}

List<int> _buildRow(
  Generator generator,
  String left,
  String right, {
  bool bold = false,
}) {
  return generator.row([
    PosColumn(
      text: left,
      width: 8,
      styles: PosStyles(bold: bold, align: PosAlign.left),
    ),
    PosColumn(
      text: right,
      width: 4,
      styles: PosStyles(bold: bold, align: PosAlign.right),
    ),
  ], multiLine: true);
}
