import 'package:flutter/material.dart';

class HabitTile extends StatelessWidget {
  final String title;
  final bool done;
  final VoidCallback onToggle;

  const HabitTile({
    super.key,
    required this.title,
    required this.done,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        trailing: IconButton(
          onPressed: onToggle,
          icon: Icon(
            done ? Icons.check_circle : Icons.radio_button_unchecked,
          ),
        ),
        onTap: onToggle,
      ),
    );
  }
}