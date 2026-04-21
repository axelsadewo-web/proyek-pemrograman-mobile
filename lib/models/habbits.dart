class Habit {
  int? id;
  String title;
  String date;
  int isDone; // 0 = not done, 1 = done

  Habit({this.id, required this.title, required this.date, this.isDone = 0});

  // Convert Habit to JSON for database
  Map<String, dynamic> toMap() {
    return {'id': id, 'title': title, 'date': date, 'isDone': isDone};
  }

  // Create Habit from JSON
  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      id: map['id'],
      title: map['title'],
      date: map['date'],
      isDone: map['isDone'] ?? 0,
    );
  }
}
