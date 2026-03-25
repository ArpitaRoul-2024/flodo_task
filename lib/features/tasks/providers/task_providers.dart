import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../repositories/task_repository.dart';

// ─── Repository ──────────────────────────────────────────────────────────────

final taskRepositoryProvider = Provider<TaskRepository>((_) => TaskRepository());

// ─── All Tasks (live stream) ──────────────────────────────────────────────────

final tasksStreamProvider = StreamProvider<List<Task>>((ref) {
  return ref.watch(taskRepositoryProvider).watchAll();
});

// ─── Search Query ─────────────────────────────────────────────────────────────

final searchQueryProvider = StateProvider<String>((_) => '');

// The debounced version used for actual filtering (300ms)
final debouncedSearchProvider = StateProvider<String>((_) => '');

class SearchDebouncer {
  Timer? _timer;

  void run(String value, void Function(String) callback) {
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 300), () => callback(value));
  }
}

final searchDebouncerProvider =
    Provider<SearchDebouncer>((_) => SearchDebouncer());

// ─── Status Filter ────────────────────────────────────────────────────────────

/// null means "All"
final statusFilterProvider = StateProvider<TaskStatus?>((_) => null);

// ─── Filtered + Searched Tasks ────────────────────────────────────────────────

final filteredTasksProvider = Provider<AsyncValue<List<Task>>>((ref) {
  final allAsync = ref.watch(tasksStreamProvider);
  final query = ref.watch(debouncedSearchProvider).trim().toLowerCase();
  final statusFilter = ref.watch(statusFilterProvider);

  return allAsync.whenData((tasks) {
    return tasks.where((t) {
      final matchesSearch =
          query.isEmpty || t.title.toLowerCase().contains(query);
      final matchesStatus =
          statusFilter == null || t.status == statusFilter;
      return matchesSearch && matchesStatus;
    }).toList();
  });
});

// ─── Draft Persistence ────────────────────────────────────────────────────────

const _draftTitleKey = 'draft_title';
const _draftDescKey = 'draft_desc';

class DraftNotifier extends AsyncNotifier<({String title, String description})> {
  @override
  Future<({String title, String description})> build() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      title: prefs.getString(_draftTitleKey) ?? '',
      description: prefs.getString(_draftDescKey) ?? '',
    );
  }

  Future<void> updateTitle(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_draftTitleKey, value);
    final current = state.valueOrNull;
    state = AsyncData((
      title: value,
      description: current?.description ?? '',
    ));
  }

  Future<void> updateDescription(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_draftDescKey, value);
    final current = state.valueOrNull;
    state = AsyncData((
      title: current?.title ?? '',
      description: value,
    ));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftTitleKey);
    await prefs.remove(_draftDescKey);
    state = const AsyncData((title: '', description: ''));
  }
}

final draftProvider =
    AsyncNotifierProvider<DraftNotifier, ({String title, String description})>(
        DraftNotifier.new);

// ─── Form Saving State ────────────────────────────────────────────────────────

/// true = currently saving (shows loader, disables button)
final isSavingProvider = StateProvider<bool>((_) => false);
