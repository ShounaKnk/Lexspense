import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/client_matter.dart';
import 'database_provider.dart';

/// Active matters for expense creation pickers.
final activeMattersProvider = FutureProvider<List<ClientMatter>>((ref) {
  return ref.watch(matterRepositoryProvider).getActive();
});

/// All matters (active + archived) for the matters management screen.
final allMattersProvider = FutureProvider<List<ClientMatter>>((ref) {
  return ref.watch(matterRepositoryProvider).getAll();
});
