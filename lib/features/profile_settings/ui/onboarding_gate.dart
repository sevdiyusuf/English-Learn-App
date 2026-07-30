import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yunoo/l10n/app_localizations.dart';

import 'package:yunoo/core/telemetry/telemetry_events.dart';
import 'package:yunoo/core/telemetry/telemetry_service.dart';
import '../../../core/widgets/responsive_content.dart';
import '../logic/user_settings_controller.dart';
import '../models/user_settings.dart';
import '../models/learning_profile_presentation.dart';

bool requiresCurrentOnboarding(UserSettings settings) =>
    settings.onboardingCompletedVersion <
    LearningProfileValues.currentOnboardingVersion;

typedef LearningProfileUpdater =
    Future<void> Function({
      required String? cefrLevel,
      required String? learningGoal,
      required String onboardingStep,
      required int onboardingCompletedVersion,
    });

class OnboardingGate extends ConsumerWidget {
  const OnboardingGate({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(userSettingsControllerProvider);
    return settings.when(
      data:
          (value) =>
              requiresCurrentOnboarding(value) ? const OnboardingPage() : child,
      loading:
          () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => const OnboardingPage(),
    );
  }
}

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({
    this.initialSettings,
    this.updateLearningProfile,
    super.key,
  });

  final UserSettings? initialSettings;
  final LearningProfileUpdater? updateLearningProfile;

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  late String _step;
  String? _level;
  String? _goal;
  bool _saving = false;
  bool _loaded = false;
  bool _saveFailed = false;
  bool _validationFailed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    final settings =
        widget.initialSettings ??
        ref.read(userSettingsControllerProvider).valueOrNull;
    _level = settings?.cefrLevel;
    _goal = settings?.learningGoal;
    _step = _safeResumeStep(
      settings?.onboardingStep ?? LearningProfileValues.onboardingIntro,
    );
    _loaded = true;
  }

  String _safeResumeStep(String persistedStep) {
    if (persistedStep == LearningProfileValues.onboardingReview) {
      if (_level == null) return LearningProfileValues.onboardingLevel;
      if (_goal == null) return LearningProfileValues.onboardingGoal;
    }
    if (persistedStep == LearningProfileValues.onboardingGoal &&
        _level == null) {
      return LearningProfileValues.onboardingLevel;
    }
    return LearningProfileValues.isValidStep(persistedStep)
        ? persistedStep
        : LearningProfileValues.onboardingIntro;
  }

  Future<void> _next() async {
    if (_step == LearningProfileValues.onboardingIntro) {
      await _persistProgress(LearningProfileValues.onboardingLevel);
      return;
    }
    if (_step == LearningProfileValues.onboardingLevel && _level == null) {
      setState(() => _validationFailed = true);
      return;
    }
    if (_step == LearningProfileValues.onboardingLevel) {
      await _persistProgress(LearningProfileValues.onboardingGoal);
      return;
    }
    if (_step == LearningProfileValues.onboardingGoal && _goal == null) {
      setState(() => _validationFailed = true);
      return;
    }
    if (_step == LearningProfileValues.onboardingGoal) {
      await _persistProgress(LearningProfileValues.onboardingReview);
      return;
    }
    if (_level == null || _goal == null) {
      setState(() => _validationFailed = true);
      return;
    }
    setState(() => _saving = true);
    try {
      await _updateLearningProfile(
        cefrLevel: _level,
        learningGoal: _goal,
        onboardingStep: LearningProfileValues.onboardingReview,
        onboardingCompletedVersion:
            LearningProfileValues.currentOnboardingVersion,
      );
      await TelemetryService.instance.logAnalyticsEvent(
        TelemetryEvents.onboardingCompleted,
        parameters: {
          TelemetryParams.level: _level,
          TelemetryParams.goal: _goal,
        },
      );
    } catch (_) {
      if (mounted) setState(() => _saveFailed = true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _persistProgress(String nextStep) async {
    setState(() => _saving = true);
    try {
      await _updateLearningProfile(
        cefrLevel: _level,
        learningGoal: _goal,
        onboardingStep: nextStep,
        onboardingCompletedVersion: 0,
      );
      if (!mounted) return;
      setState(() {
        _saveFailed = false;
        _validationFailed = false;
        _step = nextStep;
      });
    } catch (_) {
      if (mounted) setState(() => _saveFailed = true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _updateLearningProfile({
    required String? cefrLevel,
    required String? learningGoal,
    required String onboardingStep,
    required int onboardingCompletedVersion,
  }) {
    final callback = widget.updateLearningProfile;
    if (callback != null) {
      return callback(
        cefrLevel: cefrLevel,
        learningGoal: learningGoal,
        onboardingStep: onboardingStep,
        onboardingCompletedVersion: onboardingCompletedVersion,
      );
    }
    return ref
        .read(userSettingsControllerProvider.notifier)
        .updateLearningProfile(
          cefrLevel: cefrLevel,
          learningGoal: learningGoal,
          onboardingStep: onboardingStep,
          onboardingCompletedVersion: onboardingCompletedVersion,
        );
  }

  void _back() {
    setState(() {
      _saveFailed = false;
      _validationFailed = false;
      _step = switch (_step) {
        LearningProfileValues.onboardingReview =>
          LearningProfileValues.onboardingGoal,
        LearningProfileValues.onboardingGoal =>
          LearningProfileValues.onboardingLevel,
        LearningProfileValues.onboardingLevel =>
          LearningProfileValues.onboardingIntro,
        _ => LearningProfileValues.onboardingIntro,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = switch (_step) {
      LearningProfileValues.onboardingIntro => l10n.onboardingIntroTitle,
      LearningProfileValues.onboardingLevel => l10n.onboardingLevelTitle,
      LearningProfileValues.onboardingGoal => l10n.onboardingGoalTitle,
      _ => l10n.onboardingReviewTitle,
    };
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _step != LearningProfileValues.onboardingIntro) _back();
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading:
              _step == LearningProfileValues.onboardingIntro
                  ? null
                  : IconButton(
                    onPressed: _saving ? null : _back,
                    tooltip: l10n.backAction,
                    icon: const Icon(Icons.arrow_back),
                  ),
        ),
        body: SafeArea(
          child: ResponsiveContent(
            maxWidth: 720,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.only(top: 16, bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(l10n.onboardingProgress(_stepIndex(_step) + 1, 4)),
                        const SizedBox(height: 12),
                        Text(l10n.onboardingDescription),
                        const SizedBox(height: 24),
                        if (_step == LearningProfileValues.onboardingLevel)
                          RadioGroup<String>(
                            groupValue: _level,
                            onChanged:
                                (value) => setState(() {
                                  _level = value;
                                  _validationFailed = false;
                                }),
                            child: Column(
                              children:
                                  supportedCefrLevels
                                      .map(
                                        (value) => RadioListTile<String>(
                                          value: value,
                                          title: Text(l10n.cefrLabel(value)),
                                        ),
                                      )
                                      .toList(),
                            ),
                          ),
                        if (_step == LearningProfileValues.onboardingGoal)
                          RadioGroup<String>(
                            groupValue: _goal,
                            onChanged:
                                (value) => setState(() {
                                  _goal = value;
                                  _validationFailed = false;
                                }),
                            child: Column(
                              children:
                                  supportedLearningGoals
                                      .map(
                                        (value) => RadioListTile<String>(
                                          value: value,
                                          title: Text(
                                            l10n.learningGoalLabel(value),
                                          ),
                                        ),
                                      )
                                      .toList(),
                            ),
                          ),
                        if (_step == LearningProfileValues.onboardingReview)
                          Text(
                            l10n.onboardingReviewValue(
                              _level == null ? '' : l10n.cefrLabel(_level!),
                              _goal == null
                                  ? ''
                                  : l10n.learningGoalLabel(_goal!),
                            ),
                          ),
                        if (_validationFailed)
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              l10n.onboardingSelectionRequired,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        if (_saveFailed)
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              l10n.onboardingSaveFailed,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: FilledButton(
                    onPressed: _saving ? null : _next,
                    child:
                        _saving
                            ? Semantics(
                              label: l10n.loading,
                              child: const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                            : Text(
                              _step == LearningProfileValues.onboardingReview
                                  ? l10n.onboardingComplete
                                  : l10n.onboardingNext,
                            ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _stepIndex(String step) {
    return switch (step) {
      LearningProfileValues.onboardingLevel => 1,
      LearningProfileValues.onboardingGoal => 2,
      LearningProfileValues.onboardingReview => 3,
      _ => 0,
    };
  }
}
