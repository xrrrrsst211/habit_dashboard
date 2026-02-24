class Habit {
final String id;
final String title;

/// Фактические даты выполнения, например {"2026-02-24", "2026-02-23"}
final Set<String> completedDates;

/// цель/срок в днях. 0 = без срока
final int targetDays;

const Habit({
required this.id,
required this.title,
required this.completedDates,
required this.targetDays,
});

Habit copyWith({
String? id,
String? title,
Set<String>? completedDates,
int? targetDays,
}) {
return Habit(
id: id ?? this.id,
title: title ?? this.title,
completedDates: completedDates ?? this.completedDates,
targetDays: targetDays ?? this.targetDays,
);
}

Map<String, dynamic> toJson() => {
'id': id,
'title': title,
'completedDates': completedDates.toList(),
'targetDays': targetDays,
};

static Habit fromJson(Map<String, dynamic> json) {
final rawDates = json['completedDates'];

Set<String> dates = {};
if (rawDates is List) {
dates = rawDates.whereType<String>().toSet();
}

// ✅ МИГРАЦИЯ со старой версии (streak/doneToday/lastCompletedDate)
// Если completedDates пустой, попробуем восстановить по старым полям.
if (dates.isEmpty) {
final oldStreak = (json['streak'] as int?) ?? 0;
final oldDoneToday = (json['doneToday'] as bool?) ?? false;
final oldLast = (json['lastCompletedDate'] as String?) ?? '';

DateTime? endDate;
if (oldLast.isNotEmpty) {
endDate = _tryParseYmd(oldLast);
}
endDate ??= DateTime.now();

// Если раньше было doneToday=true — считаем, что выполнено в endDate (обычно сегодня)
if (oldDoneToday || oldLast.isNotEmpty || oldStreak > 0) {
final streakToRebuild = oldStreak > 0 ? oldStreak : 1;
final capped = streakToRebuild.clamp(1, 365); // чтобы не раздувать до бесконечности

for (int i = 0; i < capped; i++) {
final d = endDate.subtract(Duration(days: i));
dates.add(_ymd(d));
}
}
}

return Habit(
id: (json['id'] as String?) ?? '',
title: (json['title'] as String?) ?? '',
completedDates: dates,
targetDays: (json['targetDays'] as int?) ?? 0,
);
}

// -------- helpers (private) --------

static String _ymd(DateTime d) {
String two(int n) => n.toString().padLeft(2, '0');
return '${d.year}-${two(d.month)}-${two(d.day)}';
}

static DateTime? _tryParseYmd(String s) {
final parts = s.split('-');
if (parts.length != 3) return null;
final y = int.tryParse(parts[0]);
final m = int.tryParse(parts[1]);
final d = int.tryParse(parts[2]);
if (y == null || m == null || d == null) return null;
return DateTime(y, m, d);
}
}