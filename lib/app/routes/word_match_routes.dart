import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/mode_select/ui/mode_select_page.dart';
import '../../features/word_match/ui/edit_word_set_page.dart';
import '../../features/word_match/ui/practice_match_page.dart';
import '../../features/word_match/ui/word_match_home_page.dart';
import '../../features/word_match/ui/word_match_set_detail_page.dart';

List<RouteBase> get wordMatchRoutes => [
  GoRoute(
    path: '/mode-select',
    name: ModeSelectPage.routeName,
    builder: (context, state) => const ModeSelectPage(),
  ),
  GoRoute(
    path: '/word-match/sets',
    name: WordMatchHomePage.routeName,
    builder: (context, state) => const WordMatchHomePage(),
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
      return PracticeMatchPage(setId: setId);
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
];

class _RouteErrorPage extends StatelessWidget {
  const _RouteErrorPage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text(message)));
  }
}
