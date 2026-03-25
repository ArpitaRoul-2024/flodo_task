import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../providers/task_providers.dart';
import '../widgets/search_filter_bar.dart';
import '../widgets/task_card.dart';
import '../screens/task_form_screen.dart';
import '../../../core/theme/theme_notifier.dart';

class TaskListScreen extends ConsumerWidget {
  const TaskListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredAsync = ref.watch(filteredTasksProvider);
    final query = ref.watch(debouncedSearchProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        actions: [
          IconButton(
            tooltip: isDark ? 'Switch to Light' : 'Switch to Dark',
            icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
          ),
          const Gap(8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const Gap(8),
            const SearchFilterBar(),
            const Gap(16),
            Expanded(
              child: filteredAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (tasks) {
                  if (tasks.isEmpty) {
                    return _EmptyState(
                      hasFilter: query.isNotEmpty ||
                          ref.watch(statusFilterProvider) != null,
                    );
                  }
                  return ListView.separated(
                    itemCount: tasks.length,
                    separatorBuilder: (_, __) => const Gap(10),
                    padding: const EdgeInsets.only(bottom: 100),
                    itemBuilder: (_, i) => TaskCard(
                      task: tasks[i],
                      searchQuery: query,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const TaskFormScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('New Task'),
      ).animate().scale(delay: 300.ms, duration: 400.ms, curve: Curves.elasticOut),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasFilter;
  const _EmptyState({required this.hasFilter});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasFilter ? Icons.search_off : Icons.checklist_rtl_outlined,
            size: 64,
            color: cs.onSurface.withOpacity(0.2),
          ),
          const Gap(16),
          Text(
            hasFilter ? 'No tasks match your search' : 'No tasks yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: cs.onSurface.withOpacity(0.4),
                ),
          ),
          if (!hasFilter) ...[
            const Gap(8),
            Text(
              'Tap + to create your first task',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withOpacity(0.3),
                  ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}
