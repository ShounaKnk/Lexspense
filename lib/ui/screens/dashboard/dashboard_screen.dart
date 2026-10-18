import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../data/models/expense_view.dart';
import '../../../providers/database_provider.dart';
import '../../../providers/expense_provider.dart';
import '../../../providers/reimbursement_provider.dart';
import '../../../providers/selection_provider.dart';
import '../add_expense/add_expense_screen.dart';
import '../matters/matters_screen.dart';
import '../forums/forums_screen.dart';
import '../expense_detail/expense_detail_screen.dart';
import 'widgets/expense_list_tile.dart';
import 'widgets/mark_paid_bottom_sheet.dart';
import 'widgets/summary_header.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Future<void> _deleteExpense(BuildContext context, WidgetRef ref, ExpenseView view) async {
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

    if (confirm == true && view.expense.id != null) {
      await ref.read(expenseRepositoryProvider).deleteExpense(view.expense.id!);
      ref.read(selectedExpensesProvider.notifier).toggle(view.expense.id!); // clear if selected
      ref.invalidate(unpaidExpensesProvider);
      ref.read(widgetSyncServiceProvider).updateWidgetData();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense deleted successfully')),
        );
      }
    }
  }

  void _showMarkPaidModal(BuildContext context, WidgetRef ref, List<ExpenseView> selectedExpenses) {
    final totalPaise = selectedExpenses.fold<int>(
      0,
      (sum, item) => sum + item.expense.amountPaise,
    );

    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => MarkPaidBottomSheet(
        totalPaise: totalPaise,
        count: selectedExpenses.length,
        onConfirm: (datePaid, notes) async {
          final expenseIds = selectedExpenses.map((e) => e.expense.id!).toList();
          await ref.read(reimbursementRepositoryProvider).createReimbursement(
            expenseIds: expenseIds,
            datePaid: datePaid,
            notes: notes,
          );
          ref.read(selectedExpensesProvider.notifier).clear();
          ref.invalidate(unpaidExpensesProvider);
          ref.invalidate(reimbursementsListProvider);
          ref.read(widgetSyncServiceProvider).updateWidgetData();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unpaidAsync = ref.watch(unpaidExpensesProvider);
    final selectedIds = ref.watch(selectedExpensesProvider);
    final selectionNotifier = ref.read(selectedExpensesProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.gavel_rounded, color: theme.colorScheme.primary, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'Lexspense',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.3),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 26),
            tooltip: 'Add Expense',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: unpaidAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                const SizedBox(height: 12),
                Text('Error loading expenses: $err', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: () => ref.refresh(unpaidExpensesProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (expenses) {
          final totalPaise = expenses.fold<int>(
            0,
            (sum, item) => sum + item.expense.amountPaise,
          );

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(unpaidExpensesProvider);
              await ref.read(widgetSyncServiceProvider).updateWidgetData();
            },
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: SummaryHeader(
                    totalPaise: totalPaise,
                    count: expenses.length,
                    selectedCount: selectedIds.length,
                    onSelectAll: () {
                      final allIds = expenses
                          .where((e) => e.expense.id != null)
                          .map((e) => e.expense.id!)
                          .toList();
                      selectionNotifier.selectAll(allIds);
                    },
                    onClearSelection: () => selectionNotifier.clear(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: _QuickNavCard(
                            title: 'Client Matters',
                            subtitle: 'Manage Cases',
                            icon: Icons.business_center_rounded,
                            color: theme.colorScheme.primary,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const MattersScreen()),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _QuickNavCard(
                            title: 'Courts / Forums',
                            subtitle: 'Manage Forums',
                            icon: Icons.account_balance_rounded,
                            color: const Color(0xFF1565C0),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const ForumsScreen()),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (expenses.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.task_alt_rounded,
                                size: 54,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'All Expenses Settled!',
                              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No pending out-of-pocket expenses right now. Log your court fees, printing, or travel costs as you incur them.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 24),
                            FilledButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
                                );
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Log New Expense'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.only(bottom: 96, top: 4),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = expenses[index];
                          final id = item.expense.id!;
                          final isSelected = selectedIds.contains(id);

                          return ExpenseListTile(
                            expenseView: item,
                            isSelected: isSelected,
                            onSelected: (_) => selectionNotifier.toggle(id),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ExpenseDetailScreen.fromView(item),
                                ),
                              );
                            },
                            onDelete: () => _deleteExpense(context, ref, item),
                          );
                        },
                        childCount: expenses.length,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: selectedIds.isNotEmpty
          ? unpaidAsync.maybeWhen(
              data: (expenses) {
                final selectedExpenses = expenses
                    .where((e) => e.expense.id != null && selectedIds.contains(e.expense.id!))
                    .toList();
                final selectedPaise = selectedExpenses.fold<int>(
                  0,
                  (sum, item) => sum + item.expense.amountPaise,
                );

                return FloatingActionButton.extended(
                  onPressed: () => _showMarkPaidModal(context, ref, selectedExpenses),
                  icon: const Icon(Icons.check_circle),
                  label: Text(
                    'Claim ${CurrencyUtils.format(selectedPaise)} (${selectedIds.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                );
              },
              orElse: () => null,
            )
          : FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Expense'),
            ),
    );
  }
}

class _QuickNavCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickNavCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.12)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
