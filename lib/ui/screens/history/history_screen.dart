import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/reimbursement_provider.dart';
import '../../widgets/dot_matrix_background.dart';
import '../expense_detail/expense_detail_screen.dart';
import 'reimbursement_detail_screen.dart';
import 'widgets/reimbursement_tile.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reimbursementsAsync = ref.watch(reimbursementsListProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reimbursement History'),
      ),
      body: DotMatrixBackground(
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

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(reimbursementsListProvider),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: batches.length,
              itemBuilder: (context, index) {
                final batch = batches[index];
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
  );
}
}
