import 'package:flutter/material.dart';
import 'package:habit_dashboard/features/habits/domain/habit.dart';

class AddHabitScreen extends StatefulWidget {
  final String? initialTitle;
  final String? initialType;
  final int? initialTargetDays;
  final int? initialWeeklyTarget;
  final int? initialReminderMinutes;
  final List<int>? initialReminderWeekdays;
  final bool? initialReminderOnlyIfIncomplete;
  final bool? initialReminderEveningNudge;
  final String? initialReminderMessage;
  final String? initialNotes;
  final String? initialIconKey;
  final int? initialColorValue;

  const AddHabitScreen({
    super.key,
    this.initialTitle,
    this.initialType,
    this.initialTargetDays,
    this.initialWeeklyTarget,
    this.initialReminderMinutes,
    this.initialReminderWeekdays,
    this.initialReminderOnlyIfIncomplete,
    this.initialReminderEveningNudge,
    this.initialReminderMessage,
    this.initialNotes,
    this.initialIconKey,
    this.initialColorValue,
  });

  @override
  State<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> {
  late final TextEditingController _controller;
  late final TextEditingController _notesController;
  late final TextEditingController _reminderMessageController;

  late String _type;
  late int _targetDays;
  late int _weeklyTarget;
  int? _reminderMinutes;
  late List<int> _reminderWeekdays;
  late bool _reminderOnlyIfIncomplete;
  late bool _reminderEveningNudge;
  late String _iconKey;
  late int _colorValue;

  bool get _isEdit => (widget.initialTitle ?? '').trim().isNotEmpty;

  static const _options = <int>[0, 7, 14, 21, 30, 60, 90];
  static const _weeklyOptions = <int>[0, 1, 2, 3, 4, 5, 6, 7];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialTitle ?? '');
    _notesController = TextEditingController(text: widget.initialNotes ?? '');
    _reminderMessageController = TextEditingController(text: widget.initialReminderMessage ?? '');
    _type = widget.initialType ?? Habit.typeBuild;
    _targetDays = widget.initialTargetDays ?? 0;
    _weeklyTarget = widget.initialWeeklyTarget ?? 0;
    _reminderMinutes = widget.initialReminderMinutes;
    _reminderWeekdays = List<int>.from(widget.initialReminderWeekdays ?? Habit.defaultReminderWeekdays);
    _reminderOnlyIfIncomplete = widget.initialReminderOnlyIfIncomplete ?? true;
    _reminderEveningNudge = widget.initialReminderEveningNudge ?? false;
    _iconKey = widget.initialIconKey ?? Habit.defaultIconKey;
    _colorValue = widget.initialColorValue ?? Habit.defaultColorValue;

