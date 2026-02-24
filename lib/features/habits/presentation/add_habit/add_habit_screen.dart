import 'package:flutter/material.dart';

class AddHabitScreen extends StatefulWidget {
  final String? initialTitle;
  final int? initialTargetDays;

  const AddHabitScreen({
    super.key,
    this.initialTitle,
    this.initialTargetDays,
  });

  @override
  State<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> {
  late final TextEditingController _controller;

  late int _targetDays;

  bool get _isEdit => (widget.initialTitle ?? '').trim().isNotEmpty;

  static const _options = <int>[0, 7, 14, 21, 30, 60, 90];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialTitle ?? '');
    _targetDays = widget.initialTargetDays ?? 0;
  }

  String _labelFor(int d) {
    if (d == 0) return 'No limit';
    return '$d days';
    }

  void _submit() {
    final title = _controller.text.trim();
    if (title.isEmpty) return;

    Navigator.pop(context, {
      'title': title,
      'targetDays': _targetDays,
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit habit' : 'Add habit')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                labelText: 'Habit name',
                hintText: 'e.g. Study 30 min',
              ),
            ),
            const SizedBox(height: 14),

            // target days dropdown
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Goal duration',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: _targetDays,
              items: _options
                  .map(
                    (d) => DropdownMenuItem<int>(
                      value: d,
                      child: Text(_labelFor(d)),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() => _targetDays = v);
              },
              decoration: const InputDecoration(),
            ),

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submit,
                child: Text(_isEdit ? 'Save' : 'Add'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}