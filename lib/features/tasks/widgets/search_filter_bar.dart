import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../models/task.dart';
import '../providers/task_providers.dart';

class SearchFilterBar extends ConsumerWidget {
  const SearchFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final currentFilter = ref.watch(statusFilterProvider);
    final debouncer = ref.read(searchDebouncerProvider);

    return Column(
      children: [
        // ── Search Field ───────────────────────────────────────────────
        TextField(
          onChanged: (value) {
            ref.read(searchQueryProvider.notifier).state = value;
            debouncer.run(value, (debounced) {
              ref.read(debouncedSearchProvider.notifier).state = debounced;
            });
          },
          decoration: InputDecoration(
            hintText: 'Search tasks…',
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: ref.watch(searchQueryProvider).isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      ref.read(searchQueryProvider.notifier).state = '';
                      ref.read(debouncedSearchProvider.notifier).state = '';
                    },
                  )
                : null,
          ),
        ),
        const Gap(10),

        // ── Status Filter Chips ────────────────────────────────────────
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _FilterChip(
                label: 'All',
                selected: currentFilter == null,
                onTap: () =>
                    ref.read(statusFilterProvider.notifier).state = null,
              ),
              const Gap(8),
              ...TaskStatus.values.map(
                (s) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _FilterChip(
                    label: s.label,
                    selected: currentFilter == s,
                    onTap: () =>
                        ref.read(statusFilterProvider.notifier).state = s,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        selectedColor: cs.primaryContainer,
        labelStyle: TextStyle(
          color: selected ? cs.onPrimaryContainer : cs.onSurface,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          fontSize: 13,
        ),
        side: BorderSide(
          color: selected ? Colors.transparent : cs.outline.withOpacity(0.3),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }
}
