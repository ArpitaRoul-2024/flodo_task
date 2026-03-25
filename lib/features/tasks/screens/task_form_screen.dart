import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../providers/task_providers.dart';

class TaskFormScreen extends ConsumerStatefulWidget {
  final Task? existingTask;
  const TaskFormScreen({super.key, this.existingTask});

  @override
  ConsumerState<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends ConsumerState<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late DateTime _dueDate;
  late TaskStatus _status;
  int? _blockedById;
  bool _initialized = false;

  bool get _isEditing => widget.existingTask != null;

  @override
  void initState() {
    super.initState();
    final task = widget.existingTask;
    _titleCtrl = TextEditingController(text: task?.title ?? '');
    _descCtrl = TextEditingController(text: task?.description ?? '');
    _dueDate = task?.dueDate ?? DateTime.now().add(const Duration(days: 1));
    _status = task?.status ?? TaskStatus.todo;
    _blockedById = task?.blockedById;

    // Load draft only for new task creation
    if (!_isEditing) {
      Future.microtask(_loadDraft);
    }

    // Listen for changes to persist draft
    _titleCtrl.addListener(_saveDraft);
    _descCtrl.addListener(_saveDraft);
  }

  Future<void> _loadDraft() async {
    final draft = await ref.read(draftProvider.future);
    if (!mounted) return;
    if (draft.title.isNotEmpty && _titleCtrl.text.isEmpty) {
      _titleCtrl.text = draft.title;
    }
    if (draft.description.isNotEmpty && _descCtrl.text.isEmpty) {
      _descCtrl.text = draft.description;
    }
    setState(() => _initialized = true);
  }

  void _saveDraft() {
    if (_isEditing) return;
    ref.read(draftProvider.notifier).updateTitle(_titleCtrl.text);
    ref.read(draftProvider.notifier).updateDescription(_descCtrl.text);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final isSaving = ref.read(isSavingProvider);
    if (isSaving) return; // prevent double tap

    ref.read(isSavingProvider.notifier).state = true;

    try {
      final repo = ref.read(taskRepositoryProvider);

      if (_isEditing) {
        final task = widget.existingTask!;
        task.title = _titleCtrl.text.trim();
        task.description = _descCtrl.text.trim();
        task.dueDate = _dueDate;
        task.status = _status;
        task.blockedById = _blockedById;
        await repo.update(task);
      } else {
        final task = Task()
          ..title = _titleCtrl.text.trim()
          ..description = _descCtrl.text.trim()
          ..dueDate = _dueDate
          ..status = _status
          ..blockedById = _blockedById
          ..sortOrder = 0;
        await repo.create(task);
        await ref.read(draftProvider.notifier).clear();
      }

      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) ref.read(isSavingProvider.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isSaving = ref.watch(isSavingProvider);

    final allAsync = ref.watch(tasksStreamProvider);
    final otherTasks = allAsync.whenOrNull(data: (tasks) => tasks
        .where((t) => t.id != widget.existingTask?.id)
        .toList()) ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Task' : 'New Task'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Title ──────────────────────────────────────────────────
            _Label('Title'),
            const Gap(6),
            TextFormField(
              controller: _titleCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(hintText: 'What needs to be done?'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Title is required' : null,
            ),
            const Gap(20),

            // ── Description ────────────────────────────────────────────
            _Label('Description'),
            const Gap(6),
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration:
                  const InputDecoration(hintText: 'Add more details… (optional)'),
            ),
            const Gap(20),

            // ── Due Date ───────────────────────────────────────────────
            _Label('Due Date'),
            const Gap(6),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(14),
              child: InputDecorator(
                decoration: const InputDecoration(),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 16, color: cs.primary),
                    const Gap(10),
                    Text(DateFormat('MMMM d, yyyy').format(_dueDate)),
                  ],
                ),
              ),
            ),
            const Gap(20),

            // ── Status ─────────────────────────────────────────────────
            _Label('Status'),
            const Gap(6),
            DropdownButtonFormField<TaskStatus>(
              value: _status,
              decoration: const InputDecoration(),
              items: TaskStatus.values
                  .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(s.label),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _status = v!),
            ),
            const Gap(20),

            // ── Blocked By ─────────────────────────────────────────────
            _Label('Blocked By (optional)'),
            const Gap(6),
            DropdownButtonFormField<int?>(
              value: _blockedById,
              decoration: const InputDecoration(hintText: 'None'),
              items: [
                const DropdownMenuItem(value: null, child: Text('None')),
                ...otherTasks.map(
                  (t) => DropdownMenuItem(
                    value: t.id,
                    child: Text(
                      t.title,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _blockedById = v),
            ),
            const Gap(36),

            // ── Save Button ────────────────────────────────────────────
            FilledButton(
              onPressed: isSaving ? null : _save,
              child: isSaving
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: cs.onPrimary,
                      ),
                    )
                  : Text(_isEditing ? 'Save Changes' : 'Create Task'),
            ),

            if (isSaving) ...[
              const Gap(12),
              Text(
                _isEditing ? 'Updating task…' : 'Creating task…',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
    );
  }
}
