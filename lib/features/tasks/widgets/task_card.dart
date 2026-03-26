import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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

    final isDone = task.status == TaskStatus.done;

    return GestureDetector(
      onTap: () => _showTaskDetails(context, ref),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDone
                  ? [
                isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                isDark ? Colors.grey.shade900 : Colors.grey.shade50,
              ]
                  : isBlocked
                  ? [
                isDark ? Colors.red.shade900.withOpacity(0.3) : Colors.red.shade50,
                isDark ? Colors.red.shade900.withOpacity(0.2) : Colors.red.shade50,
              ]
                  : [
                cs.primaryContainer.withOpacity(0.3),
                cs.primaryContainer.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isOverdue && !isDone
                  ? cs.error.withOpacity(0.5)
                  : isBlocked
                  ? Colors.red.withOpacity(0.3)
                  : cs.primary.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _showTaskDetails(context, ref),
              splashColor: cs.primary.withOpacity(0.1),
              highlightColor: cs.primary.withOpacity(0.05),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Status indicator dot
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDone
                                ? Colors.green
                                : isBlocked
                                ? Colors.red
                                : isOverdue
                                ? cs.error
                                : cs.primary,
                          ),
                        ),
                        const Gap(10),
                        // Title
                        Expanded(
                          child: _HighlightedText(
                            text: task.title,
                            query: searchQuery,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              decoration: isDone ? TextDecoration.lineThrough : null,
                              color: isDone
                                  ? cs.onSurface.withOpacity(0.5)
                                  : isDark
                                  ? Colors.white
                                  : const Color(0xFF1A1D2E),
                            ),
                            highlightColor: cs.primaryContainer,
                          ),
                        ),
                        const Gap(8),
                        // Compact status chip
                        _CompactStatusChip(status: task.status),
                      ],
                    ),
                    const Gap(8),
                    // Description preview
                    if (task.description.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.format_quote,
                            size: 12,
                            color: cs.onSurface.withOpacity(0.4),
                          ),
                          const Gap(4),
                          Expanded(
                            child: Text(
                              task.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: cs.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Gap(8),
                    ],
                    // Footer
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isOverdue && !isDone
                                ? cs.error.withOpacity(0.1)
                                : cs.surface.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.schedule_outlined,
                                size: 12,
                                color: isOverdue && !isDone
                                    ? cs.error
                                    : cs.onSurface.withOpacity(0.6),
                              ),
                              const Gap(4),
                              Text(
                                _formatDueDate(task.dueDate),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: isOverdue && !isDone
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: isOverdue && !isDone
                                      ? cs.error
                                      : cs.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        if (isBlocked && !isDone) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.lock_outline,
                                  size: 12,
                                  color: Colors.red,
                                ),
                                const Gap(4),
                                Text(
                                  'Blocked',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Gap(8),
                        ],
                        // Delete button - FIXED
                        _DeleteButton(taskId: task.id, isDark: isDark),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.05, end: 0);
  }

  String _formatDueDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDate = DateTime(date.year, date.month, date.day);
    final difference = dueDate.difference(today).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Tomorrow';
    if (difference == -1) return 'Yesterday';
    if (difference < -1) return '${-difference} days late';
    return DateFormat('MMM d').format(date);
  }

  void _showTaskDetails(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TaskDetailsSheet(
        task: task,
        isDark: isDark,
        ref: ref,
      ),
    );
  }
}

// Compact Status Chip
class _CompactStatusChip extends StatelessWidget {
  final TaskStatus status;
  const _CompactStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Map<TaskStatus, Map<String, dynamic>> statusConfig = {
      TaskStatus.todo: {
        'color': Colors.blue,
        'icon': Icons.circle_outlined,
        'label': 'To Do',
      },
      TaskStatus.inProgress: {
        'color': Colors.orange,
        'icon': Icons.play_circle_outline,
        'label': 'Active',
      },
      TaskStatus.done: {
        'color': Colors.green,
        'icon': Icons.check_circle_outline,
        'label': 'Done',
      },
    };

    final config = statusConfig[status]!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (config['color'] as Color).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            config['icon'] as IconData,
            size: 10,
            color: config['color'] as Color,
          ),
          const Gap(4),
          Text(
            config['label'] as String,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: config['color'] as Color,
            ),
          ),
        ],
      ),
    );
  }
}

// Task Details Bottom Sheet
class _TaskDetailsSheet extends StatelessWidget {
  final Task task;
  final bool isDark;
  final WidgetRef ref;

