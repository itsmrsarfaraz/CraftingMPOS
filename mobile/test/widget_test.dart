import 'package:flutter_test/flutter_test.dart';
import 'package:crafting_mpos/app/crafting_mpos_app.dart';

void main() {
  testWidgets('CraftingMPOS dashboard loads', (WidgetTester tester) async {
    await tester.pumpWidget(const CraftingMposApp());

    expect(find.text('CraftingMPOS'), findsOneWidget);
    expect(find.text('Welcome to CraftingMPOS'), findsOneWidget);
    expect(find.text('Business Modules'), findsOneWidget);
    expect(find.text('Point of Sale'), findsOneWidget);
  });
}
