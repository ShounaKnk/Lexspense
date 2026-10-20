import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../providers/matter_provider.dart';
import '../../../providers/reimbursement_provider.dart';
import '../../widgets/dot_matrix_background.dart';
import '../../widgets/lexspense_app_bar.dart';
import '../../widgets/search_filter_bar.dart';
import '../expense_detail/expense_detail_screen.dart';
import 'reimbursement_detail_screen.dart';
import 'widgets/reimbursement_tile.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
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

  @override
  Widget build(BuildContext context) {
    final reimbursementsAsync = ref.watch(reimbursementsListProvider);
    final mattersAsync = ref.watch(allMattersProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 2),
              child: PageHeaderTitle(
                title: 'History',
                subtitle: 'Past claims, settled vouchers & payment records',
              ),
            ),

            // Search & Filter Bar
            SearchFilterBar(
              searchController: _searchController,
              searchQuery: _searchQuery,
              onSearchChanged: (val) => setState(() => _searchQuery = val),
              onSearchCleared: () => setState(() {
                _searchQuery = '';
                _searchController.clear();
              }),
              searchHint: 'Search voucher, case, notes, or ₹...',
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
              activeFilterSummary: hasActiveFilter ? null : null,
            ),

            Expanded(
              child: reimbursementsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline_rounded, size: 48, color: theme.colorScheme.error),
                      const SizedBox(height: 12),
                      Text('Error loading history: $e'),
                      const SizedBox(height: 12),
                      FilledButton.tonal(
                        onPressed: () => ref.refresh(reimbursementsListProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (batches) {
                  if (batches.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E1E22) : const Color(0xFFECECEF),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF2E2E34) : const Color(0xFFD6D6DC),
                                  width: 0.8,
                                ),
                              ),
                              child: Icon(
                                Icons.history_edu_rounded,
                                size: 40,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'No Reimbursements Yet',
                              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'When your senior pays or settles your logged expenses on the dashboard, the record and receipts will appear here.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Apply search and filters
                  final filteredBatches = batches.where((batch) {
                    // 1. Case filter
                    if (_selectedMatterId != null) {
                      if (!batch.matchesMatterId(_selectedMatterId!)) {
                        return false;
                      }
                    }

                    // 2. Date filter (datePaid)
                    if (!DateFilterHelper.matchesDate(
                        batch.datePaid, _selectedDateFilter, _customDateRange)) {
                      return false;
                    }

                    // 3. Search query
                    if (_searchQuery.trim().isNotEmpty) {
                      final q = _searchQuery.toLowerCase().trim();
                      final matchesNotes = batch.notes != null && batch.notes!.toLowerCase().contains(q);
                      final matchesSingleTitle = batch.singleMatterTitle != null &&
                          batch.singleMatterTitle!.toLowerCase().contains(q);
                      final matchesAllTitles = batch.allMatterTitles != null &&
                          batch.allMatterTitles!.toLowerCase().contains(q);
                      final matchesCat = batch.singleCategoryName != null &&
                          batch.singleCategoryName!.toLowerCase().contains(q);
                      final matchesAllCats = batch.allCategoryNames != null &&
                          batch.allCategoryNames!.toLowerCase().contains(q);
                      final amountRupees = (batch.totalAmountPaise / 100.0).toStringAsFixed(2);
                      final amountInt = (batch.totalAmountPaise ~/ 100).toString();
                      final matchesAmount = amountRupees.contains(q) || amountInt == q;
                      final matchesRawDate = batch.datePaid.contains(q);
                      final matchesDisplayDate =
                          AppDateUtils.toDisplay(batch.datePaid).toLowerCase().contains(q);
                      final matchesId =
                          batch.id != null && (batch.id.toString() == q || '#${batch.id}' == q);

                      if (!matchesNotes &&
                          !matchesSingleTitle &&
                          !matchesAllTitles &&
                          !matchesCat &&
                          !matchesAllCats &&
                          !matchesAmount &&
                          !matchesRawDate &&
                          !matchesDisplayDate &&
                          !matchesId) {
                        return false;
                      }
                    }

                    return true;
                  }).toList();

                  if (filteredBatches.isEmpty) {
                    return Center(
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
                              'No Matching History Records',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Try adjusting your search query, case filter, or payment date.',
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
                    );
                  }

                  final totalSettledPaise = filteredBatches.fold<int>(
                    0,
                    (sum, b) => sum + b.totalAmountPaise,
                  );

                  return RefreshIndicator(
                    onRefresh: () async => ref.refresh(reimbursementsListProvider),
                    child: ListView.builder(
                      padding: const EdgeInsets.only(top: 4, bottom: 24),
                      itemCount: filteredBatches.length + (hasActiveFilter ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (hasActiveFilter && index == 0) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Showing ${filteredBatches.length} of ${batches.length} voucher(s)',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  CurrencyUtils.format(totalSettledPaise),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        final batchIndex = hasActiveFilter ? index - 1 : index;
                        final batch = filteredBatches[batchIndex];
                        return ReimbursementTile(
                          reimbursement: batch,
                          onTap: () {
                            if (batch.itemCount == 1 && batch.singleExpenseId != null) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ExpenseDetailScreen(
                                    expenseId: batch.singleExpenseId!,
                                  ),
                                ),
                              );
                            } else {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ReimbursementDetailScreen(reimbursement: batch),
                                ),
                              );
                            }
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
