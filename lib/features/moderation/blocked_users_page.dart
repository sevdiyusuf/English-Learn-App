import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../auth/logic/auth_controller.dart';
import 'moderation_client.dart';

class BlockedUsersPage extends ConsumerWidget {
  const BlockedUsersPage({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!; final user = ref.watch(authControllerProvider).value;
    if (user == null) return Scaffold(appBar: AppBar(title: Text(l.blockedUsers)), body: Center(child: Text(l.interactionUnavailable)));
    final client = ref.watch(moderationClientProvider)..setUid(user.uid);
    return Scaffold(appBar: AppBar(title: Text(l.blockedUsers)), body: StreamBuilder<List<String>>(
      stream: client.watchBlocked(), builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final ids = snapshot.data!; if (ids.isEmpty) return Center(child: Text(l.blockedUsersEmpty));
        return ListView.builder(itemCount: ids.length, itemBuilder: (_, index) => ListTile(
          leading: const Icon(Icons.block), title: Text(ids[index]),
          trailing: TextButton(onPressed: () async { try { await client.unblock(ids[index]); } catch (_) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.errorGeneric))); } }, child: Text(l.unblock)),
        ));
      },
    ));
  }
}
