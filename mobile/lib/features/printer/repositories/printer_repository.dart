
import '../models/printer_device.dart';

abstract interface class PrinterRepository {
  Future<bool> checkPermission();

  Future<bool> isBluetoothEnabled();

  Future<List<PrinterDevice>> getPairedDevices();

  Future<bool> connect(String address);

  Future<bool> isConnected();

  Future<bool> write(List<int> bytes);

  Future<bool> disconnect();
}
