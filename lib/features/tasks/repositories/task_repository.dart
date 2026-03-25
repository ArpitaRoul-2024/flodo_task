import 'package:isar/isar.dart';
import '../../../core/db/isar_service.dart';
import '../models/task.dart';

class TaskRepository {
  Isar get _db => IsarService.db;

  /// Watch all tasks as a live stream
  Stream<List<Task>> watchAll() {
    return _db.tasks.where().sortBySortOrder().watch(fireImmediately: true);
  }

  Future<List<Task>> getAll() => _db.tasks.where().sortBySortOrder().findAll();

  Future<Task?> getById(Id id) => _db.tasks.get(id);

  /// Create with simulated 2-second network delay
  Future<void> create(Task task) async {
    await Future.delayed(const Duration(seconds: 2));
    await _db.writeTxn(() async {
      // Assign sort order as max+1
      final count = await _db.tasks.count();
      task.sortOrder = count;
      await _db.tasks.put(task);
    });
  }

  /// Update with simulated 2-second network delay
  Future<void> update(Task task) async {
    await Future.delayed(const Duration(seconds: 2));
    await _db.writeTxn(() => _db.tasks.put(task));
  }

  Future<void> delete(Id id) async {
    await _db.writeTxn(() => _db.tasks.delete(id));
  }

  /// Update status only (no delay — used for quick status toggles)
  Future<void> updateStatus(Id id, TaskStatus status) async {
    final task = await _db.tasks.get(id);
    if (task == null) return;
    task.status = status;
    await _db.writeTxn(() => _db.tasks.put(task));
  }
}
