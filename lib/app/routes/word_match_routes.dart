import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/mode_select/ui/mode_select_page.dart';
import '../../features/word_match/ui/edit_word_set_page.dart';
import '../../features/word_match/ui/practice_match_page.dart';
import '../../features/word_match/ui/word_match_home_page.dart';
import '../../features/word_match/ui/word_match_set_detail_page.dart';
import '../../features/word_match/ui/prebuilt_sets_page.dart';
import '../../features/word_match/ui/shared_word_set_page.dart';
import '../../features/word_match/ui/word_test_page.dart';

List<RouteBase> get wordMatchRoutes => [
  GoRoute(
    path: '/',
    name: ModeSelectPage.routeName,
    builder: (context, state) => const ModeSelectPage(),
  ),
  GoRoute(path: '/mode-select', redirect: (_, __) => '/'),
  GoRoute(
    path: '/word-match/sets',
    name: WordMatchHomePage.routeName,
    builder: (context, state) => const WordMatchHomePage(),
  ),
  GoRoute(
    path: '/word-match/prebuilt',
    name: PreBuiltSetsPage.routeName,
    builder: (context, state) => const PreBuiltSetsPage(),
  ),
  GoRoute(
    path: '/word-match/test/:setId',
    name: WordTestPage.routeName,
    builder: (context, state) {
      final param = state.pathParameters['setId'];
      final setId = int.tryParse(param ?? '');
      if (setId == null) {
        return const _RouteErrorPage(message: 'Geçersiz set id');
      }
      return WordTestPage(setId: setId);
    },
  ),
  GoRoute(
    path: '/word-match/edit/:setId',
    name: EditWordSetPage.routeName,
    builder: (context, state) {
      final param = state.pathParameters['setId'];
      final setId = int.tryParse(param ?? '');
      if (setId == null) {
        return const _RouteErrorPage(message: 'Geçersiz set id');
      }
      return EditWordSetPage(setId: setId);
    },
  ),
  GoRoute(
    path: '/word-match/practice/:setId',
    name: PracticeMatchPage.routeName,
    builder: (context, state) {
      final param = state.pathParameters['setId'];
      final setId = int.tryParse(param ?? '');
      if (setId == null) {
        return const _RouteErrorPage(message: 'Geçersiz set id');
      }
      final mode = state.uri.queryParameters['mode'];
      final usePassiveOnly = mode == 'active' ? false : true;
      return PracticeMatchPage(setId: setId, usePassiveOnly: usePassiveOnly);
    },
  ),
  GoRoute(
    path: '/word-match/detail/:setId',
    name: WordMatchSetDetailPage.routeName,
    builder: (context, state) {
      final param = state.pathParameters['setId'];
      final setId = int.tryParse(param ?? '');
      if (setId == null) {
        return const _RouteErrorPage(message: 'Geçersiz set id');
      }
      return WordMatchSetDetailPage(setId: setId);
    },
  ),
  // Shared set preview inside app
  GoRoute(
    path: '/word-match/share/:shareId',
    name: SharedWordSetPage.routeName,
    builder: (context, state) {
      final shareId = state.pathParameters['shareId'] ?? '';
      if (shareId.isEmpty) {
        return const _RouteErrorPage(message: 'Geçersiz paylaşım kodu');
      }
      return SharedWordSetPage(shareId: shareId);
    },
  ),
];

class _RouteErrorPage extends StatelessWidget {
  const _RouteErrorPage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text(message)));
  }
}
