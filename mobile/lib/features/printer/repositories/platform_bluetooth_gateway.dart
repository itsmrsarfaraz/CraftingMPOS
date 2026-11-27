
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

import '../models/printer_device.dart';
import 'bluetooth_gateway.dart';

class PlatformBluetoothGateway implements BluetoothGateway {
  @override
  Future<bool> ensurePermission() async {
    return PrintBluetoothThermal.isPermissionBluetoothGranted;
  }

  @override
  Future<bool> isBluetoothEnabled() async {
    return PrintBluetoothThermal.bluetoothEnabled;
  }

  @override
  Future<List<PrinterDevice>> getPairedDevices() async {
    final devices = await PrintBluetoothThermal.pairedBluetooths;
    final result = <PrinterDevice>[];
    final seenAddresses = <String>{};

    for (final device in devices) {
      try {
        final printer = PrinterDevice(
          name: device.name,
          address: device.macAdress,
        );

        if (seenAddresses.add(printer.address)) {
          result.add(printer);
        }
      } on ArgumentError {
        // Ignore malformed platform device records.
      }
    }

    return result;
  }

  @override
  Future<bool> connect(String address) async {
    final normalizedAddress = address.trim().toUpperCase();

    if (!RegExp(r'^[0-9A-F]{2}(:[0-9A-F]{2}){5}$')
        .hasMatch(normalizedAddress)) {
      throw ArgumentError.value(
        address,
        'address',
        'A valid Bluetooth MAC address is required.',
      );
    }

    return PrintBluetoothThermal.connect(
      macPrinterAddress: normalizedAddress,
    );
  }

  @override
  Future<bool> isConnected() async {
    return PrintBluetoothThermal.connectionStatus;
  }

  @override
  Future<bool> write(List<int> bytes) async {
    return PrintBluetoothThermal.writeBytes(bytes);
  }

  @override
  Future<bool> disconnect() async {
    return PrintBluetoothThermal.disconnect;
  }
}
