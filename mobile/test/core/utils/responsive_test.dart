import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:crafting_mpos/core/utils/responsive.dart';

void main() {
  group('Responsive', () {
    test('uses one column for very narrow screens', () {
      expect(Responsive.gridColumns(320), 1);
    });

    test('uses two columns for standard phone widths', () {
      expect(Responsive.gridColumns(360), 2);
      expect(Responsive.gridColumns(393), 2);
      expect(Responsive.gridColumns(412), 2);
    });

    test('uses three columns for expanded layouts', () {
      expect(Responsive.gridColumns(840), 3);
      expect(Responsive.gridColumns(1024), 3);
    });

    test('adjusts horizontal padding based on available width', () {
      expect(Responsive.horizontalPadding(320), 12);
      expect(Responsive.horizontalPadding(393), 16);
      expect(Responsive.horizontalPadding(600), 24);
      expect(Responsive.horizontalPadding(900), 32);
    });

    testWidgets('identifies compact screens', (tester) async {
      late bool result;

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(393, 852)),
            child: Builder(
              builder: (context) {
                result = Responsive.isCompact(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(result, isTrue);
    });

    testWidgets('identifies medium screens', (tester) async {
      late bool result;

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(700, 900)),
            child: Builder(
              builder: (context) {
                result = Responsive.isMedium(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(result, isTrue);
    });

    testWidgets('identifies expanded screens', (tester) async {
      late bool result;

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(900, 1000)),
            child: Builder(
              builder: (context) {
                result = Responsive.isExpanded(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(result, isTrue);
    });
  });
}
