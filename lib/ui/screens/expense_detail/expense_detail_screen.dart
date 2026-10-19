import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/icon_map.dart';
import '../../../data/models/expense_view.dart';
import '../../../providers/database_provider.dart';
import '../../../providers/expense_provider.dart';
import '../../../providers/reimbursement_provider.dart';
import '../../../providers/selection_provider.dart';
import '../../widgets/dot_matrix_background.dart';
import '../dashboard/widgets/mark_paid_bottom_sheet.dart';
import '../history/reimbursement_detail_screen.dart';

class ExpenseDetailScreen extends ConsumerStatefulWidget {
  final int expenseId;
  final ExpenseView? initialExpenseView;

  const ExpenseDetailScreen({
    super.key,
    required this.expenseId,
    this.initialExpenseView,
  });

  factory ExpenseDetailScreen.fromView(ExpenseView view) => ExpenseDetailScreen(
        expenseId: view.expense.id!,
        initialExpenseView: view,
      );

  @override
  ConsumerState<ExpenseDetailScreen> createState() => _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends ConsumerState<ExpenseDetailScreen> {
  Future<void> _deleteExpense(ExpenseView view) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Expense?'),
        content: Text(
          'Are you sure you want to delete ${CurrencyUtils.format(view.expense.amountPaise)} for "${view.matterTitle}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      await ref.read(expenseRepositoryProvider).deleteExpense(view.expense.id!);
      ref.read(selectedExpensesProvider.notifier).toggle(view.expense.id!);
      ref.invalidate(unpaidExpensesProvider);
      await ref.read(widgetSyncServiceProvider).updateWidgetData();
      if (!mounted) return;
      Navigator.of(context).pop(); // Exit detail screen
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense deleted successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting expense: $e')),
      );
    }
  }

  void _showMarkPaidModal(ExpenseView view) {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) => MarkPaidBottomSheet(
        totalPaise: view.expense.amountPaise,
        count: 1,
        onConfirm: (datePaid, notes) async {
          await ref.read(reimbursementRepositoryProvider).createReimbursement(
            expenseIds: [view.expense.id!],
            datePaid: datePaid,
            notes: notes,
          );
          ref.read(selectedExpensesProvider.notifier).clear();
          ref.invalidate(unpaidExpensesProvider);
          ref.invalidate(reimbursementsListProvider);
          ref.invalidate(singleExpenseProvider(widget.expenseId));
          await ref.read(widgetSyncServiceProvider).updateWidgetData();
          if (!mounted) return;
          Navigator.of(context).pop(); // close modal
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Expense marked as reimbursed')),
          );
        },
      ),
    );
  }

  void _showImageDialog(File file, String title) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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
              minScale: 0.8,
              maxScale: 4.0,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                child: Image.file(file, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expenseAsync = ref.watch(singleExpenseProvider(widget.expenseId));
    final receiptsAsync = ref.watch(expenseReceiptsProvider(widget.expenseId));
    final storage = ref.watch(receiptStorageServiceProvider);

    final expenseView = expenseAsync.value ?? widget.initialExpenseView;

    if (expenseView == null && expenseAsync.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (expenseView == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Expense Details')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 12),
              const Text('Expense record not found'),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final expense = expenseView.expense;
    final isReimbursed = expense.reimbursementId != null;
    final iconData = IconMap.fromKey(expenseView.categoryIcon);

    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Details'),
        actions: [
          if (!isReimbursed)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Delete Expense',
              color: theme.colorScheme.error,
              onPressed: () => _deleteExpense(expenseView),
            ),
        ],
      ),
      body: DotMatrixBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            // -------------------------------------------------------------------
            // 1. HERO AMOUNT & STATUS CARD
            // -------------------------------------------------------------------
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
                      // Category pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E1E22) : const Color(0xFFECECEF),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isDark ? const Color(0xFF2E2E34) : const Color(0xFFD6D6DC),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              iconData,
                              size: 14,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              expenseView.categoryName,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isReimbursed
                              ? (isDark ? Colors.white : Colors.black)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isDark ? Colors.white : Colors.black,
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isReimbursed ? Icons.check_circle_rounded : Icons.pending_rounded,
                              size: 13,
                              color: isReimbursed
                                  ? (isDark ? Colors.black : Colors.white)
                                  : (isDark ? Colors.white : Colors.black),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isReimbursed ? 'Reimbursed' : 'Unpaid',
                              style: TextStyle(
                                color: isReimbursed
                                    ? (isDark ? Colors.black : Colors.white)
                                    : (isDark ? Colors.white : Colors.black),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
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
                        CurrencyUtils.format(expense.amountPaise).replaceAll('₹', '').trim(),
                        style: AppTypography.ndot(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Incurred on ${AppDateUtils.toDisplay(expense.expenseDate)}',
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // -------------------------------------------------------------------
            // 2. CASE & FORUM METADATA CARD
            // -------------------------------------------------------------------
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
                side: BorderSide(color: theme.dividerColor, width: 0.8),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    _DetailRow(
                      icon: Icons.business_center_rounded,
                      label: 'Client Matter / Case',
                      value: expenseView.matterTitle,
                      isBold: true,
                    ),
                    Divider(height: 20, color: theme.dividerColor),
                    _DetailRow(
                      icon: Icons.account_balance_rounded,
                      label: 'Court / Forum',
                      value: (expenseView.forumName != null && expenseView.forumName!.isNotEmpty)
                          ? expenseView.forumName!
                          : 'No forum specified',
                    ),
                    Divider(height: 20, color: theme.dividerColor),
                    _DetailRow(
                      icon: Icons.calendar_today_rounded,
                      label: 'Expense Date',
                      value: AppDateUtils.toDisplay(expense.expenseDate),
                    ),
                    if (expense.createdAt != null) ...[
                      Divider(height: 20, color: theme.dividerColor),
                      _DetailRow(
                        icon: Icons.schedule_rounded,
                        label: 'Logged Timestamp',
                        value: expense.createdAt!,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // -------------------------------------------------------------------
            // 3. DESCRIPTION / NOTES
            // -------------------------------------------------------------------
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
                side: BorderSide(color: theme.dividerColor, width: 0.8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.notes_rounded, size: 18, color: theme.colorScheme.onSurface),
                        const SizedBox(width: 8),
                        Text(
                          'Description & Purpose',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      (expense.notes != null && expense.notes!.trim().isNotEmpty)
                          ? expense.notes!
                          : 'No description or notes provided for this expense.',
                      style: TextStyle(
                        color: (expense.notes != null && expense.notes!.trim().isNotEmpty)
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                        fontStyle: (expense.notes != null && expense.notes!.trim().isNotEmpty)
                            ? FontStyle.normal
                            : FontStyle.italic,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // -------------------------------------------------------------------
            // 4. REIMBURSEMENT SETTLEMENT INFO (IF PAID)
            // -------------------------------------------------------------------
            if (isReimbursed) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF121216) : Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: theme.dividerColor, width: 0.8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.verified_rounded, color: theme.colorScheme.onSurface, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Settlement Record',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Batch Voucher:'),
                        Text(
                          '#RV-${expense.reimbursementId.toString().padLeft(4, '0')}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    if (expenseView.reimbursementDatePaid != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Date Settled:'),
                          Text(
                            AppDateUtils.toDisplay(expenseView.reimbursementDatePaid!),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                    if (expenseView.reimbursementNotes != null &&
                        expenseView.reimbursementNotes!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Payment Ref:'),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              expenseView.reimbursementNotes!,
                              textAlign: TextAlign.end,
                              style: const TextStyle(fontStyle: FontStyle.italic),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      onPressed: () async {
                        final reimbursement = await ref
                            .read(reimbursementRepositoryProvider)
                            .getReimbursementById(expense.reimbursementId!);
                        if (reimbursement != null && context.mounted) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ReimbursementDetailScreen(reimbursement: reimbursement),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.receipt_long_rounded, size: 18),
                      label: const Text('View Full Settlement Voucher'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // -------------------------------------------------------------------
            // 5. ATTACHED RECEIPTS & PROOFS
            // -------------------------------------------------------------------
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
                side: BorderSide(color: theme.dividerColor, width: 0.8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.photo_library_rounded,
                                size: 18, color: theme.colorScheme.onSurface),
                            const SizedBox(width: 8),
                            Text(
                              'Attached Receipts',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                        receiptsAsync.maybeWhen(
                          data: (receipts) => receipts.isNotEmpty
                              ? Container(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1E1E22) : const Color(0xFFECECEF),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: isDark ? const Color(0xFF2E2E34) : const Color(0xFFD6D6DC),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Text(
                                    '${receipts.length} photo(s)',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : Colors.black,
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                          orElse: () => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    receiptsAsync.when(
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      error: (e, _) => Text('Error loading receipts: $e'),
                      data: (receipts) {
                        if (receipts.isEmpty) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF121216) : Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: theme.dividerColor,
                                width: 0.8,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.receipt_long_rounded,
                                  size: 32,
                                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No receipt photos attached',
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 1.0,
                          ),
                          itemCount: receipts.length,
                          itemBuilder: (context, idx) {
                            final receipt = receipts[idx];
                            return FutureBuilder<File>(
                              future: storage.getReceiptFile(receipt.fileName),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF1E1E22) : Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Center(
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  );
                                }

                                final file = snapshot.data!;
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.file(file, fit: BoxFit.cover),
                                      Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () => _showImageDialog(
                                            file,
                                            'Receipt Proof ${idx + 1}',
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        right: 6,
                                        bottom: 6,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.7),
                                            borderRadius: BorderRadius.circular(3),
                                          ),
                                          child: const Icon(
                                            Icons.fullscreen_rounded,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomSheet: !isReimbursed
          ? Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                border: Border(top: BorderSide(color: theme.dividerColor, width: 0.8)),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                          side: BorderSide(color: theme.colorScheme.error.withOpacity(0.6)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        onPressed: () => _deleteExpense(expenseView),
                        icon: const Icon(Icons.delete_outline_rounded, size: 20),
                        label: const Text('Delete'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        onPressed: () => _showMarkPaidModal(expenseView),
                        icon: const Icon(Icons.check_circle_rounded, size: 20),
                        label: const Text('Claim This Expense'),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isBold;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
