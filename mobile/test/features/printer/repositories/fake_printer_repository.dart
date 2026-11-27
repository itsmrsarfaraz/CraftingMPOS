
import 'dart:async';
import 'package:crafting_mpos/features/printer/models/printer_device.dart';
import 'package:crafting_mpos/features/printer/repositories/printer_repository.dart';

class FakePrinterRepository implements PrinterRepository {

  Completer<void>? connectGate;
  Completer<void>? disconnectGate;

  bool permissionGranted = true;
  bool bluetoothEnabled = true;
  bool connectResult = true;
  bool connected = false;
  bool disconnectResult = true;

  Object? permissionError;
  Object? bluetoothEnabledError;
  Object? pairedDevicesError;
  Object? connectError;
  Object? disconnectError;

  List<PrinterDevice> devices = [];

  String? lastConnectedAddress;

  int permissionCalls = 0;
  int bluetoothEnabledCalls = 0;
  int pairedDevicesCalls = 0;
  int connectCalls = 0;
  int connectionStatusCalls = 0;
  int writeCalls = 0;
  int disconnectCalls = 0;

  List<int>? lastWrittenBytes;

  @override
  Future<bool> checkPermission() async {
    permissionCalls++;

    if (permissionError != null) {
      throw permissionError!;
    }

    return permissionGranted;
  }

  @override
  Future<bool> isBluetoothEnabled() async {
    bluetoothEnabledCalls++;

    if (bluetoothEnabledError != null) {
      throw bluetoothEnabledError!;
    }

    return bluetoothEnabled;
  }

  @override
  Future<List<PrinterDevice>> getPairedDevices() async {
    pairedDevicesCalls++;

    if (pairedDevicesError != null) {
      throw pairedDevicesError!;
    }

    return devices;
  }

  @override
  Future<bool> connect(String address) async {
    connectCalls++;
    lastConnectedAddress = address;

    if (connectGate != null) {
      await connectGate!.future;
    }

    if (connectError != null) {
      throw connectError!;
    }

    if (connectResult) {
      connected = true;
    }

    return connectResult;
  }

  @override
  Future<bool> isConnected() async {
    connectionStatusCalls++;
    return connected;
  }

  @override
  Future<bool> write(List<int> bytes) async {
    writeCalls++;
    lastWrittenBytes = List<int>.from(bytes);
    return true;
  }

  @override
  Future<bool> disconnect() async {
    disconnectCalls++;

    if (disconnectGate != null) {
      await disconnectGate!.future;
    }

    if (disconnectError != null) {
      throw disconnectError!;
    }

    if (disconnectResult) {
      connected = false;
    }

    return disconnectResult;
  }
}
