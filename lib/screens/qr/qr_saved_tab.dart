import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../core/dependencies.dart';
import '../../core/failure.dart';
import '../../core/result.dart';
import '../../models/qr_item.dart';
import '../../utils/app_theme.dart';
import '../../widgets/error_view.dart';
import '../../widgets/group_card.dart';
import 'qr_fullscreen_view.dart';
import '../../utils/app_spacing.dart';

class QrSavedTab extends StatefulWidget {
  const QrSavedTab({super.key});

  @override
  State<QrSavedTab> createState() => _QrSavedTabState();
}

class _QrSavedTabState extends State<QrSavedTab> {
  List<QrItem> _items = const [];
  bool _isLoading = true;
  Failure? _failure;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await context.qrCodes.all();
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      switch (result) {
        case Ok(:final value):
          _failure = null;
          _items = value;
        case Err(:final failure):
          _failure = failure;
      }
    });
  }

  Future<void> _add() async {
    final draft = await _promptForItem();
    if (draft == null || !mounted) return;

    final result = await context.qrCodes.save(
      QrItem(
        id: const Uuid().v4(),
        label: draft.label,
        data: draft.data,
        createdAt: DateTime.now(),
      ),
    );
    if (!mounted) return;

    if (result case Err(:final failure)) {
      _showMessage(failure.message);
      return;
    }
    await _load();
  }

  Future<void> _delete(QrItem item) async {
    final result = await context.qrCodes.delete(item.id);
    if (!mounted) return;
    if (result case Err(:final failure)) {
      _showMessage(failure.message);
      return;
    }
    await _load();
  }

  /// Collects a label and payload. Controllers are disposed in `finally` so
  /// repeated opens don't leak them.
  Future<_QrDraft?> _promptForItem() async {
    final labelController = TextEditingController();
    final dataController = TextEditingController();

    try {
      return await showDialog<_QrDraft>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(
            'Save QR Code',
            style: Theme.of(ctx).textTheme.titleMedium,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: labelController,
                autofocus: true,
                decoration:
                    const InputDecoration(hintText: 'Label (e.g. My WiFi)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: dataController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Content (URL, text, etc.)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final label = labelController.text.trim();
                final data = dataController.text.trim();
                if (label.isEmpty || data.isEmpty) return;
                Navigator.pop(ctx, _QrDraft(label: label, data: data));
              },
              child:
                  const Text('Save', style: TextStyle(color: AppTheme.primary)),
            ),
          ],
        ),
      );
    } finally {
      labelController.dispose();
      dataController.dispose();
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: _buildBody()),
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.page, 0, AppSpacing.page, 20),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _add,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add QR Code'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final failure = _failure;
    if (failure != null) {
      return ErrorView(
        title: 'Could not load QR codes',
        failure: failure,
        onRetry: () {
          setState(() {
            _isLoading = true;
            _failure = null;
          });
          _load();
        },
      );
    }

    if (_items.isEmpty) return _buildEmpty();

    return ListView(
      padding:
          const EdgeInsets.fromLTRB(AppSpacing.page, 0, AppSpacing.page, 20),
      children: [
        GroupCard(
          children: [
            for (var i = 0; i < _items.length; i++) ...[
              _QrRow(
                item: _items[i],
                onTap: () => _openFullscreen(_items[i]),
                onConfirmDelete: _confirmDelete,
                onDeleted: () => _delete(_items[i]),
              ),
              if (i != _items.length - 1) const GroupDivider(indent: 66),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.qr_code_2_rounded, size: 40, color: colors.outlineVariant),
          const SizedBox(height: 12),
          Text(
            'No saved QR codes',
            style: Theme.of(context)
                .textTheme
                .bodyMedium!
                .copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(
            'Add one to show it quickly later',
            style: Theme.of(context)
                .textTheme
                .labelMedium!
                .copyWith(color: colors.outline),
          ),
        ],
      ),
    );
  }

  void _openFullscreen(QrItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QrFullscreenView(data: item.data, label: item.label),
      ),
    );
  }

  Future<bool> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Delete QR code?',
          style: Theme.of(ctx).textTheme.titleMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Delete', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }
}

class _QrDraft {
  const _QrDraft({required this.label, required this.data});
  final String label;
  final String data;
}

class _QrRow extends StatelessWidget {
  const _QrRow({
    required this.item,
    required this.onTap,
    required this.onConfirmDelete,
    required this.onDeleted,
  });

  final QrItem item;
  final VoidCallback onTap;
  final Future<bool> Function() onConfirmDelete;
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: ColoredBox(
        color: AppTheme.error.withValues(alpha: 0.1),
        child: const Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: EdgeInsets.only(right: 20),
            child: Icon(Icons.delete_outline, color: AppTheme.error, size: 20),
          ),
        ),
      ),
      confirmDismiss: (_) => onConfirmDelete(),
      onDismissed: (_) => onDeleted(),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppRadius.control),
                ),
                child: Icon(
                  Icons.qr_code_rounded,
                  size: 20,
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            fontWeight: FontWeight.w500,
                            color: colors.onSurface,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.data,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium!
                          .copyWith(color: colors.outline),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: colors.outlineVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
