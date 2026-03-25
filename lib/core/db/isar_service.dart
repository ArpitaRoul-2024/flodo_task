import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../features/tasks/models/task.dart';

class IsarService {
  static late Isar _isar;

  static Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [TaskSchema],
      directory: dir.path,
    );
  }

  static Isar get db => _isar;
}
