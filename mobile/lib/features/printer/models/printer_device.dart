
class PrinterDevice {
  factory PrinterDevice({
    required String name,
    required String address,
  }) {
    final normalizedName = name.trim();
    final normalizedAddress = address.trim().toUpperCase();

    if (normalizedName.isEmpty) {
      throw ArgumentError.value(
        name,
        'name',
        'Printer device name cannot be empty.',
      );
    }

    if (!RegExp(r'^[0-9A-F]{2}(:[0-9A-F]{2}){5}$')
        .hasMatch(normalizedAddress)) {
      throw ArgumentError.value(
        address,
        'address',
        'Printer address must be a valid Bluetooth MAC address.',
      );
    }

    return PrinterDevice._(
      name: normalizedName,
      address: normalizedAddress,
    );
  }

  const PrinterDevice._({
    required this.name,
    required this.address,
  });

  final String name;

  /// Bluetooth Classic MAC address.
  final String address;
}
