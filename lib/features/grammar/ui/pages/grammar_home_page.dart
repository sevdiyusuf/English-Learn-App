import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:go_router/go_router.dart';
// import '../../logic/grammar_providers.dart';
import '../../../training/ui/training_home_page.dart';
// import '../../../../core/theme/app_colors.dart';
// import '../../../training/models/training_models.dart';
// import '../../../training/logic/training_controller.dart';
// import '../../../training/data/subject_summaries_data.dart';
// import '../../../training/ui/worksheet_page.dart';

class GrammarHomePage extends ConsumerWidget {
  static const routeName = 'grammar_home';

  const GrammarHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We reuse TrainingHomePage but we will intercept the onTap of worksheet cards
    // To do this, we need to modify TrainingHomePage or use it as is and
    // provide the selection logic.
    // Since TrainingHomePage is already built to show the Train UI,
    // we'll return it directly to restore the "old" look.
    return const TrainingHomePage(showAppBar: true);
  }
}
