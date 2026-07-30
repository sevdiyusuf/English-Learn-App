import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yunoo/core/telemetry/telemetry_events.dart';
import 'package:yunoo/core/telemetry/telemetry_service.dart';
import '../../l10n/app_localizations.dart';
import 'moderation_client.dart';

const _reportReasons = <String>[
  'spam',
  'harassment_or_bullying',
  'hateful_or_abusive',
  'inappropriate_content',
  'impersonation',
  'privacy_violation',
  'other',
];

Future<void> showReportDialog(
  BuildContext context,
  WidgetRef ref, {
  required String type,
  required String targetId,
  required String title,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _ReportDialog(type: type, targetId: targetId, title: title),
  );
}

Future<void> showReportAndBlockDialog(
  BuildContext context,
  WidgetRef ref,
  String targetUid,
) {
  final l10n = AppLocalizations.of(context)!;
  return showDialog<void>(
    context: context,
    builder:
        (_) => _ReportDialog(
          type: 'user',
          targetId: targetUid,
          title: l10n.reportAndBlock,
          alsoBlock: true,
        ),
  );
}

class _ReportDialog extends ConsumerStatefulWidget {
  const _ReportDialog({
    required this.type,
    required this.targetId,
    required this.title,
    this.alsoBlock = false,
  });

  final String type;
  final String targetId;
  final String title;
  final bool alsoBlock;

  @override
  ConsumerState<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends ConsumerState<_ReportDialog> {
  final _detailsController = TextEditingController();
  String? _reason;
  bool _submitting = false;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _reason,
            decoration: InputDecoration(labelText: l10n.reportReason),
            items:
                _reportReasons
                    .map(
                      (reason) => DropdownMenuItem<String>(
                        value: reason,
                        child: Text(reason.replaceAll('_', ' ')),
                      ),
                    )
                    .toList(),
            onChanged:
                _submitting ? null : (value) => setState(() => _reason = value),
          ),
          TextField(
            controller: _detailsController,
            maxLength: 500,
            maxLines: 3,
            enabled: !_submitting,
            decoration: InputDecoration(labelText: l10n.reportDetails),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _reason == null || _submitting ? null : _submit,
          child: Text(_submitting ? l10n.loading : l10n.submitReport),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final reason = _reason;
    if (reason == null) return;
    setState(() => _submitting = true);
    try {
      final client = ref.read(moderationClientProvider);
      await client.report(
        type: widget.type,
        targetId: widget.targetId,
        reason: reason,
        details: _detailsController.text.trim(),
      );
      if (widget.alsoBlock) await client.block(widget.targetId);

      await TelemetryService.instance.logAnalyticsEvent(
        TelemetryEvents.contentReportSubmitted,
        parameters: {
          TelemetryParams.contentType: widget.type,
          TelemetryParams.reason: reason,
        },
      );

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.reportReceived)));
    } catch (error) {
      TelemetryService.instance.recordNonFatalError(
        error,
        reason: 'report_submission_failed',
        attributes: {
          TelemetryParams.feature: 'moderation',
          TelemetryParams.contentType: widget.type,
          TelemetryParams.reason: reason,
        },
      );

      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_localizedError(l10n, error))));
    }
  }
}

Future<void> showBlockDialog(
  BuildContext context,
  WidgetRef ref,
  String targetUid,
) async {
  final l10n = AppLocalizations.of(context)!;
  final accepted = await showDialog<bool>(
    context: context,
    builder:
        (_) => AlertDialog(
          content: Text(l10n.blockUserPrompt),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.block),
            ),
          ],
        ),
  );
  if (accepted != true || !context.mounted) return;

  try {
    await ref.read(moderationClientProvider).block(targetUid);
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.block)));
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(_localizedError(l10n, error))));
  }
}

String _localizedError(AppLocalizations l10n, Object error) {
  return switch (moderationErrorKey(error)) {
    'rateLimited' => l10n.rateLimited,
    'interactionUnavailable' => l10n.interactionUnavailable,
    _ => l10n.errorGeneric,
  };
}
