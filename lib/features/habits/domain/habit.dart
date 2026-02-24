class Habit {
  final String id;
  final String title;

  final bool doneToday;

  /// сколько дней подряд выполнено
  final int streak;

  /// дата последнего выполнения yyyy-MM-dd
  final String lastCompletedDate;

  /// цель/срок в днях. 0 = без срока
  final int targetDays;

  const Habit({
    required this.id,
    required this.title,
    required this.doneToday,
    required this.streak,
    required this.lastCompletedDate,
    required this.targetDays,
  });

  Habit copyWith({
    String? id,
    String? title,
    bool? doneToday,
    int? streak,
    String? lastCompletedDate,
    int? targetDays,
  }) {
    return Habit(
      id: id ?? this.id,
      title: title ?? this.title,
      doneToday: doneToday ?? this.doneToday,
      streak: streak ?? this.streak,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
      targetDays: targetDays ?? this.targetDays,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'doneToday': doneToday,
        'streak': streak,
        'lastCompletedDate': lastCompletedDate,
        'targetDays': targetDays,
      };

  static Habit fromJson(Map<String, dynamic> json) {
    return Habit(
      id: (json['id'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      doneToday: (json['doneToday'] as bool?) ?? false,
      streak: (json['streak'] as int?) ?? 0,
      lastCompletedDate: (json['lastCompletedDate'] as String?) ?? '',
      targetDays: (json['targetDays'] as int?) ?? 0,
    );
  }
}