
import 'package:flutter_test/flutter_test.dart';
import 'package:crafting_mpos/features/printer/models/printer_connection_state.dart';

void main() {
  group('PrinterConnectionState', () {
    test('Defines all supported connection states', () {
      expect(
        PrinterConnectionState.values,
        [
          PrinterConnectionState.disconnected,
          PrinterConnectionState.connecting,
          PrinterConnectionState.connected,
          PrinterConnectionState.disconnecting,
          PrinterConnectionState.error,
        ],
      );
    });

    test('Contains five distinct connection states', () {
      expect(PrinterConnectionState.values.length, 5);
    });
  });
}
