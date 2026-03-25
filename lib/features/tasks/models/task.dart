import 'package:isar/isar.dart';

part 'task.g.dart';

/// Enum for task status
enum TaskStatus { todo, inProgress, done }

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

@collection
class Task {
  Id id = Isar.autoIncrement;

  late String title;
  late String description;
  late DateTime dueDate;

  @Enumerated(EnumType.name)
  late TaskStatus status;

  /// ID of the task that must be completed before this one (optional)
  int? blockedById;

  /// Display order for drag-and-drop (future-proof)
  late int sortOrder;

  Task();
}
