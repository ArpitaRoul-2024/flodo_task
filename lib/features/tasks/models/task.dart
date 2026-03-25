import 'package:hive/hive.dart';

part 'task.g.dart';

@HiveType(typeId: 0)
enum TaskStatus {
  @HiveField(0)
  todo,

  @HiveField(1)
  inProgress,

  @HiveField(2)
  done,
}

extension TaskStatusLabel on TaskStatus {
  String get label {
    switch (this) {
      case TaskStatus.todo:
        return 'To-Do';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.done:
        return 'Done';
    }
  }

  static TaskStatus fromLabel(String label) {
    return TaskStatus.values.firstWhere((s) => s.label == label);
  }
}

@HiveType(typeId: 1)
class Task extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String title;

  @HiveField(2)
  late String description;

  @HiveField(3)
  late DateTime dueDate;

  @HiveField(4)
  late TaskStatus status;

  @HiveField(5)
  String? blockedById;

  @HiveField(6)
  late int sortOrder;

  Task();
}