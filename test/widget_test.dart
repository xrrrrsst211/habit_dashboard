import 'package:flutter_test/flutter_test.dart';
import 'package:habit_dashboard/app/app.dart';

void main() {
  testWidgets('App builds', (WidgetTester tester) async {
    await tester.pumpWidget(const HabitDashboardApp());
    expect(find.text('Daily Habit Dashboard'), findsOneWidget);
  });
}