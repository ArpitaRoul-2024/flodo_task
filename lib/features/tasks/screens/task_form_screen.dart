import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/task.dart';
import '../providers/task_providers.dart';
import '../../../core/theme/theme_notifier.dart';

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
  String? _blockedById;
  bool _initialized = false;

  // Step management
  int _currentStep = 0;
  final List<String> _stepTitles = [
    'What needs to be done?',
    'Add some details',
    'When is it due?',
    'Set the status',
    'Blocked by?',
  ];

   bool _titleValid = false;
  bool _descValid = true;
  bool _dateSelected = false;
  bool _statusSelected = false;

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

     if (_isEditing) {
      _titleValid = _titleCtrl.text.trim().isNotEmpty;
      _dateSelected = true;
      _statusSelected = true;
      _descValid = true;
    }

     if (!_isEditing) {
      Future.microtask(_loadDraft);
    }

     _titleCtrl.addListener(_updateValidation);
    _descCtrl.addListener(_saveDraft);
  }

  void _updateValidation() {
    setState(() {
      _titleValid = _titleCtrl.text.trim().isNotEmpty;
    });
    _saveDraft();
  }

  void _saveDraft() {
    if (_isEditing) return;
    ref.read(draftProvider.notifier).updateTitle(_titleCtrl.text);
    ref.read(draftProvider.notifier).updateDescription(_descCtrl.text);
  }

  Future<void> _loadDraft() async {
    final draft = await ref.read(draftProvider.future);
    if (!mounted) return;
    if (draft.title.isNotEmpty && _titleCtrl.text.isEmpty) {
      _titleCtrl.text = draft.title;
      _titleValid = draft.title.trim().isNotEmpty;
    }
    if (draft.description.isNotEmpty && _descCtrl.text.isEmpty) {
      _descCtrl.text = draft.description;
    }
    setState(() => _initialized = true);
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
    if (picked != null) {
      setState(() {
        _dueDate = picked;
        _dateSelected = true;
      });
    }
  }

  void _nextStep() {
    setState(() {
      _currentStep++;
    });
  }

  void _previousStep() {
    setState(() {
      _currentStep--;
    });
  }

  bool _canProceedToNextStep() {
    switch (_currentStep) {
      case 0:
        return _titleValid;
      case 1:
        return true;
      case 2:
        return _dateSelected;
      case 3:
        return _statusSelected;
      case 4:
        return true;
      default:
        return false;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final isSaving = ref.read(isSavingProvider);
    if (isSaving) return;

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

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Task updated!' : 'Task added to your list!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) ref.read(isSavingProvider.notifier).state = false;
    }
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildTitleStep();
      case 1:
        return _buildDescriptionStep();
      case 2:
        return _buildDueDateStep();
      case 3:
        return _buildStatusStep();
      case 4:
        return _buildBlockedByStep();
      default:
        return Container();
    }
  }

  Widget _buildTitleStep() {
    final theme = Theme.of(context);
    final isDark = _isDarkMode();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Step 1 of 5',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Gap(24),
        Text(
          'What needs to be done?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1A1D2E),
          ),
        ),
        const Gap(8),
        Text(
          'Give your task a clear, actionable title',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: isDark
                ? Colors.white.withOpacity(0.6)
                : const Color(0xFF1A1D2E).withOpacity(0.6),
          ),
        ),
        const Gap(32),
        TextFormField(
          controller: _titleCtrl,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          style: GoogleFonts.plusJakartaSans(
            color: isDark ? Colors.white : const Color(0xFF1A1D2E),
          ),
          decoration: InputDecoration(
            hintText: 'e.g., Finish project report',
            hintStyle: GoogleFonts.plusJakartaSans(
              color: isDark
                  ? Colors.white.withOpacity(0.4)
                  : const Color(0xFF1A1D2E).withOpacity(0.4),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: isDark
                ? const Color(0xFF1A1D2E).withOpacity(0.6)
                : Colors.white,
            contentPadding: const EdgeInsets.all(16),
          ),
          validator: (v) =>
          (v == null || v.trim().isEmpty) ? 'Title is required' : null,
          onFieldSubmitted: (_) {
            if (_titleValid) _nextStep();
          },
        ),
      ],
    );
  }

  Widget _buildDescriptionStep() {
    final theme = Theme.of(context);
    final isDark = _isDarkMode();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Step 2 of 5',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Gap(24),
        Text(
          'Add some details',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1A1D2E),
          ),
        ),
        const Gap(8),
        Text(
          'Optional: Add more context or notes',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: isDark
                ? Colors.white.withOpacity(0.6)
                : const Color(0xFF1A1D2E).withOpacity(0.6),
          ),
        ),
        const Gap(32),
        TextFormField(
          controller: _descCtrl,
          autofocus: true,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          style: GoogleFonts.plusJakartaSans(
            color: isDark ? Colors.white : const Color(0xFF1A1D2E),
          ),
          decoration: InputDecoration(
            hintText: 'Add more details… (optional)',
            hintStyle: GoogleFonts.plusJakartaSans(
              color: isDark
                  ? Colors.white.withOpacity(0.4)
                  : const Color(0xFF1A1D2E).withOpacity(0.4),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: isDark
                ? const Color(0xFF1A1D2E).withOpacity(0.6)
                : Colors.white,
            contentPadding: const EdgeInsets.all(16),
          ),
          onFieldSubmitted: (_) => _nextStep(),
        ),
      ],
    );
  }

  Widget _buildDueDateStep() {
    final theme = Theme.of(context);
    final isDark = _isDarkMode();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Step 3 of 5',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Gap(24),
        Text(
          'When is it due?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1A1D2E),
          ),
        ),
        const Gap(8),
        Text(
          'Set a deadline to stay on track',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: isDark
                ? Colors.white.withOpacity(0.6)
                : const Color(0xFF1A1D2E).withOpacity(0.6),
          ),
        ),
        const Gap(32),
        InkWell(
          onTap: _pickDate,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _dateSelected
                    ? theme.colorScheme.primary
                    : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                width: _dateSelected ? 2 : 1,
              ),
              color: isDark
                  ? const Color(0xFF1A1D2E).withOpacity(0.6)
                  : Colors.white,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 24,
                  color: _dateSelected
                      ? theme.colorScheme.primary
                      : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                ),
                const Gap(12),
                Expanded(
                  child: Text(
                    DateFormat('EEEE, MMMM d, yyyy').format(_dueDate),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: _dateSelected ? FontWeight.w500 : FontWeight.normal,
                      color: isDark ? Colors.white : const Color(0xFF1A1D2E),
                    ),
                  ),
                ),
                if (_dateSelected)
                  Icon(
                    Icons.check_circle,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusStep() {
    final theme = Theme.of(context);
    final isDark = _isDarkMode();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Step 4 of 5',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Gap(24),
        Text(
          'Set the status',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1A1D2E),
          ),
        ),
        const Gap(8),
        Text(
          'Where is this task in your workflow?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: isDark
                ? Colors.white.withOpacity(0.6)
                : const Color(0xFF1A1D2E).withOpacity(0.6),
          ),
        ),
        const Gap(32),
        ...TaskStatus.values.map((status) {
          final isSelected = _status == status;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () {
                setState(() {
                  _status = status;
                  _statusSelected = true;
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                    width: isSelected ? 2 : 1,
                  ),
                  color: isSelected
                      ? theme.colorScheme.primaryContainer.withOpacity(0.3)
                      : (isDark
                      ? const Color(0xFF1A1D2E).withOpacity(0.6)
                      : Colors.white),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getStatusIcon(status),
                      color: isSelected
                          ? theme.colorScheme.primary
                          : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                      size: 24,
                    ),
                    const Gap(12),
                    Expanded(
                      child: Text(
                        status.label,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isDark ? Colors.white : const Color(0xFF1A1D2E),
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  IconData _getStatusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return Icons.radio_button_unchecked;
      case TaskStatus.inProgress:
        return Icons.play_circle_outline;
      case TaskStatus.done:
        return Icons.check_circle_outline;
    }
  }

  Widget _buildBlockedByStep() {
    final theme = Theme.of(context);
    final isDark = _isDarkMode();
    final allAsync = ref.watch(tasksStreamProvider);
    final otherTasks = allAsync.whenOrNull(data: (tasks) => tasks
        .where((t) => t.id != widget.existingTask?.id)
        .toList()) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Step 5 of 5',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Gap(24),
        Text(
          'Blocked by?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1A1D2E),
          ),
        ),
        const Gap(8),
        Text(
          'Optional: Select a task that needs to be completed first',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: isDark
                ? Colors.white.withOpacity(0.6)
                : const Color(0xFF1A1D2E).withOpacity(0.6),
          ),
        ),
        const Gap(32),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
            color: isDark
                ? const Color(0xFF1A1D2E).withOpacity(0.6)
                : Colors.white,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: _blockedById,
              isExpanded: true,
              hint: Text(
                'None (optional)',
                style: GoogleFonts.plusJakartaSans(
                  color: isDark
                      ? Colors.white.withOpacity(0.6)
                      : const Color(0xFF1A1D2E).withOpacity(0.6),
                ),
              ),
              dropdownColor: isDark ? const Color(0xFF1A1D2E) : Colors.white,
              style: GoogleFonts.plusJakartaSans(
                color: isDark ? Colors.white : const Color(0xFF1A1D2E),
              ),
              icon: Icon(
                Icons.arrow_drop_down,
                color: isDark ? Colors.white : const Color(0xFF1A1D2E),
              ),
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
          ),
        ),
        const Gap(32),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primaryContainer,
                theme.colorScheme.primaryContainer.withOpacity(0.5),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Text(
                  "🎉",
                  style: TextStyle(
                    fontSize: 50,
                  )
              ),
              const Gap(12),
              Text(
                'Almost there!',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1A1D2E),
                ),
              ),
              const Gap(4),
              Text(
                'Review your task details and create it',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: isDark
                      ? Colors.white.withOpacity(0.7)
                      : const Color(0xFF1A1D2E).withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewStep() {
    final theme = Theme.of(context);
    final isDark = _isDarkMode();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Gap(24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const Gap(16),
              Text(
                'Ready to create!',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const Gap(8),
              Text(
                'Your task "${_titleCtrl.text}" has been set up',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  color: isDark ? Colors.white : const Color(0xFF1A1D2E),
                ),
              ),
              const Gap(24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1A1D2E).withOpacity(0.6)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Task Summary',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1A1D2E),
                      ),
                    ),
                    const Gap(12),
                    _buildSummaryRow('Title', _titleCtrl.text),
                    if (_descCtrl.text.isNotEmpty)
                      _buildSummaryRow('Description', _descCtrl.text),
                    _buildSummaryRow('Due Date', DateFormat('MMMM d, yyyy').format(_dueDate)),
                    _buildSummaryRow('Status', _status.label),

                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    final isDark = _isDarkMode();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w500,
                color: isDark
                    ? Colors.white.withOpacity(0.6)
                    : const Color(0xFF1A1D2E).withOpacity(0.6),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : const Color(0xFF1A1D2E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isDarkMode() {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);
    return isDark;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSaving = ref.watch(isSavingProvider);
    final isDark = _isDarkMode();

     final screenSize = MediaQuery.of(context).size;
     void _nextStep() {
      // Special validation for title step
      if (_currentStep == 0 && _titleCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a task title'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      // Check other steps
      if (!_canProceedToNextStep()) {
        String errorMessage;
        switch (_currentStep) {
          case 2:
            errorMessage = 'Please select a due date';
            break;
          case 3:
            errorMessage = 'Please select a status';
            break;
          default:
            errorMessage = 'Please complete this step';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }

      setState(() {
        _currentStep++;
      });
    }
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1D2E) : const Color(0xFFF5F6FA),
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.close,
            color: isDark ? Colors.white : const Color(0xFF1A1D2E),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEditing ? 'Edit Task' : 'New Task',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF1A1D2E),
          ),
        ),
        actions: [
          if (_currentStep == 4 && !_isEditing)
            TextButton(
              onPressed: _save,
              child: Text(
                'Skip',
                style: GoogleFonts.plusJakartaSans(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
        ],
      ),

      body: Stack(
        children: [
           Positioned(
            top: 40,
            right: 10,
            child: IgnorePointer(
              ignoring: true,
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  isDark ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.1),
                  BlendMode.srcATop,
                ),
                child: Image.asset(
                  'assets/pen.png',
                  width: 80,
                  opacity: const AlwaysStoppedAnimation(0.45),
                ),
              ),
            ),
          ),

          Positioned(
            top: screenSize.height * 0.35,
            left: 5,
            child: IgnorePointer(
              ignoring: true,
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  isDark ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.1),
                  BlendMode.srcATop,
                ),
                child: Image.asset(
                  'assets/note.png',
                  width: 95,
                  opacity: const AlwaysStoppedAnimation(0.45),
                ),
              ),
            ),
          ),

          Positioned(
            bottom: screenSize.height * 0.2,
            right: 15,
            child: IgnorePointer(
              ignoring: true,
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  isDark ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.1),
                  BlendMode.srcATop,
                ),
                child: Image.asset(
                  'assets/notepad.png',
                  width: 85,
                  opacity: const AlwaysStoppedAnimation(0.45),
                ),
              ),
            ),
          ),

          Positioned(
            bottom: screenSize.height * 0.45,
            right: 25,
            child: IgnorePointer(
              ignoring: true,
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  isDark ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.1),
                  BlendMode.srcATop,
                ),
                child: Image.asset(
                  'assets/team-work.png',
                  width: 90,
                  opacity: const AlwaysStoppedAnimation(0.45),
                ),
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(
                        left: 24,
                        right: 24,
                        top: 24,
                        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!_isEditing)
                            Column(
                              children: [
                                LinearProgressIndicator(
                                  value: (_currentStep + 1) / 5,
                                  backgroundColor: theme.colorScheme.primaryContainer,
                                  valueColor: AlwaysStoppedAnimation(
                                    theme.colorScheme.primary,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                const Gap(24),
                              ],
                            ),
                          _buildStepContent(),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Buttons
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1A1D2E) : const Color(0xFFF5F6FA),
                      border: Border(
                        top: BorderSide(
                          color: isDark
                              ? Colors.white.withOpacity(0.1)
                              : Colors.black.withOpacity(0.05),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        if (_currentStep > 0)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _previousStep,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                side: BorderSide(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              child: Text(
                                'Back',
                                style: GoogleFonts.plusJakartaSans(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                        if (_currentStep > 0) const Gap(12),
                        Expanded(
                          child: FilledButton(
                            onPressed: isSaving
                                ? null
                                : (_currentStep < 4 ? _nextStep : _save),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              backgroundColor: const Color(0xFF2D5BE3),
                            ),
                            child: isSaving
                                ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                                : Text(
                              _currentStep < 4
                                  ? 'Continue'
                                  : (_isEditing
                                  ? 'Save Changes'
                                  : 'Create Task'),
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}