class Habit {
  final String id;
  final String title;

  /// doneToday = выполнено сегодня или нет
  final bool doneToday;

  const Habit({
    required this.id,
    required this.title,
    required this.doneToday,
  });

  Habit copyWith({
    String? id,
    String? title,
    bool? doneToday,
  }) {
    return Habit(
      id: id ?? this.id,
      title: title ?? this.title,
      doneToday: doneToday ?? this.doneToday,
    );
  }
}