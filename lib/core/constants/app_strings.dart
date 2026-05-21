import 'package:habit_dashboard/core/localization/app_localizations.dart';

class AppStrings {
  static String get appTitle => 'Daily Habit Dashboard'.tr;

  static String get today => 'Today'.tr;

  static String get progressTitle => 'Daily progress'.tr;
  static String get progressSubtitle => '{done} / {total} habits completed'.tr;

  static String get emptyTitle => 'No habits yet'.tr;
  static String get emptySubtitle => 'Tap + to add your first habit.'.tr;
}
