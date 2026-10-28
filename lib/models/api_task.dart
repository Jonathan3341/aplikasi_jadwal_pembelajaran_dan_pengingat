
class ApiTask {
  final int userId;
  final int id;
  final String title;
  final bool completed;

  const ApiTask({
    required this.userId,
    required this.id,
    required this.title,
    required this.completed,
  });

  factory ApiTask.fromJson(Map<String, dynamic> json) {
    return ApiTask(
      userId: json['userId'] as int,
      id: json['id'] as int,
      title: json['title'] as String,
      completed: json['completed'] as bool,
    );
  }
}
