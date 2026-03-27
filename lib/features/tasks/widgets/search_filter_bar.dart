import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/task.dart';
import '../providers/task_providers.dart';

class SearchFilterBar extends ConsumerWidget {
  const SearchFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.watch(statusFilterProvider);
    final debouncer = ref.read(searchDebouncerProvider);
    final query = ref.watch(searchQueryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         Container(
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1C1C1C)
                : const Color(0xFFF0F0F5),
            borderRadius: BorderRadius.circular(16),
            boxShadow: isDark
                ? []
                : [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: TextField(
            style: GoogleFonts.plusJakartaSans(
              color: isDark ? Colors.white : const Color(0xFF1A1D2E),
              fontSize: 14,
            ),
            onChanged: (value) {
              ref.read(searchQueryProvider.notifier).state = value;
              debouncer.run(value, (debounced) {
                ref.read(debouncedSearchProvider.notifier).state = debounced;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search task',
              hintStyle: GoogleFonts.plusJakartaSans(
                color: isDark ? Colors.white30 : Colors.black38,
                fontSize: 14,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: isDark ? Colors.white30 : Colors.black38,
                size: 20,
              ),
              suffixIcon: query.isNotEmpty
                  ? GestureDetector(
                onTap: () {
                  ref.read(searchQueryProvider.notifier).state = '';
                  ref.read(debouncedSearchProvider.notifier).state = '';
                },
                child: Container(
                  margin: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.black.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ),
              )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 4,
              ),
            ),
          ),
        ),

        const Gap(14),


        SizedBox(
          height: 34,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _Chip(
                label: 'All',
                icon: Icons.grid_view_rounded,
                selected: currentFilter == null,
                onTap: () =>
                ref.read(statusFilterProvider.notifier).state = null,
                activeColor: const Color(0xFF7C3AED),
                isDark: isDark,
              ),
              const Gap(8),
              _Chip(
                label: 'To-Do',
                icon: Icons.radio_button_unchecked_rounded,
                selected: currentFilter == TaskStatus.todo,
                onTap: () => ref
                    .read(statusFilterProvider.notifier)
                    .state = TaskStatus.todo,
                activeColor: const Color(0xFF8B8FA8),
                isDark: isDark,
              ),
              const Gap(8),
              _Chip(
                label: 'In Progress',
                icon: Icons.timelapse_rounded,
                selected: currentFilter == TaskStatus.inProgress,
                onTap: () => ref
                    .read(statusFilterProvider.notifier)
                    .state = TaskStatus.inProgress,
                activeColor: const Color(0xFFE8A838),
                isDark: isDark,
              ),
              const Gap(8),
              _Chip(
                label: 'Done',
                icon: Icons.check_circle_outline_rounded,
                selected: currentFilter == TaskStatus.done,
                onTap: () => ref
                    .read(statusFilterProvider.notifier)
                    .state = TaskStatus.done,
                activeColor: const Color(0xFF10B981),
                isDark: isDark,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final Color activeColor;
  final bool isDark;

  const _Chip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.activeColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {

    final unselectedBg = isDark
        ? const Color(0xFF1C1C1C)
        : const Color(0xFFF0F0F5);
    final unselectedBorder = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.08);
    final unselectedText = isDark ? Colors.white38 : Colors.black38;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? activeColor.withOpacity(isDark ? 0.15 : 0.1)
              : unselectedBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? activeColor.withOpacity(0.5)
                : unselectedBorder,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: selected ? activeColor : unselectedText,
            ),
            const Gap(5),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: selected ? activeColor : unselectedText,
                fontSize: 12,
                fontWeight:
                selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}