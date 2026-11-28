import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:crafting_mpos/features/printer/models/printer_connection_state.dart';
import 'package:crafting_mpos/features/printer/models/printer_device.dart';
import 'package:crafting_mpos/features/printer/services/printer_service.dart';

import '../repositories/fake_printer_repository.dart';

void main() {
  late FakePrinterRepository repository;
  late PrinterService service;

  final printer = PrinterDevice(
    name: 'Thermal Printer',
    address: '00:11:22:33:44:55',
  );

  setUp(() {
    repository = FakePrinterRepository();
    service = PrinterService(repository: repository);
  });

  tearDown(() async {
    await service.dispose();
  });

  group('prepare', () {
    test(
      'returns true when permission is granted and Bluetooth is enabled',
      () async {
        expect(await service.prepare(), isTrue);
        expect(repository.permissionCalls, 1);
        expect(repository.bluetoothEnabledCalls, 1);
      },
    );

    test('returns false when permission is denied', () async {
      repository.permissionGranted = false;

      expect(await service.prepare(), isFalse);
      expect(repository.bluetoothEnabledCalls, 0);
    });

    test('returns false when Bluetooth is disabled', () async {
      repository.bluetoothEnabled = false;

      expect(await service.prepare(), isFalse);
    });

    test('propagates permission exceptions', () async {
      repository.permissionError = Exception('Permission unavailable');

      await expectLater(service.prepare(), throwsA(isA<Exception>()));
    });

    test('propagates Bluetooth status exceptions', () async {
      repository.bluetoothEnabledError = Exception(
        'Bluetooth status unavailable',
      );

      await expectLater(service.prepare(), throwsA(isA<Exception>()));
    });
  });

  group('getPairedDevices', () {
    test('returns paired devices when Bluetooth is ready', () async {
      repository.devices = [printer];

      expect(await service.getPairedDevices(), [printer]);
      expect(repository.pairedDevicesCalls, 1);
    });

    test('does not request devices when permission is denied', () async {
      repository.permissionGranted = false;

      expect(await service.getPairedDevices(), isEmpty);
      expect(repository.pairedDevicesCalls, 0);
    });

    test('does not request devices when Bluetooth is disabled', () async {
      repository.bluetoothEnabled = false;

      expect(await service.getPairedDevices(), isEmpty);
      expect(repository.pairedDevicesCalls, 0);
    });

    test('propagates paired-device retrieval exceptions', () async {
      repository.pairedDevicesError = Exception(
        'Unable to retrieve paired devices',
      );

      await expectLater(service.getPairedDevices(), throwsA(isA<Exception>()));
    });
  });

  group('connect', () {
    test('connects and updates the connection state', () async {
      final states = <PrinterConnectionState>[];
      final subscription = service.stateChanges.listen(states.add);

      expect(await service.connect(printer), isTrue);
      expect(service.state, PrinterConnectionState.connected);
      expect(service.connectedDevice?.address, printer.address);
      expect(repository.lastConnectedAddress, printer.address);

      await Future<void>.delayed(Duration.zero);

      expect(states, [
        PrinterConnectionState.connecting,
        PrinterConnectionState.connected,
      ]);

      await subscription.cancel();
    });

    test('returns true without reconnecting to the same printer', () async {
      expect(await service.connect(printer), isTrue);

      final callsBefore = repository.connectCalls;

      expect(await service.connect(printer), isTrue);
      expect(repository.connectCalls, callsBefore);
    });

    test('does not connect when permission is denied', () async {
      repository.permissionGranted = false;

      expect(await service.connect(printer), isFalse);
      expect(service.state, PrinterConnectionState.error);
      expect(repository.connectCalls, 0);
    });

    test('does not connect when Bluetooth is disabled', () async {
      repository.bluetoothEnabled = false;

      expect(await service.connect(printer), isFalse);
      expect(service.state, PrinterConnectionState.error);
      expect(repository.connectCalls, 0);
    });

    test('sets error state when connection fails', () async {
      repository.connectResult = false;

      expect(await service.connect(printer), isFalse);
      expect(service.state, PrinterConnectionState.error);
      expect(service.connectedDevice, isNull);
    });

    test('disconnects previous printer before connecting another', () async {
      final anotherPrinter = PrinterDevice(
        name: 'Second Printer',
        address: 'AA:BB:CC:DD:EE:FF',
      );

      expect(await service.connect(printer), isTrue);
      expect(await service.connect(anotherPrinter), isTrue);

      expect(repository.disconnectCalls, 1);
      expect(repository.lastConnectedAddress, anotherPrinter.address);
      expect(service.connectedDevice?.address, anotherPrinter.address);
      expect(service.state, PrinterConnectionState.connected);
    });

    test(
      'does not connect another printer if previous disconnect fails',
      () async {
        final anotherPrinter = PrinterDevice(
          name: 'Second Printer',
          address: 'AA:BB:CC:DD:EE:FF',
        );

        expect(await service.connect(printer), isTrue);

        repository.disconnectResult = false;

        expect(await service.connect(anotherPrinter), isFalse);
        expect(repository.connectCalls, 1);
        expect(service.state, PrinterConnectionState.error);
        expect(service.connectedDevice?.address, printer.address);
      },
    );

    test('sets error state and propagates connection exceptions', () async {
      repository.connectError = Exception('Connection failed');
      await expectLater(service.connect(printer), throwsA(isA<Exception>()));
      expect(service.state, PrinterConnectionState.error);
      expect(service.connectedDevice, isNull);
    });

    test(
      'sets error state and propagates previous disconnect exceptions',
      () async {
        final anotherPrinter = PrinterDevice(
          name: 'Second Printer',
          address: 'AA:BB:CC:DD:EE:FF',
        );
        expect(await service.connect(printer), isTrue);
        repository.disconnectError = Exception('Disconnection failed');
        await expectLater(
          service.connect(anotherPrinter),
          throwsA(isA<Exception>()),
        );
        expect(service.state, PrinterConnectionState.error);
        expect(service.connectedDevice?.address, printer.address);
        expect(repository.connectCalls, 1);
      },
    );

    test('serializes concurrent connection requests', () async {
      final anotherPrinter = PrinterDevice(
        name: 'Second Printer',
        address: 'AA:BB:CC:DD:EE:FF',
      );

      final gate = Completer<void>();
      repository.connectGate = gate;

      final firstConnection = service.connect(printer);

      // Allow the first queued operation to reach the repository.
      await Future<void>.delayed(Duration.zero);

      final secondConnection = service.connect(anotherPrinter);

      expect(repository.connectCalls, 1);

      gate.complete();

      expect(await firstConnection, isTrue);
      expect(await secondConnection, isTrue);

      expect(repository.connectCalls, 2);
      expect(repository.disconnectCalls, 1);
      expect(service.state, PrinterConnectionState.connected);
      expect(service.connectedDevice?.address, anotherPrinter.address);
    });

    test('continues processing queued operations after an exception', () async {
      final gate = Completer<void>();
      repository.connectGate = gate;
      repository.connectError = Exception('Connection failed');

      final failedConnection = service.connect(printer);

      await Future<void>.delayed(Duration.zero);

      final queuedDisconnection = service.disconnect();

      expect(repository.connectCalls, 1);
      expect(repository.disconnectCalls, 0);

      gate.complete();

      await expectLater(failedConnection, throwsA(isA<Exception>()));

      expect(await queuedDisconnection, isTrue);

      expect(repository.disconnectCalls, 1);
      expect(service.state, PrinterConnectionState.disconnected);
    });

    test('preserves previous printer when readiness check fails', () async {
      final anotherPrinter = PrinterDevice(
        name: 'Second Printer',
        address: 'AA:BB:CC:DD:EE:FF',
      );

      expect(await service.connect(printer), isTrue);

      repository.permissionGranted = false;

      expect(await service.connect(anotherPrinter), isFalse);

      expect(service.state, PrinterConnectionState.error);
      expect(service.connectedDevice?.address, printer.address);
      expect(repository.disconnectCalls, 0);
      expect(repository.connectCalls, 1);
    });
  });

  group('printBytes', () {
    test('returns false when no printer is connected', () async {
      expect(await service.printBytes([0x1B, 0x40]), isFalse);

      expect(repository.connectionStatusCalls, 0);
      expect(repository.writeCalls, 0);
    });

    test('rejects empty print data', () async {
      await expectLater(service.printBytes([]), throwsArgumentError);

      expect(repository.writeCalls, 0);
    });

    test('prints bytes successfully when connected', () async {
      final bytes = [0x1B, 0x40, 0x1D, 0x56, 0x00];

      expect(await service.connect(printer), isTrue);
      expect(await service.printBytes(bytes), isTrue);

      expect(repository.connectionStatusCalls, 1);
      expect(repository.writeCalls, 1);
      expect(repository.lastWrittenBytes, bytes);
      expect(repository.writtenJobs, [bytes]);
      expect(service.state, PrinterConnectionState.connected);
    });

    test('returns false when repository reports disconnected', () async {
      expect(await service.connect(printer), isTrue);

      repository.connected = false;

      expect(await service.printBytes([0x1B, 0x40]), isFalse);

      expect(repository.writeCalls, 0);
      expect(service.state, PrinterConnectionState.error);
      expect(service.connectedDevice, isNull);
    });

    test('returns false when Bluetooth write fails', () async {
      expect(await service.connect(printer), isTrue);

      repository.writeResult = false;

      expect(await service.printBytes([0x1B, 0x40]), isFalse);

      expect(service.state, PrinterConnectionState.connected);
      expect(service.connectedDevice, printer);
    });

    test('propagates write exceptions without breaking the queue', () async {
      expect(await service.connect(printer), isTrue);

      repository.writeError = Exception('Printer write failed');

      await expectLater(
        service.printBytes([0x1B, 0x40]),
        throwsA(isA<Exception>()),
      );

      repository.writeError = null;

      expect(await service.printBytes([0x1B, 0x40]), isTrue);
      expect(repository.writeCalls, 2);
      expect(service.state, PrinterConnectionState.connected);
    });

    test('serializes concurrent print jobs', () async {
      expect(await service.connect(printer), isTrue);

      final gate = Completer<void>();
      repository.writeGate = gate;

      final firstJob = service.printBytes([0x01, 0x02]);

      await Future<void>.delayed(Duration.zero);

      final secondJob = service.printBytes([0x03, 0x04]);

      expect(repository.writeCalls, 1);

      gate.complete();

      expect(await firstJob, isTrue);
      expect(await secondJob, isTrue);

      expect(repository.writeCalls, 2);
      expect(repository.writtenJobs, [
        [0x01, 0x02],
        [0x03, 0x04],
      ]);
    });

    test('disconnect waits until an active print job finishes', () async {
      expect(await service.connect(printer), isTrue);

      final gate = Completer<void>();
      repository.writeGate = gate;

      final printJob = service.printBytes([0x01, 0x02]);

      await Future<void>.delayed(Duration.zero);

      final disconnection = service.disconnect();

      expect(repository.writeCalls, 1);
      expect(repository.disconnectCalls, 0);

      gate.complete();

      expect(await printJob, isTrue);
      expect(await disconnection, isTrue);

      expect(repository.disconnectCalls, 1);
      expect(service.state, PrinterConnectionState.disconnected);
      expect(service.connectedDevice, isNull);
    });
  });

  group('disconnect', () {
    test('disconnects and updates the connection state', () async {
      expect(await service.connect(printer), isTrue);

      expect(await service.disconnect(), isTrue);
      expect(service.state, PrinterConnectionState.disconnected);
      expect(service.connectedDevice, isNull);
      expect(repository.disconnectCalls, 1);
    });

    test('does nothing when already disconnected', () async {
      expect(await service.disconnect(), isTrue);
      expect(repository.disconnectCalls, 0);
    });

    test('sets error state when disconnection fails', () async {
      expect(await service.connect(printer), isTrue);

      repository.disconnectResult = false;

      expect(await service.disconnect(), isFalse);
      expect(service.state, PrinterConnectionState.error);
      expect(service.connectedDevice?.address, printer.address);
    });

    test('sets error state and propagates disconnection exceptions', () async {
      expect(await service.connect(printer), isTrue);

      repository.disconnectError = Exception('Disconnection failed');

      await expectLater(service.disconnect(), throwsA(isA<Exception>()));

      expect(service.state, PrinterConnectionState.error);
      expect(service.connectedDevice?.address, printer.address);
    });
  });

  group('dispose', () {
    test('throws when operations are attempted after disposal', () async {
      await service.dispose();

      await expectLater(service.prepare(), throwsStateError);
      await expectLater(service.getPairedDevices(), throwsStateError);

      expect(() => service.connect(printer), throwsStateError);

      expect(() => service.disconnect(), throwsStateError);
    });

    test('can be disposed more than once', () async {
      await service.dispose();

      await expectLater(service.dispose(), completes);
    });

    test('concurrent dispose calls share the same future', () async {
      final gate = Completer<void>();
      repository.connectGate = gate;

      final connection = service.connect(printer);

      await Future<void>.delayed(Duration.zero);

      final firstDisposal = service.dispose();
      final secondDisposal = service.dispose();

      expect(identical(firstDisposal, secondDisposal), isTrue);

      gate.complete();

      expect(await connection, isTrue);

      await Future.wait([firstDisposal, secondDisposal]);
    });
  });
}
