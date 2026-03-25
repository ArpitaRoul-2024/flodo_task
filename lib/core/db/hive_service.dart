import 'package:hive_flutter/hive_flutter.dart';
import '../../features/tasks/models/task.dart';

class HiveService {
  static const String tasksBoxName = 'tasks';

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(TaskStatusAdapter());
    Hive.registerAdapter(TaskAdapter());
    await Hive.openBox<Task>(tasksBoxName);
  }

  static Box<Task> get tasksBox => Hive.box<Task>(tasksBoxName);
}