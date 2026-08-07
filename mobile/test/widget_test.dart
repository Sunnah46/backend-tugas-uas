import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:evently/main.dart';

void main() {
  testWidgets('App boots to splash screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(EventlyApp(prefs: prefs));
    await tester.pumpAndSettle();
    expect(find.text('Evently'), findsWidgets);
    expect(find.text('Masuk untuk melanjutkan'), findsOneWidget);
  });
}
