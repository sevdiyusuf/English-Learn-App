import 'package:yunoo/l10n/app_localizations.dart';

import 'user_settings.dart';

extension LearningProfilePresentation on AppLocalizations {
  String cefrLabel(String value) => switch (value) {
    'A1' => cefrA1,
    'A2' => cefrA2,
    'B1' => cefrB1,
    'B2' => cefrB2,
    'C1' => cefrC1,
    'C2' => cefrC2,
    _ => value,
  };

  String learningGoalLabel(String value) => switch (value) {
    'word_practice' => learningGoalWords,
    'grammar_practice' => learningGoalGrammar,
    'mini_games' => learningGoalGames,
    'multiplayer' => learningGoalMultiplayer,
    _ => value,
  };
}

List<String> get supportedCefrLevels =>
    LearningProfileValues.cefrLevels.toList(growable: false);

List<String> get supportedLearningGoals =>
    LearningProfileValues.learningGoals.toList(growable: false);
