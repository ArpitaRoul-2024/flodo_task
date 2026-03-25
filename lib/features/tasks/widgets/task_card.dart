import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../providers/task_providers.dart';
import '../screens/task_form_screen.dart';

class TaskCard extends ConsumerWidget {
  final Task task;
  final String searchQuery;

  const TaskCard({super.key, required this.task, this.searchQuery = ''});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Check if this task is blocked
    final allAsync = ref.watch(tasksStreamProvider);
    final isBlocked = allAsync.whenOrNull(data: (tasks) {
      if (task.blockedById == null) return false;
      final blocker = tasks.firstWhere(
        (t) => t.id == task.blockedById,
        orElse: () => task,
      );
      return blocker.id != task.id && blocker.status != TaskStatus.done;
    }) ?? false;

    final isOverdue = task.status != TaskStatus.done &&
        task.dueDate.isBefore(DateTime.now());

    return Opacity(
      opacity: isBlocked ? 0.45 : 1.0,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TaskFormScreen(existingTask: task),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _HighlightedText(
                        text: task.title,
                        query: searchQuery,
                        style: theme.textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.w600,
                          decoration: task.status == TaskStatus.done
                              ? TextDecoration.lineThrough
                              : null,
                          color: task.status == TaskStatus.done
                              ? cs.onSurface.withOpacity(0.5)
                              : null,
                        ),
                        highlightColor: cs.primaryContainer,
                      ),
                    ),
                    const Gap(8),
                    _StatusChip(status: task.status),
                  ],
                ),
                if (task.description.isNotEmpty) ...[
                  const Gap(6),
                  Text(
                    task.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
                const Gap(12),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: isOverdue ? cs.error : cs.onSurface.withOpacity(0.5),
                    ),
                    const Gap(4),
                    Text(
                      DateFormat('MMM d, yyyy').format(task.dueDate),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isOverdue
                            ? cs.error
                            : cs.onSurface.withOpacity(0.5),
                        fontWeight:
                            isOverdue ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    if (isBlocked) ...[
                      const Gap(10),
                      Icon(Icons.lock_outline, size: 14, color: cs.error),
                      const Gap(4),
                      Text(
                        'Blocked',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const Spacer(),
                    _DeleteButton(taskId: task.id),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.05, end: 0);
  }
}

// ─── Highlighted text for search results ──────────────────────────────────────

class _HighlightedText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle style;
  final Color highlightColor;

  const _HighlightedText({
    required this.text,
    required this.query,
    required this.style,
    required this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) return Text(text, style: style);

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final index = lowerText.indexOf(lowerQuery);

    if (index < 0) return Text(text, style: style);

    return Text.rich(
      TextSpan(
        children: [
          if (index > 0) TextSpan(text: text.substring(0, index), style: style),
          TextSpan(
            text: text.substring(index, index + query.length),
            style: style.copyWith(
              backgroundColor: highlightColor,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          if (index + query.length < text.length)
            TextSpan(
              text: text.substring(index + query.length),
              style: style,
            ),
        ],
      ),
    );
  }
}

// ─── Status Chip ──────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final TaskStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Color bg;
    Color fg;
    IconData icon;

    switch (status) {
      case TaskStatus.todo:
        bg = cs.secondaryContainer;
        fg = cs.onSecondaryContainer;
        icon = Icons.radio_button_unchecked;
      case TaskStatus.inProgress:
        bg = cs.tertiaryContainer;
        fg = cs.onTertiaryContainer;
        icon = Icons.timelapse_outlined;
      case TaskStatus.done:
        bg = cs.primaryContainer;
        fg = cs.onPrimaryContainer;
        icon = Icons.check_circle_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const Gap(4),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Delete Button ────────────────────────────────────────────────────────────

class _DeleteButton extends ConsumerWidget {
  final String taskId; // ← int se String
  const _DeleteButton({required this.taskId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      iconSize: 18,
      visualDensity: VisualDensity.compact,
      icon: Icon(Icons.delete_outline,
          color: Theme.of(context).colorScheme.error.withOpacity(0.7)),
      onPressed: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Delete Task?'),
            content: const Text('This action cannot be undone.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel')),
              FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Delete')),
            ],
          ),
        );
        if (confirmed == true) {
          await ref.read(taskRepositoryProvider).delete(taskId);
        }
      },
    );
  }
}