import 'package:flutter_test/flutter_test.dart';

import 'package:flashlight_app/main.dart';

void main() {
  testWidgets('Home screen shows OFF state', (WidgetTester tester) async {
    await tester.pumpWidget(const FlashlightApp());

    expect(find.text('Flashlight'), findsOneWidget);
    expect(find.text('Chiroq o‘chiq'), findsOneWidget);
    expect(find.text('Maslahat'), findsOneWidget);
  });
}