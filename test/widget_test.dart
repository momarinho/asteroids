import 'package:flutter_test/flutter_test.dart';
import 'package:asteroids/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Asteroids Multiplatform launches and displays MenuOverlay', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('ASTEROIDS'), findsOneWidget);
    expect(find.text('MULTIPLATFORM EDITION'), findsOneWidget);
  });
}
