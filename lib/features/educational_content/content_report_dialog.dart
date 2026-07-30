/// Sprint 10C — Educational Content Report Dialog
///
/// A self-contained bottom-sheet that collects:
///   • error category (required, single-select)
///   • optional free-text comment (≤ 500 chars)
///
/// The dialog is always non-blocking: dismissing without submitting, or a
/// submission failure, never affects the parent learning flow.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import 'content_report_service.dart';

/// Shows the content-report bottom sheet.
///
/// Returns `true` if the report was submitted successfully, `false`/`null`
/// otherwise.  The caller may choose to show a snackbar but MUST NOT block
/// the learning flow.
Future<bool?> showContentReportSheet(
  BuildContext context, {
  required String contentId,
  required int contentVersion,
  required String contentType,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder:
        (_) => _ContentReportSheet(
          contentId: contentId,
          contentVersion: contentVersion,
          contentType: contentType,
        ),
  );
}

class _ContentReportSheet extends ConsumerStatefulWidget {
  const _ContentReportSheet({
    required this.contentId,
    required this.contentVersion,
    required this.contentType,
  });

  final String contentId;
  final int contentVersion;
  final String contentType;

  @override
  ConsumerState<_ContentReportSheet> createState() =>
      _ContentReportSheetState();
}

class _ContentReportSheetState extends ConsumerState<_ContentReportSheet> {
  ContentReportCategory? _category;
  final _commentController = TextEditingController();
  bool _submitting = false;
  String? _categoryError;
  String? _commentError;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  String _categoryLabel(AppLocalizations l10n, ContentReportCategory cat) {
    switch (cat) {
      case ContentReportCategory.typo:
        return l10n.reportCategoryTypo;
      case ContentReportCategory.incorrectAnswer:
        return l10n.reportCategoryIncorrectAnswer;
      case ContentReportCategory.unclearExplanation:
        return l10n.reportCategoryUnclearExplanation;
      case ContentReportCategory.audioIssue:
        return l10n.reportCategoryAudioIssue;
      case ContentReportCategory.wrongLevelOrCategory:
        return l10n.reportCategoryWrongLevelOrCategory;
      case ContentReportCategory.other:
        return l10n.reportCategoryOther;
    }
  }

  Future<void> _submit(AppLocalizations l10n) async {
    // Validate
    if (_category == null) {
      setState(() => _categoryError = l10n.reportCategoryRequired);
      return;
    }
    final comment = _commentController.text;
    if (comment.trim().length > 500) {
      setState(() => _commentError = l10n.reportCommentTooLong);
      return;
    }

    setState(() {
      _submitting = true;
      _categoryError = null;
      _commentError = null;
    });

    final service = ref.read(contentReportServiceProvider);
    final result = await service.submit(
      contentId: widget.contentId,
      contentVersion: widget.contentVersion,
      contentType: widget.contentType,
      category: _category!,
      comment: comment,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    switch (result) {
      case ContentReportResult.success:
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.reportContentSuccess)));
      case ContentReportResult.alreadyReported:
        Navigator.of(context).pop(false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.reportContentAlreadyReported)),
        );
      case ContentReportResult.unauthenticated:
        Navigator.of(context).pop(false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.reportContentSignInRequired)),
        );
      case ContentReportResult.failure:
        Navigator.of(context).pop(false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.reportContentFailure)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              l10n.reportContentTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Description
            Text(
              l10n.reportContentDescription,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),

            // Category chips
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children:
                  ContentReportCategory.values.map((cat) {
                    final selected = _category == cat;
                    return ChoiceChip(
                      key: ValueKey('report_category_${cat.value}'),
                      label: Text(_categoryLabel(l10n, cat)),
                      selected: selected,
                      onSelected:
                          _submitting
                              ? null
                              : (_) => setState(() {
                                _category = cat;
                                _categoryError = null;
                              }),
                    );
                  }).toList(),
            ),
            if (_categoryError != null) ...[
              const SizedBox(height: 4),
              Text(
                _categoryError!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Optional comment
            Text(
              l10n.reportOptionalComment,
              style: theme.textTheme.labelMedium,
            ),
            const SizedBox(height: 6),
            TextField(
              key: const ValueKey('report_comment_field'),
              controller: _commentController,
              enabled: !_submitting,
              maxLines: 3,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: l10n.reportCommentHint,
                errorText: _commentError,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) {
                if (_commentError != null) setState(() => _commentError = null);
              },
            ),
            const SizedBox(height: 20),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const ValueKey('report_cancel_button'),
                    onPressed:
                        _submitting
                            ? null
                            : () => Navigator.of(context).pop(false),
                    child: Text(l10n.reportContentCancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    key: const ValueKey('report_submit_button'),
                    onPressed: _submitting ? null : () => _submit(l10n),
                    child:
                        _submitting
                            ? SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.onPrimary,
                              ),
                            )
                            : Text(l10n.reportContentSubmit),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
