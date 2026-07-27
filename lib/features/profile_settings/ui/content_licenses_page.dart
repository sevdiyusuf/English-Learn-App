import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yunoo/l10n/app_localizations.dart';

import '../../../core/widgets/responsive_content.dart';

typedef ExternalLinkOpener = Future<bool> Function(Uri uri);

class ContentLicensesPage extends StatelessWidget {
  const ContentLicensesPage({super.key, this.openExternalLink});

  final ExternalLinkOpener? openExternalLink;

  static final Uri _materialIconsSource = Uri.parse(
    'https://developers.google.com/fonts/docs/material_icons',
  );
  static final Uri _apacheLicense = Uri.parse(
    'https://www.apache.org/licenses/LICENSE-2.0',
  );

  Future<void> _open(BuildContext context, Uri uri) async {
    if (openExternalLink == null) {
      await showDialog<void>(
        context: context,
        builder:
            (dialogContext) => AlertDialog(
              title: Text(AppLocalizations.of(dialogContext)!.externalLink),
              content: SingleChildScrollView(
                child: SelectableText(uri.toString()),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(AppLocalizations.of(dialogContext)!.closeAction),
                ),
                FilledButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: uri.toString()),
                    );
                    if (!dialogContext.mounted || !context.mounted) return;
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppLocalizations.of(context)!.linkCopied),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy),
                  label: Text(AppLocalizations.of(dialogContext)!.copyLink),
                ),
              ],
            ),
      );
      return;
    }

    var opened = false;
    try {
      opened = await openExternalLink!(uri);
    } catch (_) {
      opened = false;
    }
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.linkUnavailable)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.contentAndLicenses)),
      body: SafeArea(
        top: false,
        child: ResponsiveContent(
          maxWidth: 760,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Semantics(
                header: true,
                child: Text(
                  l10n.contentInformationTitle,
                  style: theme.textTheme.headlineSmall,
                ),
              ),
              const SizedBox(height: 12),
              _InformationCard(
                icon: Icons.auto_stories_outlined,
                title: l10n.projectCreatedContent,
                body: l10n.projectContentDescription,
              ),
              const SizedBox(height: 12),
              _InformationCard(
                icon: Icons.assistant_outlined,
                title: l10n.aiAssistedContent,
                body:
                    '${l10n.aiAssistedContentDescription}\n\n'
                    '${l10n.aiAccuracyDisclaimer}',
              ),
              const SizedBox(height: 24),
              Semantics(
                header: true,
                child: Text(
                  l10n.attributionsTitle,
                  style: theme.textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.materialIconsTitle,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(l10n.materialIconsAttribution),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed:
                                () => _open(context, _materialIconsSource),
                            icon: const Icon(Icons.open_in_new),
                            label: Text(l10n.sourceAction),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _open(context, _apacheLicense),
                            icon: const Icon(Icons.description_outlined),
                            label: Text(l10n.licenseAction),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  minVerticalPadding: 16,
                  leading: const Icon(Icons.code),
                  title: Text(l10n.softwareLicenses),
                  subtitle: Text(l10n.softwareLicensesSubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap:
                      () => showLicensePage(
                        context: context,
                        applicationName: l10n.appTitle,
                        applicationLegalese: l10n.applicationLegalese,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ContentLicensesSettingsTile extends StatelessWidget {
  const ContentLicensesSettingsTile({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      key: const Key('content-licenses-settings-tile'),
      title: Text(l10n.contentAndLicenses),
      subtitle: Text(l10n.contentAndLicensesSubtitle),
      leading: const Icon(Icons.info_outline),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _InformationCard extends StatelessWidget {
  const _InformationCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(child: Icon(icon)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(body),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
