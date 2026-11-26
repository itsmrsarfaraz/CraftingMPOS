enum PrinterPaperWidth {
  mm58,
  mm80;

  int get millimeters {
    switch (this) {
      case PrinterPaperWidth.mm58:
        return 58;
      case PrinterPaperWidth.mm80:
        return 80;
    }
  }
}

class PrinterConfiguration {
  factory PrinterConfiguration({
    required String printerName,
    required String printerAddress,
    PrinterPaperWidth paperWidth = PrinterPaperWidth.mm58,
    String capabilityProfileName = 'default',
  }) {
    final normalizedName = printerName.trim();
    final normalizedAddress = printerAddress.trim();
    final normalizedProfileName = capabilityProfileName.trim();

    if (normalizedName.isEmpty) {
      throw ArgumentError.value(
        printerName,
        'printerName',
        'Printer name cannot be empty.',
      );
    }

    if (!RegExp(r'^[0-9A-Fa-f]{2}(:[0-9A-Fa-f]{2}){5}$')
        .hasMatch(normalizedAddress)) {
      throw ArgumentError.value(
        printerAddress,
        'printerAddress',
        'Printer address must be a valid Bluetooth MAC address.',
      );
    }

    if (normalizedProfileName.isEmpty) {
      throw ArgumentError.value(
        capabilityProfileName,
        'capabilityProfileName',
        'Capability profile name cannot be empty.',
      );
    }

    return PrinterConfiguration._(
      printerName: normalizedName,
      printerAddress: normalizedAddress,
      paperWidth: paperWidth,
      capabilityProfileName: normalizedProfileName,
    );
  }

  const PrinterConfiguration._({
    required this.printerName,
    required this.printerAddress,
    required this.paperWidth,
    required this.capabilityProfileName,
  });

  final String printerName;

  /// Bluetooth Classic MAC address.
  final String printerAddress;

  final PrinterPaperWidth paperWidth;

  /// Name of the ESC/POS capability profile.
  final String capabilityProfileName;
}
