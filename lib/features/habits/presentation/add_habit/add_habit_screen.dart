import 'package:flutter/material.dart';

class AddHabitScreen extends StatefulWidget {
  final String? initialTitle;
  final int? initialTargetDays;
  final int? initialWeeklyTarget;
  final int? initialReminderMinutes;

  const AddHabitScreen({
    super.key,
    this.initialTitle,
    this.initialTargetDays,
    this.initialWeeklyTarget,
    this.initialReminderMinutes,
  });

  @override
  State<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> {
  late final TextEditingController _controller;

  late int _targetDays;
  late int _weeklyTarget;
  int? _reminderMinutes;

  bool get _isEdit => (widget.initialTitle ?? '').trim().isNotEmpty;

  static const _options = <int>[0, 7, 14, 21, 30, 60, 90];
  static const _weeklyOptions = <int>[0, 1, 2, 3, 4, 5, 6, 7];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialTitle ?? '');
    _targetDays = widget.initialTargetDays ?? 0;
    _weeklyTarget = widget.initialWeeklyTarget ?? 0;
    _reminderMinutes = widget.initialReminderMinutes;

    // Keep goals mutually exclusive.
    if (_weeklyTarget > 0) _targetDays = 0;
  }

  String _labelFor(int d) {
    if (d == 0) return 'No limit';
    return '$d days';
  }

  String _formatMinutes(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    final hh = h.toString().padLeft(2, '0');
    final mm = m.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  Future<void> _pickTime() async {
    final initial = _reminderMinutes ?? (20 * 60);
    final initialTime = TimeOfDay(hour: initial ~/ 60, minute: initial % 60);

    final t = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (t == null) return;
    setState(() => _reminderMinutes = t.hour * 60 + t.minute);
  }

  void _submit() {
    final title = _controller.text.trim();
    if (title.isEmpty) return;

    Navigator.pop(context, {
      'title': title,
      'targetDays': _targetDays,
      'weeklyTarget': _weeklyTarget,
      'reminderMinutes': _reminderMinutes, // null = off
    });
  }

  String _weeklyLabelFor(int n) {
    if (n == 0) return 'Off';
    if (n == 1) return '1 time / week';
    return '$n times / week';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reminderOn = _reminderMinutes != null;

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

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Goals',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),
            // Weekly goal (new)
            DropdownButtonFormField<int>(
              value: _weeklyTarget,
              items: _weeklyOptions
                  .map(
                    (v) => DropdownMenuItem<int>(
                      value: v,
                      child: Text('Weekly goal: ${_weeklyLabelFor(v)}'),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _weeklyTarget = v;
                  if (_weeklyTarget > 0) {
                    // Weekly goal wins.
                    _targetDays = 0;
                  }
                });
              },
              decoration: const InputDecoration(),
            ),

            const SizedBox(height: 10),
            // Duration goal (existing)
            DropdownButtonFormField<int>(
              value: _targetDays,
              items: _options
                  .map(
                    (d) => DropdownMenuItem<int>(
                      value: d,
                      child: Text('Duration goal: ${_labelFor(d)}'),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _targetDays = v;
                  if (_targetDays > 0) {
                    // Duration goal wins.
                    _weeklyTarget = 0;
                  }
                });
              },
              decoration: const InputDecoration(),
            ),

            const SizedBox(height: 16),

            // Reminder UI (notifications not implemented yet)
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Reminder',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Switch(
                  value: reminderOn,
                  onChanged: (v) {
                    setState(() {
                      _reminderMinutes = v ? (20 * 60) : null; // default 20:00
                    });
                  },
                ),
              ],
            ),

            if (reminderOn) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Time: ${_formatMinutes(_reminderMinutes!)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  OutlinedButton(
                    onPressed: _pickTime,
                    child: const Text('Change'),
                  ),
                ],
              ),
            ],

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