import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yunoo/l10n/app_localizations.dart';

import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/responsive_content.dart';
import '../logic/friends_controller.dart';
import '../models/friend_models.dart';
import 'friend_profile_page.dart';

class FriendsPage extends ConsumerWidget {
  const FriendsPage({super.key});

  static const routeName = 'friends';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(friendsControllerProvider);
    final incoming =
        state.incomingRequests
            .where((request) => request.status == FriendRequestStatus.pending)
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navigationSocial),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        top: false,
        child:
            state.isLoading
                ? ErrorView.loading(message: l10n.loading)
                : ResponsiveContent(
                  maxWidth: 840,
                  child: ListView(
                    key: const PageStorageKey<String>('friends-scroll'),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    children: [
                      if (state.errorMessage != null)
                        Semantics(
                          liveRegion: true,
                          child: Card(
                            child: ListTile(
                              leading: const Icon(Icons.error_outline),
                              title: Text(l10n.errorGeneric),
                            ),
                          ),
                        ),
                      if (state.profile case final profile?) ...[
                        _ProfileHeader(profile: profile),
                        const SizedBox(height: 24),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: Semantics(
                              header: true,
                              child: Text(
                                l10n.myFriends,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: () => _showAddFriendDialog(context, ref),
                            icon: const Icon(Icons.person_add),
                            label: Text(l10n.addFriend),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (state.friends.isEmpty)
                        _EmptySection(message: l10n.friendsEmpty)
                      else
                        ...state.friends.map(
                          (friend) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Card(
                              margin: EdgeInsets.zero,
                              clipBehavior: Clip.antiAlias,
                              child: ListTile(
                                minVerticalPadding: 12,
                                leading: CircleAvatar(
                                  child: Text(_initial(friend.displayName)),
                                ),
                                title: Text(friend.displayName ?? l10n.user),
                                subtitle: Text(
                                  l10n.userCode(friend.userCode ?? '—'),
                                ),
                                trailing: const ExcludeSemantics(
                                  child: Icon(Icons.chevron_right),
                                ),
                                onTap:
                                    () => Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder:
                                            (_) => FriendProfilePage(
                                              profile: friend,
                                            ),
                                      ),
                                    ),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      Semantics(
                        header: true,
                        child: Text(
                          l10n.incomingFriendRequests,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (incoming.isEmpty)
                        _EmptySection(message: l10n.friendRequestsEmpty)
                      else
                        ...incoming.map(
                          (request) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Card(
                              margin: EdgeInsets.zero,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      l10n.friendRequest,
                                      style:
                                          Theme.of(
                                            context,
                                          ).textTheme.titleSmall,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(l10n.friendRequestPrivacyDescription),
                                    const SizedBox(height: 12),
                                    OverflowBar(
                                      spacing: 8,
                                      overflowSpacing: 8,
                                      children: [
                                        TextButton(
                                          onPressed:
                                              () => ref
                                                  .read(
                                                    friendsControllerProvider
                                                        .notifier,
                                                  )
                                                  .rejectRequest(request),
                                          child: Text(l10n.reject),
                                        ),
                                        FilledButton(
                                          onPressed:
                                              () => ref
                                                  .read(
                                                    friendsControllerProvider
                                                        .notifier,
                                                  )
                                                  .acceptRequest(request),
                                          child: Text(l10n.accept),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
      ),
    );
  }

  static String _initial(String? name) {
    final value = name?.trim() ?? '';
    return value.isEmpty ? '?' : value.characters.first.toUpperCase();
  }

  Future<void> _showAddFriendDialog(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 24,
            ),
            title: Text(l10n.addFriend),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: TextField(
                controller: controller,
                autofocus: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (value) {
                  final trimmed = value.trim();
                  if (trimmed.isNotEmpty) {
                    Navigator.pop(dialogContext, trimmed);
                  }
                },
                decoration: InputDecoration(labelText: l10n.friendCode),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () {
                  final value = controller.text.trim();
                  if (value.isNotEmpty) Navigator.pop(dialogContext, value);
                },
                child: Text(l10n.sendRequest),
              ),
            ],
          ),
    );
    controller.dispose();
    if (code == null || !context.mounted) return;

    try {
      await ref
          .read(friendsControllerProvider.notifier)
          .sendFriendRequestByCode(code);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.friendRequestSent)));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
    }
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              child: Text(FriendsPage._initial(profile.displayName)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.displayName ?? l10n.user,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(l10n.userCode(profile.userCode ?? l10n.loading)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(child: Text(message, textAlign: TextAlign.center)),
      ),
    );
  }
}
