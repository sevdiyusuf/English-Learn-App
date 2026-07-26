import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../auth/logic/auth_controller.dart';
import 'moderation_client.dart';

class UgcPolicyDocumentPage extends StatelessWidget {
  const UgcPolicyDocumentPage({super.key, required this.guidelines});

  final bool guidelines;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          guidelines ? l10n.communityGuidelines : l10n.termsOfService,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            Text(guidelines ? l10n.guidelinesBody : l10n.termsBody),
            const SizedBox(height: 24),
            Text(
              l10n.termsDraftNotice,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool> ensureCurrentUgcAcceptance(
  BuildContext context,
  WidgetRef ref,
) async {
  final user = ref.read(authControllerProvider).value;
  if (user == null) return false;

  final client = ref.read(moderationClientProvider)..setUid(user.uid);
  if (await client.hasCurrentAcceptance(user.uid)) return true;
  if (!context.mounted) return false;

  return (await showDialog<bool>(
        context: context,
        builder: (_) => _AcceptanceDialog(client: client),
      )) ??
      false;
}

class _AcceptanceDialog extends StatefulWidget {
  const _AcceptanceDialog({required this.client});

  final ModerationClient client;

  @override
  State<_AcceptanceDialog> createState() => _AcceptanceDialogState();
}

class _AcceptanceDialogState extends State<_AcceptanceDialog> {
  bool _accepted = false;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.acceptCurrentPolicies),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.acceptPoliciesPrompt),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const UgcPolicyDocumentPage(guidelines: false),
                ),
              ),
              child: Text(l10n.termsOfService),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const UgcPolicyDocumentPage(guidelines: true),
                ),
              ),
              child: Text(l10n.communityGuidelines),
            ),
            CheckboxListTile(
              value: _accepted,
              onChanged: _saving
                  ? null
                  : (value) => setState(() => _accepted = value ?? false),
              title: Text(l10n.acceptPoliciesCheck),
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: !_accepted || _saving ? null : _accept,
          child: Text(_saving ? l10n.loading : l10n.accept),
        ),
      ],
    );
  }

  Future<void> _accept() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _saving = true);
    try {
      await widget.client.acceptPolicies();
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.policyAcceptanceFailed)),
      );
    }
  }
}
