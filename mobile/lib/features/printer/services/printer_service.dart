
import 'dart:async';

import '../models/printer_connection_state.dart';
import '../models/printer_device.dart';
import '../repositories/printer_repository.dart';

class PrinterService {
  PrinterService({
    required this._repository,
  });

  final PrinterRepository _repository;

  final StreamController<PrinterConnectionState> _stateController =
      StreamController<PrinterConnectionState>.broadcast();

  Future<void> _operationQueue = Future<void>.value();

  PrinterConnectionState _state = PrinterConnectionState.disconnected;
  PrinterDevice? _connectedDevice;
  bool _disposed = false;
  Future<void>? _disposeFuture;

  PrinterConnectionState get state => _state;

  PrinterDevice? get connectedDevice => _connectedDevice;

  Stream<PrinterConnectionState> get stateChanges =>
      _stateController.stream;

  /// Checks Bluetooth permission and whether Bluetooth is enabled.
  Future<bool> prepare() async {
    _ensureActive();
    return _isReady();
  }

  Future<bool> _isReady() async {
    final permissionGranted = await _repository.checkPermission();

    if (!permissionGranted) {
      return false;
    }

    return _repository.isBluetoothEnabled();
  }

  /// Returns paired devices only when Bluetooth is ready.
  Future<List<PrinterDevice>> getPairedDevices() async {
    _ensureActive();

    if (!await _isReady()) {
      return const [];
    }

    return _repository.getPairedDevices();
  }

  /// Connects to a printer and updates the connection state.
  Future<bool> connect(PrinterDevice device) {
    return _enqueue(() async {
      if (_state == PrinterConnectionState.connected &&
          _connectedDevice?.address == device.address) {
        return true;
      }

      _setState(PrinterConnectionState.connecting);

      try {
        if (!await _isReady()) {
          _setState(PrinterConnectionState.error);
          return false;
        }

        if (_connectedDevice != null) {
          _setState(PrinterConnectionState.disconnecting);

          final disconnected = await _repository.disconnect();

          if (!disconnected) {
            _setState(PrinterConnectionState.error);
            return false;
          }

          _connectedDevice = null;
          _setState(PrinterConnectionState.connecting);
        }

        final connected = await _repository.connect(device.address);

        if (!connected) {
          _connectedDevice = null;
          _setState(PrinterConnectionState.error);
          return false;
        }

        _connectedDevice = device;
        _setState(PrinterConnectionState.connected);

        return true;
      } catch (_) {
        _setState(PrinterConnectionState.error);
        rethrow;
      }
    });
  }

  /// Disconnects from the current printer.
  Future<bool> disconnect() {
    return _enqueue(() async {
      if (_state == PrinterConnectionState.disconnected &&
          _connectedDevice == null) {
        return true;
      }

      _setState(PrinterConnectionState.disconnecting);

      try {
        final disconnected = await _repository.disconnect();

        if (!disconnected) {
          _setState(PrinterConnectionState.error);
          return false;
        }

        _connectedDevice = null;
        _setState(PrinterConnectionState.disconnected);

        return true;
      } catch (_) {
        _setState(PrinterConnectionState.error);
        rethrow;
      }
    });
  }

  void _setState(PrinterConnectionState newState) {
    if (_state == newState) {
      return;
    }

    _state = newState;
    _stateController.add(newState);
  }

  /// Serializes connection and disconnection operations.
  Future<T> _enqueue<T>(Future<T> Function() operation) {
    _ensureActive();

    final completer = Completer<T>();

    _operationQueue = _operationQueue.then((_) async {
      try {
        completer.complete(await operation());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });

    return completer.future;
  }

  void _ensureActive() {
    if (_disposed) {
      throw StateError('PrinterService has already been disposed.');
    }
  }

  /// Releases the state stream after pending operations finish.
  Future<void> dispose() {
    return _disposeFuture ??= _dispose();
  }

  Future<void> _dispose() async {
    _disposed = true;

    await _operationQueue;
    await _stateController.close();
  }
}
