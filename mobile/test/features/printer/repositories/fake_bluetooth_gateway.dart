
import 'package:crafting_mpos/features/printer/models/printer_device.dart';
import 'package:crafting_mpos/features/printer/repositories/bluetooth_gateway.dart';

class FakeBluetoothGateway implements BluetoothGateway {
  bool permissionGranted = true;
  bool bluetoothEnabled = true;
  bool connected = false;
  bool connectResult = true;
  bool writeResult = true;
  bool disconnectResult = true;

  List<PrinterDevice> devices = [];

  String? lastConnectedAddress;
  List<int>? lastWrittenBytes;

  int permissionCalls = 0;
  int bluetoothEnabledCalls = 0;
  int pairedDevicesCalls = 0;
  int connectCalls = 0;
  int connectionStatusCalls = 0;
  int writeCalls = 0;
  int disconnectCalls = 0;

  @override
  Future<bool> ensurePermission() async {
    permissionCalls++;
    return permissionGranted;
  }

  @override
  Future<bool> isBluetoothEnabled() async {
    bluetoothEnabledCalls++;
    return bluetoothEnabled;
  }

  @override
  Future<List<PrinterDevice>> getPairedDevices() async {
    pairedDevicesCalls++;
    return devices;
  }

  @override
  Future<bool> connect(String address) async {
    connectCalls++;
    lastConnectedAddress = address;

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
    return writeResult;
  }

  @override
  Future<bool> disconnect() async {
    disconnectCalls++;

    if (disconnectResult) {
      connected = false;
    }

    return disconnectResult;
  }
}
