import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/irregular_verb.dart';

final irregularVerbsProvider = FutureProvider<List<IrregularVerb>>((ref) async {
  try {
    final jsonString = await rootBundle.loadString(
      'assets/ırregular_verbs.json',
    );
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((e) => IrregularVerb.fromJson(e)).toList();
  } catch (e) {
    // Fallback if asset not found or corrupted during dev
    return [];
  }
});

class PracticeState {
  final List<IrregularVerb> remainingVerbs;
  final IrregularVerb? currentVerb;
  final List<String> currentDistractors;
  final bool isV2Correct;
  final bool isV3Correct;
  final String? selectedV2;
  final String? selectedV3;
  final int score;
  final int total;
  final bool showCorrectGlow;
  final List<String> wrongOptions; // To track red chips

  PracticeState({
    required this.remainingVerbs,
    this.currentVerb,
    this.currentDistractors = const [],
    this.isV2Correct = false,
    this.isV3Correct = false,
    this.selectedV2,
    this.selectedV3,
    this.score = 0,
    this.total = 0,
    this.showCorrectGlow = false,
    this.wrongOptions = const [],
  });

  PracticeState copyWith({
    List<IrregularVerb>? remainingVerbs,
    IrregularVerb? currentVerb,
    List<String>? currentDistractors,
    bool? isV2Correct,
    bool? isV3Correct,
    String? selectedV2,
    String? selectedV3,
    int? score,
    int? total,
    bool? showCorrectGlow,
    List<String>? wrongOptions,
  }) {
    return PracticeState(
      remainingVerbs: remainingVerbs ?? this.remainingVerbs,
      currentVerb: currentVerb ?? this.currentVerb,
      currentDistractors: currentDistractors ?? this.currentDistractors,
      isV2Correct: isV2Correct ?? this.isV2Correct,
      isV3Correct: isV3Correct ?? this.isV3Correct,
      selectedV2: selectedV2 ?? this.selectedV2,
      selectedV3: selectedV3 ?? this.selectedV3,
      score: score ?? this.score,
      total: total ?? this.total,
      showCorrectGlow: showCorrectGlow ?? this.showCorrectGlow,
      wrongOptions: wrongOptions ?? this.wrongOptions,
    );
  }
}

class PracticeNotifier extends StateNotifier<PracticeState> {
  final List<IrregularVerb> allVerbs;

  PracticeNotifier(this.allVerbs)
    : super(PracticeState(remainingVerbs: List.from(allVerbs)..shuffle())) {
    _nextVerb();
  }

  void _nextVerb() {
    if (state.remainingVerbs.isEmpty) {
      // Finished
      return;
    }

    final next = state.remainingVerbs.first;
    final remaining = state.remainingVerbs.sublist(1);

    // Generate distractors for the whole verb (V2 and V3)
    final distractors = _generateDistractors(next);

    state = state.copyWith(
      currentVerb: next,
      remainingVerbs: remaining,
      currentDistractors: distractors,
      isV2Correct: false,
      isV3Correct: false,
      selectedV2: null,
      selectedV3: null,
      showCorrectGlow: false,
      wrongOptions: [],
    );
  }

  List<String> _generateDistractors(IrregularVerb correct) {
    // Helper to get similar ones
    List<String> getSimilar(String val, String form) {
      final List<String> candidates = [];
      final suffix =
          val.length > 3
              ? val.substring(val.length - 3)
              : (val.length > 2 ? val.substring(val.length - 2) : val);

      for (var verb in allVerbs) {
        final v = form == 'v2' ? verb.v2 : verb.v3;
        if (v == val) continue;
        if (v.endsWith(suffix)) candidates.add(v);
      }

      if (candidates.length < 3) {
        for (var verb in allVerbs) {
          final v = form == 'v2' ? verb.v2 : verb.v3;
          if (v == val || candidates.contains(v)) continue;
          if ((v.length - val.length).abs() <= 2) candidates.add(v);
        }
      }
      candidates.shuffle();
      return candidates.take(3).toList();
    }

    final v2Similar = getSimilar(correct.v2, 'v2');
    final v3Similar = getSimilar(correct.v3, 'v3');

    final Set<String> combined = {correct.v2, correct.v3};
    final allSimilars = [...v2Similar, ...v3Similar]..shuffle();

    for (var s in allSimilars) {
      if (combined.length >= 6) break;
      combined.add(s);
    }

    // Still not enough? Fill with randoms
    if (combined.length < 6) {
      final randomVerbs = List.from(allVerbs)..shuffle();
      for (var v in randomVerbs) {
        if (combined.length >= 6) break;
        combined.add(v.v2);
        if (combined.length >= 6) break;
        combined.add(v.v3);
      }
    }

    return combined.toList()..shuffle();
  }

  void selectOption(String option) {
    final current = state.currentVerb;
    if (current == null) return;

    if (!state.isV2Correct) {
      if (current.v2 == option) {
        state = state.copyWith(
          isV2Correct: true,
          selectedV2: option,
          wrongOptions: [],
        );
        _checkComplete();
      } else {
        // Wrong
        if (!state.wrongOptions.contains(option)) {
          state = state.copyWith(wrongOptions: [...state.wrongOptions, option]);
          // Add to end of list for spaced repetition
          _addToEnd(current);
        }
      }
    } else if (!state.isV3Correct) {
      if (current.v3 == option) {
        state = state.copyWith(
          isV3Correct: true,
          selectedV3: option,
          wrongOptions: [],
        );
        _checkComplete();
      } else {
        // Wrong
        if (!state.wrongOptions.contains(option)) {
          state = state.copyWith(wrongOptions: [...state.wrongOptions, option]);
          _addToEnd(current);
        }
      }
    }
  }

  void _addToEnd(IrregularVerb verb) {
    if (!state.remainingVerbs.contains(verb)) {
      state = state.copyWith(remainingVerbs: [...state.remainingVerbs, verb]);
    }
  }

  void _checkComplete() {
    if (state.isV2Correct && state.isV3Correct) {
      state = state.copyWith(
        showCorrectGlow: true,
        score: state.score + 1,
        total: state.total + 1,
      );
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) _nextVerb();
      });
    }
  }
}

final practiceProvider =
    StateNotifierProvider.autoDispose<PracticeNotifier, PracticeState>((ref) {
      final verbs = ref.watch(irregularVerbsProvider).valueOrNull ?? [];
      return PracticeNotifier(verbs);
    });