  const _TaskDetailsSheet({
    required this.task,
    required this.isDark,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1D2E) : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 20),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with status
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getStatusColor(task.status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getStatusIcon(task.status),
                                  size: 16,
                                  color: _getStatusColor(task.status),
                                ),
                                const Gap(6),
                                Text(
                                  task.status.label,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _getStatusColor(task.status),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          // Edit button
                          IconButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => TaskFormScreen(existingTask: task),
                                ),
                              );
                            },
                            icon: Icon(
                              Icons.edit_outlined,
                              size: 20,
                              color: cs.primary,
                            ),
                          ),
                          // Delete button - FIXED
                          IconButton(
                            onPressed: () async {
                              // Close the bottom sheet first
                              Navigator.pop(context);

                              // Small delay to ensure bottom sheet is closed
                              await Future.delayed(const Duration(milliseconds: 100));

                              // Show confirmation dialog
                              final confirmed = await showDialog<bool>(
                                context: context,
                                barrierDismissible: false,
                                builder: (dialogContext) => AlertDialog(
                                  backgroundColor: isDark ? const Color(0xFF1A1D2E) : Colors.white,
                                  title: Text(
                                    'Delete Task?',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: isDark ? Colors.white : const Color(0xFF1A1D2E),
                                    ),
                                  ),
                                  content: Text(
                                    'This action cannot be undone.',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: isDark ? Colors.white70 : const Color(0xFF1A1D2E).withOpacity(0.7),
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(dialogContext, false),
                                      child: Text(
                                        'Cancel',
                                        style: GoogleFonts.plusJakartaSans(
                                          color: const Color(0xFF2D5BE3),
                                        ),
                                      ),
                                    ),
                                    FilledButton(
                                      onPressed: () => Navigator.pop(dialogContext, true),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: Colors.red,
                                      ),
                                      child: Text(
                                        'Delete',
                                        style: GoogleFonts.plusJakartaSans(),
                                      ),
                                    ),
                                  ],
                                ),
                              );

                              if (confirmed == true) {
                                try {
                                  await ref.read(taskRepositoryProvider).delete(task.id);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text('Task deleted successfully'),
                                        backgroundColor: Colors.green,
                                        behavior: SnackBarBehavior.floating,
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error deleting task: $e'),
                                        backgroundColor: Colors.red,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                            icon: Icon(
                              Icons.delete_outline,
                              size: 20,
                              color: cs.error,
                            ),
                          ),
                        ],
                      ),
                      const Gap(16),
                      // Title
                      Text(
                        task.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF1A1D2E),
                        ),
                      ),
                      const Gap(12),
                      // Due date
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 16,
                              color: cs.primary,
                            ),
                            const Gap(8),
                            Text(
                              'Due: ${DateFormat('EEEE, MMMM d, yyyy').format(task.dueDate)}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white : const Color(0xFF1A1D2E),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Gap(20),
                      // Description
                      if (task.description.isNotEmpty) ...[
                        Text(
                          'Description',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF1A1D2E),
                          ),
                        ),
                        const Gap(8),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            task.description,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              height: 1.5,
                              color: isDark
                                  ? Colors.white.withOpacity(0.8)
                                  : const Color(0xFF1A1D2E).withOpacity(0.8),
                            ),
                          ),
                        ),
                        const Gap(20),
                      ],
                      // Additional info
                      Text(
                        'Additional Info',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF1A1D2E),
                        ),
                      ),
                      const Gap(12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            _buildInfoRow(
                              'Created',
                              DateFormat('MMM d, yyyy • h:mm a').format(task.dueDate),
                              Icons.access_time_outlined,
                              isDark,
                            ),
                            const Divider(),
                            _buildInfoRow(
                              'Last Updated',
                              DateFormat('MMM d, yyyy • h:mm a').format(task.dueDate),
                              Icons.update_outlined,
                              isDark,
                            ),
                            if (task.blockedById != null) ...[
                              const Divider(),
                              _buildInfoRow(
                                'Blocked By',
                                'Another task',
                                Icons.lock_outline,
                                isDark,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const Gap(20),
                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                'Close',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const Gap(12),
                          Expanded(
                            child: FilledButton(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => TaskFormScreen(existingTask: task),
                                  ),
                                );
                              },
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                backgroundColor: const Color(0xFF2D5BE3),
                              ),
                              child: Text(
                                'Edit Task',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Gap(30),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
          const Gap(12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : const Color(0xFF1A1D2E),
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return Colors.blue;
      case TaskStatus.inProgress:
        return Colors.orange;
      case TaskStatus.done:
        return Colors.green;
    }
  }

  IconData _getStatusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return Icons.circle_outlined;
      case TaskStatus.inProgress:
        return Icons.play_circle_outline;
      case TaskStatus.done:
        return Icons.check_circle_outline;
    }
  }
}

// Highlighted text for search results
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

// Delete Button - FIXED VERSION
class _DeleteButton extends ConsumerWidget {
  final String taskId;
  final bool isDark;

  const _DeleteButton({required this.taskId, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () async {
        // Show confirmation dialog directly without closing anything
        final confirmed = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1A1D2E) : Colors.white,
            title: Text(
              'Delete Task?',
              style: GoogleFonts.plusJakartaSans(
                color: isDark ? Colors.white : const Color(0xFF1A1D2E),
              ),
            ),
            content: Text(
              'This action cannot be undone.',
              style: GoogleFonts.plusJakartaSans(
                color: isDark ? Colors.white70 : const Color(0xFF1A1D2E).withOpacity(0.7),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF2D5BE3),
                  ),
                ),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: Text(
                  'Delete',
                  style: GoogleFonts.plusJakartaSans(),
                ),
              ),
            ],
          ),
        );

        if (confirmed == true) {
          try {
            await ref.read(taskRepositoryProvider).delete(taskId);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Task deleted successfully'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error deleting task: $e'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.delete_outline,
          size: 16,
          color: Theme.of(context).colorScheme.error.withOpacity(0.7),
        ),
      ),
    );
  }
}