
import '../models/printer_device.dart';

abstract interface class BluetoothGateway {
  Future<bool> ensurePermission();

  Future<bool> isBluetoothEnabled();

  Future<List<PrinterDevice>> getPairedDevices();

  Future<bool> connect(String address);

  Future<bool> isConnected();

  Future<bool> write(List<int> bytes);

  Future<bool> disconnect();
}
