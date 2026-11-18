import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:crafting_mpos/features/dashboard/presentation/dashboard_screen.dart';

void main() {
  group('DashboardScreen', () {
    const screenWidths = [320.0, 360.0, 393.0, 600.0, 840.0, 1024.0];

    for (final width in screenWidths) {
      testWidgets('renders without overflow at ${width.toInt()} px', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1.0;

        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(const MaterialApp(home: DashboardScreen()));

        await tester.pumpAndSettle();

        expect(find.text('Welcome to CraftingMPOS'), findsOneWidget);
        expect(find.text('Business Modules'), findsOneWidget);

        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('displays all six business modules', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: DashboardScreen()));

      expect(find.text('Point of Sale'), findsOneWidget);
      expect(find.text('Products'), findsOneWidget);
      expect(find.text('Inventory'), findsOneWidget);
      expect(find.text('Customers'), findsOneWidget);
      expect(find.text('Purchases'), findsOneWidget);
      expect(find.text('Reports'), findsOneWidget);
    });

    testWidgets('handles increased system font size on narrow screens', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1.0;

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 900),
              textScaler: TextScaler.linear(1.5),
            ),
            child: const DashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Welcome to CraftingMPOS'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
