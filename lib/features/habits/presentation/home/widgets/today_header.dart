import 'package:flutter/material.dart';
import '../../../../../core/constants/app_strings.dart';

class TodayHeader extends StatelessWidget {
  const TodayHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      AppStrings.today,
      style: Theme.of(context).textTheme.headlineMedium,
    );
  }
}