import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/court_forum.dart';
import 'database_provider.dart';

/// Active forums for pickers / dropdowns.
final activeForumsProvider = FutureProvider<List<CourtForum>>((ref) {
  return ref.watch(courtForumRepositoryProvider).getActive();
});

/// All forums (active + archived) for the management screen.
final allForumsProvider = FutureProvider<List<CourtForum>>((ref) {
  return ref.watch(courtForumRepositoryProvider).getAll();
});
