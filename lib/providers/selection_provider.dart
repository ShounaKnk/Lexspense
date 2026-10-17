import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks selected expense IDs on the dashboard for batch reimbursement.
class SelectionNotifier extends StateNotifier<Set<int>> {
  SelectionNotifier() : super({});

  void toggle(int expenseId) {
    if (state.contains(expenseId)) {
      state = {...state}..remove(expenseId);
    } else {
      state = {...state, expenseId};
    }
  }

  void selectAll(Iterable<int> expenseIds) {
    state = expenseIds.toSet();
  }

  void clear() {
    state = {};
  }

  bool isSelected(int expenseId) => state.contains(expenseId);
}

final selectedExpensesProvider =
    StateNotifierProvider<SelectionNotifier, Set<int>>((ref) {
  return SelectionNotifier();
});
