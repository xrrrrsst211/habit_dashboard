import 'package:flutter_test/flutter_test.dart';
import 'package:habit_dashboard/app/app.dart';

void main() {
testWidgets('App builds', (WidgetTester tester) async {
await tester.pumpWidget(const MyApp(initialDarkMode: false));
await tester.pump(); // даём фрейм отрисоваться

// Просто проверяем, что приложение не упало и MyApp реально построился.
expect(find.byType(MyApp), findsOneWidget);
});
}