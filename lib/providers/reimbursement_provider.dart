import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/reimbursement.dart';
import 'database_provider.dart';

/// All reimbursement batches, sorted newest first.
final reimbursementsListProvider = FutureProvider<List<Reimbursement>>((ref) {
  return ref.watch(reimbursementRepositoryProvider).getAllReimbursements();
});

/// Single reimbursement batch by ID.
final reimbursementDetailProvider =
    FutureProvider.family<Reimbursement?, int>((ref, id) {
  return ref.watch(reimbursementRepositoryProvider).getReimbursementById(id);
});
