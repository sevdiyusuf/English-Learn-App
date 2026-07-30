import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../logic/friends_controller.dart';
import '../logic/invitation_controller.dart';

class FriendSelectionSheet extends ConsumerWidget {
  const FriendSelectionSheet({
    required this.roomId,
    required this.gameType,
    super.key,
  });

  final String roomId;
  final String gameType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendsState = ref.watch(friendsControllerProvider);
    final friends = friendsState.friends;

    return Container(
      padding: const EdgeInsets.all(16),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Arkadaşını Davet Et',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          if (friends.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Text('Henüz ekli arkadaşın yok.'),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: friends.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final friend = friends[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage:
                          friend.photoUrl != null
                              ? NetworkImage(friend.photoUrl!)
                              : null,
                      child:
                          friend.photoUrl == null
                              ? Text(
                                friend.displayName?[0].toUpperCase() ?? '?',
                              )
                              : null,
                    ),
                    title: Text(friend.displayName ?? 'İsimsiz'),
                    trailing: TextButton(
                      onPressed: () async {
                        // Send invitation
                        await ref
                            .read(invitationControllerProvider.notifier)
                            .sendInvitation(
                              toUid: friend.uid,
                              roomId: roomId,
                              gameType: gameType,
                            );

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Davet gönderildi!')),
                          );
                          Navigator.pop(context);
                        }
                      },
                      child: const Text('Davet Et'),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
