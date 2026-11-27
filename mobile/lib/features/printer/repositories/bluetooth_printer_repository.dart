
import '../models/printer_device.dart';
import 'bluetooth_gateway.dart';
import 'printer_repository.dart';
import 'platform_bluetooth_gateway.dart';

class BluetoothPrinterRepository implements PrinterRepository {
  BluetoothPrinterRepository({
    BluetoothGateway? gateway,
  }) : _gateway = gateway ?? PlatformBluetoothGateway();

  final BluetoothGateway _gateway;

  @override
  Future<bool> checkPermission() {
    return _gateway.ensurePermission();
  }

  @override
  Future<bool> isBluetoothEnabled() {
    return _gateway.isBluetoothEnabled();
  }

  @override
  Future<List<PrinterDevice>> getPairedDevices() {
    return _gateway.getPairedDevices();
  }

  @override
  Future<bool> connect(String address) {
    return _gateway.connect(address);
  }

  @override
  Future<bool> isConnected() {
    return _gateway.isConnected();
  }

  @override
  Future<bool> write(List<int> bytes) {
    return _gateway.write(bytes);
  }

  @override
  Future<bool> disconnect() {
    return _gateway.disconnect();
  }
}
