
import 'package:flutter_test/flutter_test.dart';
import 'package:crafting_mpos/features/printer/models/printer_device.dart';
import 'package:crafting_mpos/features/printer/repositories/bluetooth_printer_repository.dart';

import 'fake_bluetooth_gateway.dart';

void main() {
  late FakeBluetoothGateway gateway;
  late BluetoothPrinterRepository repository;

  setUp(() {
    gateway = FakeBluetoothGateway();
    repository = BluetoothPrinterRepository(gateway: gateway);
  });

  group('BluetoothPrinterRepository', () {
    test('checks Bluetooth permission through the gateway', () async {
      final result = await repository.checkPermission();

      expect(result, isTrue);
      expect(gateway.permissionCalls, 1);
    });

    test('returns false when permission is denied', () async {
      gateway.permissionGranted = false;

      final result = await repository.checkPermission();

      expect(result, isFalse);
      expect(gateway.permissionCalls, 1);
    });

    test('checks whether Bluetooth is enabled', () async {
      final result = await repository.isBluetoothEnabled();

      expect(result, isTrue);
      expect(gateway.bluetoothEnabledCalls, 1);
    });

    test('returns false when Bluetooth is disabled', () async {
      gateway.bluetoothEnabled = false;

      final result = await repository.isBluetoothEnabled();

      expect(result, isFalse);
    });

    test('returns paired printer devices', () async {
      gateway.devices = [
        PrinterDevice(
          name: 'Thermal Printer',
          address: 'AA:BB:CC:DD:EE:FF',
        ),
      ];

      final result = await repository.getPairedDevices();

      expect(result, hasLength(1));
      expect(result.first.name, 'Thermal Printer');
      expect(result.first.address, 'AA:BB:CC:DD:EE:FF');
      expect(gateway.pairedDevicesCalls, 1);
    });

    test('connects to a printer using the supplied address', () async {
      const address = 'AA:BB:CC:DD:EE:FF';

      final result = await repository.connect(address);

      expect(result, isTrue);
      expect(gateway.lastConnectedAddress, address);
      expect(gateway.connectCalls, 1);
    });

    test('returns false when connection fails', () async {
      gateway.connectResult = false;

      final result = await repository.connect('AA:BB:CC:DD:EE:FF');

      expect(result, isFalse);
      expect(gateway.connectCalls, 1);
    });

    test('checks the current connection state', () async {
      gateway.connected = true;

      final result = await repository.isConnected();

      expect(result, isTrue);
      expect(gateway.connectionStatusCalls, 1);
    });

    test('writes ESC/POS bytes through the gateway', () async {
      final bytes = [0x1B, 0x40, 0x0A];

      final result = await repository.write(bytes);

      expect(result, isTrue);
      expect(gateway.lastWrittenBytes, bytes);
      expect(gateway.writeCalls, 1);
    });

    test('returns false when writing fails', () async {
      gateway.writeResult = false;

      final result = await repository.write([0x1B, 0x40]);

      expect(result, isFalse);
    });

    test('disconnects from the printer', () async {
      gateway.connected = true;

      final result = await repository.disconnect();

      expect(result, isTrue);
      expect(gateway.disconnectCalls, 1);
      expect(gateway.connected, isFalse);
    });

    test('returns false when disconnection fails', () async {
      gateway.connected = true;
      gateway.disconnectResult = false;

      final result = await repository.disconnect();

      expect(result, isFalse);
      expect(gateway.connected, isTrue);
    });
  });
}
