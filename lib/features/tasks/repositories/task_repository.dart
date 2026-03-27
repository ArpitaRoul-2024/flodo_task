import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../core/db/hive_service.dart';
import '../../../core/notification/notification_service.dart';
import '../models/task.dart';

class TaskRepository {
  Box<Task> get _box => HiveService.tasksBox;

  List<Task> _getSorted() {
    final tasks = _box.values.toList();
    tasks.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return tasks;
  }

  Stream<List<Task>> watchAll() {
    final controller = StreamController<List<Task>>.broadcast();
    controller.add(_getSorted());
    final sub = _box.watch().listen((_) => controller.add(_getSorted()));
    controller.onCancel = sub.cancel;
    return controller.stream;
  }

  List<Task> getAll() => _getSorted();

  Task? getById(String id) {
    try {
      return _box.values.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> create(Task task) async {
    await Future.delayed(const Duration(seconds: 2));
    task.id = const Uuid().v4();
    task.sortOrder = _box.length;
    await _box.put(task.id, task);
    await NotificationService.scheduleTaskReminder(task);
  }

  Future<void> update(Task task) async {
    await Future.delayed(const Duration(seconds: 2));
    await _box.put(task.id, task);
    await NotificationService.scheduleTaskReminder(task);
  }

  Future<void> delete(String id) async {
    final task = getById(id);
    if (task != null) {
      await NotificationService.cancelTaskReminder(task);
    }
    await _box.delete(id);
  }

  Future<void> updateStatus(String id, TaskStatus status) async {
    final task = getById(id);
    if (task == null) return;
    task.status = status;
    await _box.put(id, task);
    if (status == TaskStatus.done) {
      await NotificationService.cancelTaskReminder(task);
    } else {
      await NotificationService.scheduleTaskReminder(task);
    }
  }
}