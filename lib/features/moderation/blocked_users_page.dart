import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/error_view.dart';
import '../../core/widgets/responsive_content.dart';
import '../../l10n/app_localizations.dart';
import '../auth/logic/auth_controller.dart';
import 'moderation_client.dart';

class BlockedUsersPage extends ConsumerWidget {
  const BlockedUsersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(authControllerProvider).valueOrNull;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.blockedUsers)),
        body: ErrorView(message: l10n.interactionUnavailable),
      );
    }

    final client = ref.watch(moderationClientProvider)..setUid(user.uid);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.blockedUsers)),
      body: ResponsiveContent(
        maxWidth: 720,
        child: StreamBuilder<List<String>>(
          stream: client.watchBlocked(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return ErrorView(message: l10n.errorGeneric);
            }
            if (!snapshot.hasData) {
              return ErrorView.loading(message: l10n.loading);
            }
            final ids = snapshot.data!;
            if (ids.isEmpty) {
              return ErrorView.empty(
                title: l10n.blockedUsersEmpty,
                message: l10n.blockedUsersEmpty,
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: ids.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final blockedUid = ids[index];
                return ListTile(
                  minVerticalPadding: 12,
                  leading: const ExcludeSemantics(child: Icon(Icons.block)),
                  title: Text(l10n.blockedUserNumber(index + 1)),
                  trailing: TextButton(
                    onPressed: () async {
                      try {
                        await client.unblock(blockedUid);
                      } catch (_) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.errorGeneric)),
                        );
                      }
                    },
                    child: Text(l10n.unblock),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
