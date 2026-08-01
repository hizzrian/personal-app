import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../core/dependencies.dart';
import '../../core/result.dart';
import '../../models/job.dart';
import '../../models/job_status.dart';

class JobEditorScreen extends StatefulWidget {
  final Job? job;

  const JobEditorScreen({super.key, this.job});

  @override
  State<JobEditorScreen> createState() => _JobEditorScreenState();
}

class _JobEditorScreenState extends State<JobEditorScreen> {
  /// Static so it isn't rebuilt on every frame.
  static final _dateFormat = DateFormat('d MMMM yyyy');

  late TextEditingController _companyController;
  late TextEditingController _positionController;
  late TextEditingController _locationController;
  late TextEditingController _salaryController;
  late TextEditingController _notesController;
  late JobStatus _status;
  late DateTime _appliedDate;

  @override
  void initState() {
    super.initState();
    _companyController = TextEditingController(text: widget.job?.company ?? '');
    _positionController = TextEditingController(text: widget.job?.position ?? '');
    _locationController = TextEditingController(text: widget.job?.location ?? '');
    _salaryController = TextEditingController(text: widget.job?.salary ?? '');
    _notesController = TextEditingController(text: widget.job?.notes ?? '');
    _status = widget.job?.status ?? JobStatus.applied;
    _appliedDate = widget.job?.appliedDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _companyController.dispose();
    _positionController.dispose();
    _locationController.dispose();
    _salaryController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final company = _companyController.text.trim();
    final position = _positionController.text.trim();

    if (company.isEmpty || position.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Company and position are required')),
      );
      return;
    }

    final existing = widget.job;
    final job = Job(
      id: existing?.id ?? const Uuid().v4(),
      company: company,
      position: position,
      location: _locationController.text.trim(),
      salary: _salaryController.text.trim(),
      status: _status,
      notes: _notesController.text.trim(),
      appliedDate: _appliedDate,
      updatedAt: DateTime.now(),
    );

    final result = await context.jobs.save(job);
    if (!mounted) return;

    if (result case Err(:final failure)) {
      // Deliberately does not pop: the user's input would be lost.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(failure.message),
          duration: const Duration(seconds: 6),
        ),
      );
      return;
    }

    Navigator.pop(context, true);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _appliedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _appliedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.job != null ? 'Edit' : 'New Application'),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(
              'Save',
              style: TextStyle(color: colors.primary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _field('Position', _positionController, 'Software Engineer'),
          _field('Company', _companyController, 'Google'),
          _field('Location', _locationController, 'Remote'),
          _field('Salary', _salaryController, '15-20M/mo'),
          const SizedBox(height: 16),
          _label('Status'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final status in JobStatus.values) _statusChip(status, colors),
            ],
          ),
          const SizedBox(height: 20),
          _label('Applied'),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _dateFormat.format(_appliedDate),
                style: TextStyle(color: colors.onSurface, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _field('Notes', _notesController, 'Any additional info...', maxLines: 3),
        ],
      ),
    );
  }

  Widget _statusChip(JobStatus status, ColorScheme colors) {
    final isSelected = _status == status;
    final statusColor = Color(status.colorValue);

    return GestureDetector(
      onTap: () => setState(() => _status = status),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? statusColor.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? statusColor : colors.outlineVariant,
          ),
        ),
        child: Text(
          status.label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? statusColor : colors.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    final colors = Theme.of(context).colorScheme;
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        color: colors.outline,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(label),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            maxLines: maxLines,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(hintText: hint),
          ),
        ],
      ),
    );
  }
}
