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
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit habit' : 'Add habit'),
        actions: [
          TextButton(
            onPressed: _submit,
            child: const Text('Save'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      accent.withOpacity(0.18),
                      accent.withOpacity(0.08),
                      cs.surface,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: accent.withOpacity(0.20)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withOpacity(0.24),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(Habit.iconDataFor(_iconKey), color: Colors.white),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            previewHabit.title,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _pill(context, previewHabit.typeLabel),
                              _pill(context, Habit.iconLabelFor(_iconKey)),
                              if (reminderOn) _pill(context, _formatMinutes(_reminderMinutes!)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _sectionCard(
                context,
                title: 'Basics',
                subtitle: 'Name your habit and add a short note or motivation.',
                child: Column(
                  children: [
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
                    const SizedBox(height: 14),
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
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _type == Habit.typeQuit
                            ? 'Add a short reason to remember why you want to stay clean.'
                            : 'Optional note for your goal, motivation, or a simple reminder.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurface.withOpacity(0.72),
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _sectionCard(
                context,
                title: 'Type, icon & color',
                subtitle: 'Keep the visual identity clear so the habit is easy to scan.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Build habit'),
                          selected: _type == Habit.typeBuild,
                          onSelected: (_) => setState(() => _type = Habit.typeBuild),
                        ),
                        ChoiceChip(
                          label: const Text('Quit habit'),
                          selected: _type == Habit.typeQuit,
                          onSelected: (_) => setState(() => _type = Habit.typeQuit),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Icon', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: Habit.iconKeys.map((key) {
                        final selected = key == _iconKey;
                        return InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => setState(() => _iconKey = key),
                          child: Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: selected ? accent.withOpacity(0.16) : cs.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: selected ? accent : cs.outline.withOpacity(0.14),
                                width: selected ? 1.8 : 1,
                              ),
                            ),
                            child: Icon(Habit.iconDataFor(key), color: selected ? accent : cs.onSurface.withOpacity(0.74)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Text('Color', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: Habit.colorPalette.map((value) {
                        final color = Color(value);
                        final selected = value == _colorValue;
                        return InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: () => setState(() => _colorValue = value),
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selected ? cs.onSurface : Colors.transparent,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withOpacity(0.24),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: selected ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _sectionCard(
                context,
                title: 'Targets',
                subtitle: 'Use either a streak target or a weekly target.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Streak target', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _options.map((days) {
                        final selected = _targetDays == days;
                        return ChoiceChip(
                          label: Text(_labelFor(days)),
                          selected: selected,
                          onSelected: (_) => setState(() {
                            _targetDays = days;
                            if (days > 0) _weeklyTarget = 0;
                          }),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Text('Weekly target', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _weeklyOptions.map((times) {
                        final selected = _weeklyTarget == times;
                        return ChoiceChip(
                          label: Text(_weeklyLabelFor(times)),
                          selected: selected,
                          onSelected: (_) => setState(() {
                            _weeklyTarget = times;
                            if (times > 0) _targetDays = 0;
                          }),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _sectionCard(
                context,
                title: 'Reminders',
                subtitle: 'Keep it smart and lightweight. You can leave reminders off.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: _pickTime,
                          icon: const Icon(Icons.schedule_outlined),
                          label: Text(reminderOn ? _formatMinutes(_reminderMinutes!) : 'Choose time'),
                        ),
                        if (reminderOn)
                          OutlinedButton.icon(
                            onPressed: () => setState(() => _reminderMinutes = null),
                            icon: const Icon(Icons.notifications_off_outlined),
                            label: const Text('Turn off'),
                          ),
                      ],
                    ),
                    if (reminderOn) ...[
                      const SizedBox(height: 14),
                      Text('Days', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(7, (index) {
                          final weekday = index + 1;
                          final selected = _reminderWeekdays.contains(weekday);
                          return FilterChip(
                            label: Text(_weekdayLabel(weekday)),
                            selected: selected,
                            onSelected: (_) => _toggleWeekday(weekday),
                          );
                        }),
                      ),
                      const SizedBox(height: 14),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: _reminderOnlyIfIncomplete,
                        onChanged: (value) => setState(() => _reminderOnlyIfIncomplete = value),
                        title: const Text('Only if not completed yet'),
                      ),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: _reminderEveningNudge,
                        onChanged: (value) => setState(() => _reminderEveningNudge = value),
                        title: const Text('Evening nudge'),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _reminderMessageController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Custom reminder message',
                          hintText: 'Optional gentle nudge for this habit',
                          alignLabelWithHint: true,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.check_rounded),
                  label: Text(_isEdit ? 'Save changes' : 'Create habit'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outline.withOpacity(0.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withOpacity(0.72),
                ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _pill(BuildContext context, String label) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surface.withOpacity(0.84),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outline.withOpacity(0.08)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
