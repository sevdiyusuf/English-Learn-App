import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_repo.dart';
import '../models/word_set.dart';
import 'word_match_repo_interface.dart';
import 'word_match_repo_web.dart';

final appIsarProvider = FutureProvider<dynamic>((ref) async => null);

final wordMatchRepoProvider = FutureProvider<WordMatchRepoInterface>((
  ref,
) async {
  final authUser = ref.watch(authRepositoryProvider).currentUser;
  final String? activeOwnerUid =
      (authUser != null && !authUser.isAnonymous) ? authUser.uid : null;
  return WordMatchRepoWeb(activeOwnerUid: activeOwnerUid);
});

final preBuiltSetsProvider = StreamProvider<List<WordSet>>((ref) async* {
  final repo = await ref.watch(wordMatchRepoProvider.future);
  await repo.ensureLevelSets();
  yield* repo.watchLevelSets();
});
