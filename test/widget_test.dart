import 'package:flutter_test/flutter_test.dart';
import 'package:disaster_response/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const RescueNetApp());
    expect(find.text('RescueNet'), findsAny);
  });
}
