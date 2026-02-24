class Habit {
  final String id;
  final String title;
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'doneToday': doneToday,
      };

  static Habit fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'] as String,
      title: json['title'] as String,
      doneToday: (json['doneToday'] as bool?) ?? false,
    );
  }
}