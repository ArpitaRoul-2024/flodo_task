import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../models/task.dart';
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
      resizeToAvoidBottomInset: false,
      backgroundColor: isDark ? const Color(0xFF1A1D2E) : const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1A1D2E) : const Color(0xFFF5F6FA),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Tasks 📋',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1A1D2E),
              ),
            ),
            Text(
              'Stay organized, stay ahead 💪',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: isDark
                    ? Colors.white.withOpacity(0.7)
                    : const Color(0xFF1A1D2E).withOpacity(0.7),
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) =>
                  RotationTransition(turns: animation, child: child),
              child: GestureDetector(
                key: ValueKey(isDark),
                onTap: () => ref.read(themeModeProvider.notifier).toggle(),
                child: Tooltip(
                  message: isDark ? 'Switch to Light' : 'Switch to Dark',
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      isDark ? "🌞" : "🌙",
                      style: TextStyle(
                        fontSize: 22,
                        color: isDark ? Colors.white : const Color(0xFF1A1D2E),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const Gap(8),

              // Stats Row
              filteredAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (tasks) => _StatsRow(tasks: tasks, isDark: isDark),
              ),

              const Gap(16),
              const SearchFilterBar(),
              const Gap(16),

              Expanded(
                child: filteredAsync.when(
                  loading: () => Center(
                    child: CircularProgressIndicator(
                      color: const Color(0xFF2D5BE3),
                    ),
                  ),
                  error: (e, _) => Center(
                    child: Text(
                      'Error: $e',
                      style: GoogleFonts.plusJakartaSans(
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ),
                  data: (tasks) {
                    if (tasks.isEmpty) {
                      return _EmptyState(
                        hasFilter: query.isNotEmpty ||
                            ref.watch(statusFilterProvider) != null,
                        isDark: isDark,
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const TaskFormScreen()),
        ),
        backgroundColor: const Color(0xFF2D5BE3),
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'New Task',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
      ).animate().scale(delay: 300.ms, duration: 400.ms, curve: Curves.elasticOut),
    );
  }
}

// Stats Row
class _StatsRow extends StatelessWidget {
  final List<Task> tasks;
  final bool isDark;
  const _StatsRow({required this.tasks, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final total = tasks.length;
    final done = tasks.where((t) => t.status == TaskStatus.done).length;
    final inProgress = tasks.where((t) => t.status == TaskStatus.inProgress).length;
    final todo = tasks.where((t) => t.status == TaskStatus.todo).length;

    return Row(
      children: [
        _StatChip(label: 'Total', count: total, color: const Color(0xFF2D5BE3), isDark: isDark),
        const Gap(8),
        _StatChip(label: 'To-Do', count: todo, color: const Color(0xFF8B8FA8), isDark: isDark),
        const Gap(8),
        _StatChip(label: 'Active', count: inProgress, color: const Color(0xFFE8A838), isDark: isDark),
        const Gap(8),
        _StatChip(label: 'Done', count: done, color: const Color(0xFF34C77B), isDark: isDark),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0);
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final bool isDark;

  const _StatChip({
    required this.label,
    required this.count,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isDark
              ? color.withOpacity(0.12)
              : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const Gap(2),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: isDark
                    ? Colors.white.withOpacity(0.5)
                    : const Color(0xFF1A1D2E).withOpacity(0.5),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Empty State
class _EmptyState extends StatelessWidget {
  final bool hasFilter;
  final bool isDark;
  const _EmptyState({required this.hasFilter, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          hasFilter
              ? Lottie.asset(
            'assets/no_data.json',
            width: 180,
            height: 180,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.search_off,
              size: 80,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          )
              : Lottie.asset(
            'assets/empty.json',
            width: 180,
            height: 180,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.task_outlined,
              size: 80,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
          const Gap(20),
          Text(
            hasFilter ? 'No tasks found' : 'No tasks yet',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? Colors.white.withOpacity(0.7)
                  : const Color(0xFF1A1D2E).withOpacity(0.7),
            ),
          ),
          const Gap(8),
          Text(
            hasFilter
                ? 'Try a different search or filter'
                : 'Tap + to create your first task',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: isDark
                  ? Colors.white.withOpacity(0.35)
                  : const Color(0xFF1A1D2E).withOpacity(0.35),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95));
  }
}