    if (_weeklyTarget > 0) _targetDays = 0;
  }

  @override
  void dispose() {
    _controller.dispose();
    _notesController.dispose();
    _reminderMessageController.dispose();
    super.dispose();
  }

  String _labelFor(int d) => d == 0 ? 'No limit' : '$d days';

  String _weeklyLabelFor(int n) {
    if (n == 0) return 'Off';
    if (n == 1) return '1 time / week';
    return '$n times / week';
  }

  String _formatMinutes(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  String _weekdayLabel(int weekday) {
    const labels = <int, String>{1: 'M', 2: 'T', 3: 'W', 4: 'T', 5: 'F', 6: 'S', 7: 'S'};
    return labels[weekday] ?? '?';
  }

  Future<void> _pickTime() async {
    final initial = _reminderMinutes ?? (20 * 60);
    final initialTime = TimeOfDay(hour: initial ~/ 60, minute: initial % 60);
    final t = await showTimePicker(context: context, initialTime: initialTime);
    if (t == null) return;
    setState(() => _reminderMinutes = t.hour * 60 + t.minute);
  }

  void _toggleWeekday(int weekday) {
    final next = List<int>.from(_reminderWeekdays);
    if (next.contains(weekday)) {
      if (next.length == 1) return;
      next.remove(weekday);
    } else {
      next.add(weekday);
      next.sort();
    }
    setState(() => _reminderWeekdays = next);
  }

  void _submit() {
    final title = _controller.text.trim();
    if (title.isEmpty) return;

    Navigator.pop(context, {
      'title': title,
      'type': _type,
      'targetDays': _targetDays,
      'weeklyTarget': _weeklyTarget,
      'reminderMinutes': _reminderMinutes,
      'reminderWeekdays': _reminderWeekdays,
      'reminderOnlyIfIncomplete': _reminderOnlyIfIncomplete,
      'reminderEveningNudge': _reminderEveningNudge,
      'reminderMessage': _reminderMessageController.text.trim(),
      'notes': _notesController.text.trim(),
      'iconKey': _iconKey,
      'colorValue': _colorValue,
    });
  }

  @override
  Widget build(BuildContext context) {
    final reminderOn = _reminderMinutes != null;
    final accent = Color(_colorValue);
    final cs = Theme.of(context).colorScheme;
    final previewHabit = Habit(
      id: 'preview',
      title: _controller.text.trim().isEmpty ? 'Your habit preview' : _controller.text.trim(),
      type: _type,
      completedDates: const <String>{},
      skippedDates: const <String>{},
      slipDates: const <String>{},
      bestStreak: 0,
      targetDays: _targetDays,
      weeklyTarget: _weeklyTarget,
      archived: false,
      reminderMinutes: _reminderMinutes,
      reminderWeekdays: _reminderWeekdays,
      reminderOnlyIfIncomplete: _reminderOnlyIfIncomplete,
      reminderEveningNudge: _reminderEveningNudge,
      reminderMessage: _reminderMessageController.text.trim(),
      notes: _notesController.text.trim(),
      iconKey: _iconKey,
      colorValue: _colorValue,
    );

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit habit' : 'Add habit')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accent.withOpacity(0.18)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(Habit.iconDataFor(_iconKey), color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            previewHabit.title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${previewHabit.typeLabel} • ${Habit.iconLabelFor(_iconKey)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: cs.onSurface.withOpacity(0.7),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                autofocus: true,
                textInputAction: TextInputAction.done,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: _type == Habit.typeQuit ? 'What do you want to quit?' : 'Habit name',
                  hintText: _type == Habit.typeQuit ? 'e.g. No smoking' : 'e.g. Study 30 min',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _notesController,
                minLines: 2,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  labelText: _type == Habit.typeQuit ? 'Reason / motivation' : 'Note / why this matters',
                  hintText: _type == Habit.typeQuit
                      ? 'e.g. Better breathing, save money, feel cleaner'
                      : 'e.g. Helps me focus, energy, mood, consistency',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _type == Habit.typeQuit
                    ? 'Add a short reason to remember why you want to stay clean.'
                    : 'Optional note for your goal, motivation, or a simple reminder.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withOpacity(0.72),
                    ),
              ),
              const SizedBox(height: 18),
              Text('Habit type', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Build'),
                    avatar: const Icon(Icons.trending_up_rounded, size: 18),
                    selected: _type == Habit.typeBuild,
                    onSelected: (_) => setState(() => _type = Habit.typeBuild),
                  ),
                  ChoiceChip(
                    label: const Text('Quit'),
                    avatar: const Icon(Icons.block_rounded, size: 18),
                    selected: _type == Habit.typeQuit,
                    onSelected: (_) => setState(() => _type = Habit.typeQuit),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _type == Habit.typeQuit
                    ? 'Use quit habits for things like smoking, alcohol, vaping, sugar, or junk food.'
                    : 'Use build habits for actions you want to practice consistently.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withOpacity(0.72),
                    ),
              ),
              const SizedBox(height: 18),
              Text('Icon', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: Habit.iconKeys.map((key) {
                  final selected = _iconKey == key;
                  return InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => setState(() => _iconKey = key),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: selected ? accent.withOpacity(0.16) : cs.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected ? accent : cs.outline.withOpacity(0.24),
                          width: selected ? 1.8 : 1,
                        ),
                      ),
                      child: Icon(Habit.iconDataFor(key), color: selected ? accent : cs.onSurface),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              Text('Color', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: Habit.colorValues.map((value) {
                  final selected = _colorValue == value;
                  final color = Color(value);
                  return InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () => setState(() => _colorValue = value),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                        border: Border.all(
                          color: selected ? cs.onSurface : Colors.transparent,
                          width: 2,
                        ),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: color.withOpacity(0.28),
                                  blurRadius: 10,
                                ),
                              ]
                            : null,
                      ),
                      child: selected
                          ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              Text('Goal style', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: _weeklyTarget,
                items: _weeklyOptions
                    .map((n) => DropdownMenuItem<int>(
                          value: n,
                          child: Text('Weekly goal: ${_weeklyLabelFor(n)}'),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() {
                    _weeklyTarget = v;
                    if (_weeklyTarget > 0) _targetDays = 0;
                  });
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                value: _targetDays,
                items: _options
                    .map((d) => DropdownMenuItem<int>(
                          value: d,
                          child: Text('Duration goal: ${_labelFor(d)}'),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() {
                    _targetDays = v;
                    if (_targetDays > 0) _weeklyTarget = 0;
                  });
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text('Reminder', style: Theme.of(context).textTheme.titleMedium),
                  ),
                  Switch(
                    value: reminderOn,
                    onChanged: (v) => setState(() => _reminderMinutes = v ? (20 * 60) : null),
                  ),
                ],
              ),
              if (reminderOn) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: Text('Time: ${_formatMinutes(_reminderMinutes!)}')),
                    OutlinedButton(onPressed: _pickTime, child: const Text('Change')),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Reminder days', style: Theme.of(context).textTheme.titleSmall),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List<Widget>.generate(7, (index) {
                    final weekday = index + 1;
                    return FilterChip(
                      label: Text(_weekdayLabel(weekday)),
                      selected: _reminderWeekdays.contains(weekday),
                      onSelected: (_) => _toggleWeekday(weekday),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _reminderMessageController,
                  decoration: const InputDecoration(
                    labelText: 'Custom reminder message',
                    hintText: 'Optional',
                  ),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _reminderOnlyIfIncomplete,
                  onChanged: (v) => setState(() => _reminderOnlyIfIncomplete = v),
                  title: const Text('Only if not completed yet'),
                  subtitle: const Text('Useful wording for nudges and accountability.'),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _reminderEveningNudge,
                  onChanged: (v) => setState(() => _reminderEveningNudge = v),
                  title: const Text('Evening nudge'),
                  subtitle: const Text('Adds a softer later reminder on selected days.'),
                ),
              ],
              const SizedBox(height: 20),
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
      ),
    );
  }
}
