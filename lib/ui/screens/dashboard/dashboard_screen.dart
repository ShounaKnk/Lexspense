import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/expense_view.dart';
import '../../../providers/database_provider.dart';
import '../../../providers/expense_provider.dart';
import '../../../providers/matter_provider.dart';
import '../../../providers/reimbursement_provider.dart';
import '../../../providers/selection_provider.dart';
import '../add_expense/add_expense_screen.dart';
import '../matters/matters_screen.dart';
import '../forums/forums_screen.dart';
import '../expense_detail/expense_detail_screen.dart';
import 'widgets/expense_list_tile.dart';
import 'widgets/mark_paid_bottom_sheet.dart';
import 'widgets/summary_header.dart';
import '../../widgets/dot_matrix_background.dart';
import '../../widgets/lexspense_app_bar.dart';
import '../../widgets/search_filter_bar.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  int? _selectedMatterId;
  DateFilterOption _selectedDateFilter = DateFilterOption.all;
  DateTimeRange? _customDateRange;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearAllFilters() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
      _selectedMatterId = null;
      _selectedDateFilter = DateFilterOption.all;
      _customDateRange = null;
    });
  }

  Future<void> _deleteExpense(BuildContext context, ExpenseView view) async {
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

  void _showMarkPaidModal(BuildContext context, List<ExpenseView> selectedExpenses) {
    final totalPaise = selectedExpenses.fold<int>(
      0,
      (sum, item) => sum + item.expense.amountPaise,
    );

    DateTime? maxExpenseDate;
    for (final item in selectedExpenses) {
      try {
        final d = AppDateUtils.fromDbString(item.expense.expenseDate);
        if (maxExpenseDate == null || d.isAfter(maxExpenseDate)) {
          maxExpenseDate = d;
        }
      } catch (_) {}
    }
    final minClaimDate = maxExpenseDate ?? DateTime.now();

    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) => MarkPaidBottomSheet(
        totalPaise: totalPaise,
        count: selectedExpenses.length,
        minClaimDate: minClaimDate,
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
  Widget build(BuildContext context) {
    final unpaidAsync = ref.watch(unpaidExpensesProvider);
    final mattersAsync = ref.watch(allMattersProvider);
    final selectedIds = ref.watch(selectedExpensesProvider);
    final selectionNotifier = ref.read(selectedExpensesProvider.notifier);
    final theme = Theme.of(context);

    final matters = mattersAsync.value ?? [];
    final selectedMatter = _selectedMatterId != null
        ? matters.where((m) => m.id == _selectedMatterId).firstOrNull
        : null;

    final hasActiveFilter = _searchQuery.trim().isNotEmpty ||
        _selectedMatterId != null ||
        _selectedDateFilter != DateFilterOption.all;

    return Scaffold(
      appBar: const LexspenseAppBar(),
      body: DotMatrixBackground(
        child: unpaidAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline_rounded, size: 48, color: theme.colorScheme.error),
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
            // Filter expenses
            final filteredExpenses = expenses.where((item) {
              // 1. Matter filter
              if (_selectedMatterId != null && item.expense.matterId != _selectedMatterId) {
                return false;
              }

              // 2. Date filter
              if (!DateFilterHelper.matchesDate(
                  item.expense.expenseDate, _selectedDateFilter, _customDateRange)) {
                return false;
              }

              // 3. Search text
              if (_searchQuery.trim().isNotEmpty) {
                final q = _searchQuery.toLowerCase().trim();
                final matchesTitle = item.matterTitle.toLowerCase().contains(q);
                final matchesCat = item.categoryName.toLowerCase().contains(q);
                final matchesForum =
                    item.forumName != null && item.forumName!.toLowerCase().contains(q);
                final matchesNotes =
                    item.expense.notes != null && item.expense.notes!.toLowerCase().contains(q);
                final amountRupees = (item.expense.amountPaise / 100.0).toStringAsFixed(2);
                final amountInt = (item.expense.amountPaise ~/ 100).toString();
                final matchesAmount = amountRupees.contains(q) || amountInt == q;
                final matchesRawDate = item.expense.expenseDate.contains(q);
                final matchesDisplayDate =
                    AppDateUtils.toDisplay(item.expense.expenseDate).toLowerCase().contains(q);

                if (!matchesTitle &&
                    !matchesCat &&
                    !matchesForum &&
                    !matchesNotes &&
                    !matchesAmount &&
                    !matchesRawDate &&
                    !matchesDisplayDate) {
                  return false;
                }
              }

              return true;
            }).toList();

            final totalPaise = filteredExpenses.fold<int>(
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
                      count: filteredExpenses.length,
                      selectedCount: selectedIds.length,
                      onSelectAll: () {
                        final allIds = filteredExpenses
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
                              color: const Color(0xFF00897B),
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

                  // Search & Filters Header
                  SliverToBoxAdapter(
                    child: SearchFilterBar(
                      searchController: _searchController,
                      searchQuery: _searchQuery,
                      onSearchChanged: (val) => setState(() => _searchQuery = val),
                      onSearchCleared: () => setState(() {
                        _searchQuery = '';
                        _searchController.clear();
                      }),
                      searchHint: 'Search case, category, notes, or ₹...',
                      selectedMatterId: _selectedMatterId,
                      selectedMatterTitle: selectedMatter?.caseTitle,
                      matters: matters,
                      onMatterChanged: (id) => setState(() => _selectedMatterId = id),
                      selectedDateFilter: _selectedDateFilter,
                      customDateRange: _customDateRange,
                      onDateFilterChanged: (opt, range) => setState(() {
                        _selectedDateFilter = opt;
                        _customDateRange = range;
                      }),
                      onClearAll: _clearAllFilters,
                      activeFilterSummary: hasActiveFilter
                          ? 'Showing ${filteredExpenses.length} of ${expenses.length} expenses'
                          : null,
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
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('Log New Expense'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else if (filteredExpenses.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.search_off_rounded,
                                  size: 44,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No Matching Expenses Found',
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Try clearing or adjusting your search term, case filter, or date range.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 18),
                              FilledButton.tonalIcon(
                                onPressed: _clearAllFilters,
                                icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
                                label: const Text('Reset All Filters'),
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
                            final item = filteredExpenses[index];
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
                              onEdit: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => AddExpenseScreen(expenseToEdit: item),
                                  ),
                                );
                              },
                              onDelete: () => _deleteExpense(context, item),
                            );
                          },
                          childCount: filteredExpenses.length,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
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
                  onPressed: () => _showMarkPaidModal(context, selectedExpenses),
                  icon: const Icon(Icons.check_circle_rounded),
                  label: Text(
                    'Claim Selected (${selectedExpenses.length}) • ${CurrencyUtils.format(selectedPaise)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              },
              orElse: () => const SizedBox.shrink(),
            )
          : null,
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
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(
          color: theme.dividerColor,
          width: 0.8,
        ),
      ),
      color: isDark ? const Color(0xFF121216) : Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E22) : const Color(0xFFECECEF),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isDark ? const Color(0xFF2E2E34) : const Color(0xFFD6D6DC),
                    width: 0.8,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
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
                Icons.chevron_right_rounded,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
