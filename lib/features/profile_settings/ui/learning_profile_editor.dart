import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yunoo/l10n/app_localizations.dart';

import '../logic/user_settings_controller.dart';
import '../models/learning_profile_presentation.dart';
import '../models/user_settings.dart';

Future<void> showLearningProfileEditor({
  required BuildContext context,
  required WidgetRef ref,
  required UserSettings settings,
}) {
  return showDialog<void>(
    context: context,
    builder:
        (_) => LearningProfileEditorDialog(
          initialSettings: settings,
          onSave: ({required String cefrLevel, required String learningGoal}) {
            return ref
                .read(userSettingsControllerProvider.notifier)
                .updateLearningProfile(
                  cefrLevel: cefrLevel,
                  learningGoal: learningGoal,
                  onboardingStep: settings.onboardingStep,
                  onboardingCompletedVersion:
                      settings.onboardingCompletedVersion,
                );
          },
        ),
  );
}

class LearningProfileEditorDialog extends StatefulWidget {
  const LearningProfileEditorDialog({
    super.key,
    required this.initialSettings,
    required this.onSave,
  });

  final UserSettings initialSettings;
  final Future<void> Function({
    required String cefrLevel,
    required String learningGoal,
  })
  onSave;

  @override
  State<LearningProfileEditorDialog> createState() =>
      _LearningProfileEditorDialogState();
}

class _LearningProfileEditorDialogState
    extends State<LearningProfileEditorDialog> {
  String? _level;
  String? _goal;
  bool _saving = false;
  bool _saveFailed = false;
  bool _validationFailed = false;

  @override
  void initState() {
    super.initState();
    _level = widget.initialSettings.cefrLevel;
    _goal = widget.initialSettings.learningGoal;
  }

  Future<void> _save() async {
    if (_level == null || _goal == null) {
      setState(() => _validationFailed = true);
      return;
    }

    setState(() {
      _saving = true;
      _saveFailed = false;
      _validationFailed = false;
    });
    try {
      await widget.onSave(cefrLevel: _level!, learningGoal: _goal!);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) setState(() => _saveFailed = true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: Semantics(header: true, child: Text(l10n.learningProfile)),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _level,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l10n.onboardingLevelTitle,
                ),
                items:
                    supportedCefrLevels
                        .map(
                          (value) => DropdownMenuItem<String>(
                            value: value,
                            child: Text(l10n.cefrLabel(value)),
                          ),
                        )
                        .toList(),
                onChanged:
                    _saving
                        ? null
                        : (value) => setState(() {
                          _level = value;
                          _validationFailed = false;
                        }),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: _goal,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l10n.onboardingGoalTitle,
                ),
                items:
                    supportedLearningGoals
                        .map(
                          (value) => DropdownMenuItem<String>(
                            value: value,
                            child: Text(l10n.learningGoalLabel(value)),
                          ),
                        )
                        .toList(),
                onChanged:
                    _saving
                        ? null
                        : (value) => setState(() {
                          _goal = value;
                          _validationFailed = false;
                        }),
              ),
              if (_validationFailed) ...[
                const SizedBox(height: 16),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    l10n.onboardingSelectionRequired,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
              if (_saveFailed) ...[
                const SizedBox(height: 16),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    l10n.saveFailedRetry,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actionsOverflowAlignment: OverflowBarAlignment.end,
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child:
              _saving
                  ? Semantics(
                    label: l10n.loading,
                    child: const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                  : Text(l10n.save),
        ),
      ],
    );
  }
}
