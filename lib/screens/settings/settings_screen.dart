import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/dependencies.dart';
import '../../core/failure.dart';
import '../../core/result.dart';
import '../../state/theme_controller.dart';
import '../../utils/app_theme.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/group_card.dart';
import '../../widgets/large_title_bar.dart';
import '../../utils/app_spacing.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isExporting = false;
  bool _isImporting = false;

  @override
  Widget build(BuildContext context) {
    final isDark = context.select<ThemeController, bool>((c) => c.isDarkMode);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const LargeTitleBar(title: 'Settings'),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.page, 0, AppSpacing.page, 40),
            sliver: SliverList.list(
              children: [
                const GroupLabel('Appearance'),
                const SizedBox(height: 8),
                GroupCard(
                  children: [
                    _ToggleRow(
                      icon: Icons.dark_mode_rounded,
                      title: 'Dark Mode',
                      value: isDark,
                      onChanged: (_) =>
                          context.read<ThemeController>().toggle(),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                const GroupLabel('Data'),
                const SizedBox(height: 8),
                GroupCard(
                  children: [
                    _ActionRow(
                      icon: Icons.upload_file_rounded,
                      title: 'Export',
                      subtitle: 'Save as JSON file',
                      isLoading: _isExporting,
                      onTap: _handleExport,
                    ),
                    const GroupDivider(indent: 52),
                    _ActionRow(
                      icon: Icons.download_rounded,
                      title: 'Import',
                      subtitle: 'From clipboard',
                      isLoading: _isImporting,
                      onTap: _handleImport,
                    ),
                    const GroupDivider(indent: 52),
                    _ActionRow(
                      icon: Icons.delete_outline_rounded,
                      title: 'Clear All Data',
                      subtitle: 'Remove everything',
                      isDestructive: true,
                      onTap: _handleClear,
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                const GroupLabel('About'),
                const SizedBox(height: 8),
                const GroupCard(
                  children: [
                    _InfoRow(
                      icon: Icons.info_outline_rounded,
                      title: 'Version',
                      value: '1.0.0',
                    ),
                    GroupDivider(indent: 52),
                    _InfoRow(
                      icon: Icons.code_rounded,
                      title: 'Built with',
                      value: 'Flutter',
                    ),
                    GroupDivider(indent: 52),
                    _InfoRow(
                      icon: Icons.storage_rounded,
                      title: 'Storage',
                      value: 'SQLite (local)',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleExport() async {
    setState(() => _isExporting = true);
    final result = await context.exportService.exportToShareSheet();
    if (!mounted) return;
    setState(() => _isExporting = false);
    if (result case Err(:final failure)) _showFailure(failure);
  }

  Future<void> _handleImport() async {
    // Captured before the dialog await, so context isn't used across the gap.
    final importService = context.importService;
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Import from Clipboard',
      message: 'Copy your exported JSON to the clipboard first, then tap '
          'Import. Records that already exist are skipped.',
      confirmLabel: 'Import',
      confirmColor: AppTheme.primary,
    );
    if (!confirmed) return;

    setState(() => _isImporting = true);
    final result = await importService.importFromClipboard();
    if (!mounted) return;
    setState(() => _isImporting = false);

    result.fold(
      onOk: (counts) => _showMessage(
        counts.total == 0
            ? 'Nothing new to import — all records already exist.'
            : 'Imported ${counts.total} items '
                '(${counts.notes} notes, ${counts.jobs} jobs, '
                '${counts.qrCodes} QR codes).',
      ),
      onErr: _showFailure,
    );
  }

  Future<void> _handleClear() async {
    final backup = context.backup;
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Clear all data?',
      message: 'This permanently deletes all notes, applications, and QR '
          'codes. It cannot be undone.',
      confirmLabel: 'Clear All',
      confirmColor: AppTheme.error,
    );
    if (!confirmed) return;

    final result = await backup.clearAll();
    if (!mounted) return;
    result.fold(
      onOk: (_) => _showMessage('All data cleared.'),
      onErr: _showFailure,
    );
  }

  void _showFailure(Failure failure) => _showMessage(failure.message);

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colors.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title,
                style: Theme.of(context).textTheme.titleSmall!.copyWith(
                      fontWeight: FontWeight.w400,
                      color: colors.onSurface,
                    )),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppTheme.primary,
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDestructive = false,
    this.isLoading = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDestructive;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tint = isDestructive ? AppTheme.error : colors.onSurfaceVariant;

    return InkWell(
      onTap: isLoading ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Icon(icon, size: 20, color: tint),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall!.copyWith(
                          fontWeight: FontWeight.w400,
                          color:
                              isDestructive ? AppTheme.error : colors.onSurface,
                        ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium!
                        .copyWith(color: colors.outline),
                  ),
                ],
              ),
            ),
            if (isLoading)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.primary,
                ),
              )
            else
              Icon(Icons.chevron_right_rounded,
                  size: 16, color: colors.outlineVariant),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colors.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title,
                style: Theme.of(context).textTheme.titleSmall!.copyWith(
                      fontWeight: FontWeight.w400,
                      color: colors.onSurface,
                    )),
          ),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall!
                  .copyWith(color: colors.outline)),
        ],
      ),
    );
  }
}
