import 'package:flutter_test/flutter_test.dart';
import 'package:habit_dashboard/app/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App builds', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(initialDarkMode: false));
    await tester.pumpAndSettle();

    expect(find.byType(MyApp), findsOneWidget);
  });
}
