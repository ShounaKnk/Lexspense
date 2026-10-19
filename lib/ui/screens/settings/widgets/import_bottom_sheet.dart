import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../providers/import_provider.dart';

/// Shows the Excel Import modal bottom sheet.
Future<void> showImportBottomSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const ImportBottomSheet(),
  );
}

class ImportBottomSheet extends ConsumerStatefulWidget {
  const ImportBottomSheet({super.key});

  @override
  ConsumerState<ImportBottomSheet> createState() => _ImportBottomSheetState();
}

class _ImportBottomSheetState extends ConsumerState<ImportBottomSheet> {
  bool _showWarnings = false;

  @override
  void initState() {
    super.initState();
    // Reset import state when sheet opens fresh
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(importProvider.notifier).reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(importProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 20,
        right: 20,
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: theme.dividerColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            if (state.status == ImportStatus.idle || state.status == ImportStatus.picking)
              _buildInitialState(context, state, theme, isDark)
            else if (state.status == ImportStatus.parsing)
              _buildParsingState(context, state, theme)
            else if (state.status == ImportStatus.completed)
              _buildCompletedState(context, state, theme)
            else if (state.status == ImportStatus.error)
              _buildErrorState(context, state, theme),
          ],
        ),
      ),
    );
  }

  /// Initial state: explains the format and offers file selection & template download.
  Widget _buildInitialState(
    BuildContext context,
    ImportState state,
    ThemeData theme,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.upload_file_rounded,
                color: Color(0xFF2E7D32),
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Import Expenses',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Upload your historical expenses via Excel',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Information Callout
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Supported Columns in Row 1:',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              _buildColumnChipRow(
                ['Date *', 'Amount *', 'Category *', 'Case / Matter *'],
                isMandatory: true,
                theme: theme,
              ),
              const SizedBox(height: 6),
              _buildColumnChipRow(
                ['Court / Forum', 'Compensated', 'Notes'],
                isMandatory: false,
                theme: theme,
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 15,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Compensated items are stored directly into Reimbursement History. Uncompensated items appear on your Dashboard. Missing cases and categories are auto-created.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Action Buttons
        FilledButton.icon(
          icon: state.status == ImportStatus.picking
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.file_open_rounded),
          label: Text(state.status == ImportStatus.picking ? 'Selecting File…' : 'Select Excel File (.xlsx / .xls)'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: state.status == ImportStatus.picking
              ? null
              : () => ref.read(importProvider.notifier).pickAndImport(),
        ),
        const SizedBox(height: 10),

        OutlinedButton.icon(
          icon: const Icon(Icons.download_rounded, size: 18),
          label: const Text('Download Sample Template'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () async {
            final path = await ref.read(importProvider.notifier).downloadTemplate();
            if (context.mounted && path != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Sample template saved to:\n$path'),
                  duration: const Duration(seconds: 4),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildColumnChipRow(List<String> labels, {required bool isMandatory, required ThemeData theme}) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: labels.map((label) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: isMandatory
                ? theme.colorScheme.primary.withOpacity(0.12)
                : theme.colorScheme.onSurface.withOpacity(0.06),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isMandatory ? FontWeight.bold : FontWeight.normal,
              color: isMandatory ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Parsing progress state
  Widget _buildParsingState(
    BuildContext context,
    ImportState state,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.hourglass_top_rounded,
              color: theme.colorScheme.primary,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Importing Expenses…',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            state.totalItems > 0
                ? 'Processing row ${state.currentItem} of ${state.totalItems}'
                : 'Reading spreadsheet records…',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: state.progress > 0 ? state.progress : null,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Please keep Lexspense open while the records are being saved.',
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  /// Success state with stats and optional warnings expander
  Widget _buildCompletedState(
    BuildContext context,
    ImportState state,
    ThemeData theme,
  ) {
    final result = state.result;
    if (result == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.paidBadge.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: AppColors.paidBadge,
              size: 44,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: Text(
            'Import Completed!',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            '${result.imported} expense records successfully added to your database.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Stats Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Imported', '${result.imported}', AppColors.paidBadge, theme),
              Container(width: 1, height: 32, color: theme.dividerColor.withOpacity(0.2)),
              _buildStatItem('Skipped', '${result.skipped}', theme.colorScheme.error, theme),
              Container(width: 1, height: 32, color: theme.dividerColor.withOpacity(0.2)),
              _buildStatItem('Total Rows', '${result.totalRows}', theme.colorScheme.primary, theme),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Warnings / Skipped Details
        if (result.hasWarnings) ...[
          InkWell(
            onTap: () => setState(() => _showWarnings = !_showWarnings),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Row(
                children: [
                  Icon(
                    _showWarnings ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    size: 20,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${result.warnings.length} notices / skipped items',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.error,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _showWarnings ? 'Hide details' : 'Show details',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_showWarnings)
            Container(
              constraints: const BoxConstraints(maxHeight: 160),
              margin: const EdgeInsets.only(top: 4, bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: theme.colorScheme.error.withOpacity(0.2)),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: result.warnings.length,
                separatorBuilder: (_, __) => Divider(height: 8, color: theme.dividerColor.withOpacity(0.1)),
                itemBuilder: (context, idx) {
                  return Text(
                    result.warnings[idx],
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.error,
                      height: 1.3,
                    ),
                  );
                },
              ),
            ),
        ],

        const SizedBox(height: 16),
        FilledButton(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, Color color, ThemeData theme) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 11,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  /// Error state
  Widget _buildErrorState(
    BuildContext context,
    ImportState state,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.error.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline_rounded,
              color: theme.colorScheme.error,
              size: 44,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: Text(
            'Import Failed',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.error.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.error.withOpacity(0.2)),
          ),
          child: Text(
            state.errorMessage ?? 'An unknown error occurred while importing the spreadsheet.',
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.error,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 16),

        FilledButton.tonalIcon(
          icon: const Icon(Icons.download_rounded),
          label: const Text('Download Official Template'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () async {
            final path = await ref.read(importProvider.notifier).downloadTemplate();
            if (context.mounted && path != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Sample template saved to:\n$path'),
                  duration: const Duration(seconds: 4),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        ),
        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Dismiss'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => ref.read(importProvider.notifier).pickAndImport(),
                child: const Text('Try Again'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
