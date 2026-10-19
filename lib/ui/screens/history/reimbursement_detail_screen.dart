import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/receipt_image.dart';
import '../../../data/models/reimbursement.dart';
import '../../../providers/database_provider.dart';
import '../../../providers/expense_provider.dart';
import '../../../providers/reimbursement_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../core/theme/app_typography.dart';
import '../../widgets/category_icon_badge.dart';
import '../../widgets/dot_matrix_background.dart';
import '../expense_detail/expense_detail_screen.dart';

class ReimbursementDetailScreen extends ConsumerStatefulWidget {
  final Reimbursement reimbursement;

  const ReimbursementDetailScreen({super.key, required this.reimbursement});

  @override
  ConsumerState<ReimbursementDetailScreen> createState() => _ReimbursementDetailScreenState();
}

class _ReimbursementDetailScreenState extends ConsumerState<ReimbursementDetailScreen> {
  bool _isGeneratingPdf = false;
  bool _isUndoing = false;
  Map<int, List<ReceiptImage>> _receiptsMap = {};

  @override
  void initState() {
    super.initState();
    _loadReceipts();
  }

  Future<void> _loadReceipts() async {
    final expensesAsync = await ref.read(
      reimbursementExpensesProvider(widget.reimbursement.id!).future,
    );
    final expenseIds = expensesAsync
        .where((e) => e.expense.id != null)
        .map((e) => e.expense.id!)
        .toList();

    if (expenseIds.isNotEmpty) {
      final map = await ref.read(expenseRepositoryProvider).getReceiptsForExpenses(expenseIds);
      if (mounted) {
        setState(() {
          _receiptsMap = map;
        });
      }
    }
  }

  Future<void> _exportPdf() async {
    setState(() => _isGeneratingPdf = true);
    try {
      final expenses = await ref.read(
        reimbursementExpensesProvider(widget.reimbursement.id!).future,
      );

      final profile = ref.read(settingsProvider).value ?? const LawyerProfile();

      await ref.read(pdfServiceProvider).generateAndShareVoucher(
        reimbursement: widget.reimbursement,
        expenses: expenses,
        receiptsByExpense: _receiptsMap,
        lawyerName: profile.lawyerName,
        firmName: profile.firmName,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate PDF: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingPdf = false);
      }
    }
  }

  Future<void> _undoReimbursement() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Undo Reimbursement?'),
        content: Text(
          widget.reimbursement.itemCount == 1
              ? 'This will return this expense back to your unpaid home list. You can log it again later.'
              : 'This will return all items in this batch back to your unpaid home list. You can log them again later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Undo Batch'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isUndoing = true);
      try {
        await ref.read(reimbursementRepositoryProvider).undoReimbursement(widget.reimbursement.id!);
        ref.invalidate(unpaidExpensesProvider);
        ref.invalidate(reimbursementsListProvider);
        await ref.read(widgetSyncServiceProvider).updateWidgetData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reimbursement undone. Expenses restored to dashboard.')),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isUndoing = false);
        }
      }
    }
  }

  void _showImageDialog(File file, String title) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
            ),
            InteractiveViewer(
              child: Image.file(file, fit: BoxFit.contain),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expensesAsync = ref.watch(reimbursementExpensesProvider(widget.reimbursement.id!));
    final receiptStorage = ref.watch(receiptStorageServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.reimbursement.itemCount == 1
              ? (widget.reimbursement.singleCategoryName ?? 'Claim Details')
              : 'Batch #RV-${widget.reimbursement.id.toString().padLeft(4, '0')}',
        ),
        actions: [
          IconButton(
            icon: _isGeneratingPdf
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.share_rounded),
            tooltip: 'Export & Share PDF Voucher',
            onPressed: _isGeneratingPdf ? null : _exportPdf,
          ),
          IconButton(
            icon: const Icon(Icons.undo_rounded),
            tooltip: 'Undo Reimbursement',
            onPressed: _isUndoing ? null : _undoReimbursement,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: DotMatrixBackground(
        child: expensesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (expenses) {
            final isDark = theme.brightness == Brightness.dark;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Banner
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF121216) : Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isDark ? const Color(0xFF28282E) : const Color(0xFF1A1A1E),
                        width: 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white : Colors.black,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'SETTLED / REIMBURSED',
                                style: TextStyle(
                                  color: isDark ? Colors.black : Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            Text(
                              AppDateUtils.toDisplay(widget.reimbursement.datePaid),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '₹ ',
                              style: AppTypography.spaceGrotesk(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              CurrencyUtils.format(widget.reimbursement.totalAmountPaise).replaceAll('₹', '').trim(),
                              style: AppTypography.ndot(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: theme.colorScheme.onSurface,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Total payout for ${expenses.length} item(s)',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (widget.reimbursement.notes != null &&
                            widget.reimbursement.notes!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Divider(color: theme.dividerColor, height: 1),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.notes_rounded, size: 16, color: theme.colorScheme.onSurfaceVariant),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  widget.reimbursement.notes!,
                                  style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Export Button Card
                  FilledButton.icon(
                    onPressed: _isGeneratingPdf ? null : _exportPdf,
                    icon: const Icon(Icons.picture_as_pdf_rounded),
                    label: Text(_isGeneratingPdf ? 'Generating PDF...' : 'Share Formal PDF Voucher'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Itemized List
                  Text(
                    'Itemized Out-of-Pocket Expenses',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: expenses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = expenses[index];
                      final receipts = _receiptsMap[item.expense.id] ?? [];

                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                          side: BorderSide(color: theme.dividerColor, width: 0.8),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(6),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ExpenseDetailScreen.fromView(item),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CategoryIconBadge(
                                      iconKey: item.categoryIcon,
                                      size: 38,
                                      iconSize: 18,
                                      borderRadius: 6,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.categoryName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: -0.2,
                                            ),
                                          ),
                                          Text(
                                            '${item.matterTitle} • ${AppDateUtils.toDisplay(item.expense.expenseDate)}',
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: theme.colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      CurrencyUtils.format(item.expense.amountPaise),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                                if (item.expense.notes != null && item.expense.notes!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    item.expense.notes!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontStyle: FontStyle.italic,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                                // Receipts thumbnail strip
                                if (receipts.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    height: 50,
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: receipts.length,
                                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                                      itemBuilder: (context, rIdx) {
                                        final receipt = receipts[rIdx];
                                        return FutureBuilder<File>(
                                          future: receiptStorage.getReceiptFile(receipt.fileName),
                                          builder: (context, snapshot) {
                                            if (snapshot.hasData && snapshot.data!.existsSync()) {
                                              return GestureDetector(
                                                onTap: () => _showImageDialog(
                                                  snapshot.data!,
                                                  'Receipt for ${item.matterTitle}',
                                                ),
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(4),
                                                  child: Image.file(
                                                    snapshot.data!,
                                                    width: 50,
                                                    height: 50,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              );
                                            }
                                            return const SizedBox.shrink();
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
