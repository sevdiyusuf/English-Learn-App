import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../logic/friends_controller.dart';
import '../models/friend_models.dart';
import 'friend_profile_page.dart';

// Ana Sayfa Tema Sabitleri
const _backgroundColor = Color(0xFF050505);
const _accentColor = Color(0xFF2997FF);
const _stoneGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Color(0xFF2C2C2E),
    Color(0xFF1C1C1E),
  ],
);
final _borderSideColor = Colors.white.withValues(alpha: 0.08);
const _primaryTextColor = Colors.white;
const _secondaryTextColor = Color(0xFF98989F);

class FriendsPage extends ConsumerWidget {
  const FriendsPage({super.key});

  static const routeName = 'friends';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(friendsControllerProvider);

    return Scaffold(
      backgroundColor: _backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Sosyal',
          style: TextStyle(
            color: _primaryTextColor,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          // Arka plan blur (Ana Sayfa stili)
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _accentColor.withValues(alpha: 0.05),
                boxShadow: [
                  BoxShadow(
                    color: _accentColor.withValues(alpha: 0.05),
                    blurRadius: 100,
                  ),
                ],
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: Container(),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (state.profile != null) ...[
                    _buildProfileHeader(state),
                    const SizedBox(height: 24),
                  ],
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'ARKADAŞLARIM',
                          style: TextStyle(
                            color: _secondaryTextColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _showAddFriendDialog(context, ref, state),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _accentColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.person_add, color: _accentColor, size: 16),
                              SizedBox(width: 4),
                              Text(
                                'Ekle',
                                style: TextStyle(
                                  color: _accentColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: state.isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: _accentColor,
                            ),
                          )
                        : _buildFriendsList(context, state),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'GELEN İSTEKLER',
                    style: TextStyle(
                      color: _secondaryTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 140,
                    child: _buildRequestsList(context, ref, state),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(FriendsState state) {
    final profile = state.profile!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: _stoneGradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _borderSideColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _accentColor.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFF2C2C2E),
              child: Text(
                (profile.displayName ?? 'Kullanıcı').substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.displayName ?? 'Kullanıcı',
                  style: const TextStyle(
                    color: _primaryTextColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Kullanıcı kodun: ${profile.userCode ?? 'Yükleniyor...'}',
                  style: const TextStyle(
                    color: _secondaryTextColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsList(BuildContext context, FriendsState state) {
    if (state.friends.isEmpty) {
      return Center(
        child: Text(
          'Henüz arkadaşın yok.\nKodunu paylaşarak arkadaş ekleyebilirsin.',
          style: TextStyle(color: _secondaryTextColor.withValues(alpha: 0.8)),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.separated(
      itemCount: state.friends.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final friend = state.friends[index];
        return Container(
          decoration: BoxDecoration(
            gradient: _stoneGradient,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _borderSideColor, width: 1),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _accentColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: CircleAvatar(
                backgroundColor: const Color(0xFF1C1C1E),
                child: Text(
                  (friend.displayName ?? 'K').substring(0, 1).toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            title: Text(
              friend.displayName ?? 'Kullanıcı',
              style: const TextStyle(color: _primaryTextColor, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'Kod: ${friend.userCode ?? '-'}',
              style: const TextStyle(
                color: _secondaryTextColor,
                fontSize: 12,
              ),
            ),
            trailing: Icon(Icons.chevron_right, color: _borderSideColor.withValues(alpha: 0.3)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FriendProfilePage(profile: friend),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildRequestsList(BuildContext context, WidgetRef ref, FriendsState state) {
    final incoming = state.incomingRequests
        .where((r) => r.status == FriendRequestStatus.pending)
        .toList();
        
    if (incoming.isEmpty) {
      return Center(
        child: Text(
          'Bekleyen arkadaşlık isteği yok.',
          style: TextStyle(
            color: _secondaryTextColor.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
      );
    }

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: incoming.length,
      separatorBuilder: (_, __) => const SizedBox(width: 16),
      itemBuilder: (context, index) {
        final request = incoming[index];
        return Container(
          width: 260,
          decoration: BoxDecoration(
            gradient: _stoneGradient,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _borderSideColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Arkadaşlık isteği',
                  style: TextStyle(
                    color: _primaryTextColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Gönderen: ${request.fromUid}',
                  style: const TextStyle(
                    color: _secondaryTextColor,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          await ref.read(friendsControllerProvider.notifier).rejectRequest(request);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'Reddet',
                            style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          await ref.read(friendsControllerProvider.notifier).acceptRequest(request);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _accentColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'Kabul Et',
                            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showAddFriendDialog(BuildContext context, WidgetRef ref, FriendsState state) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1C1C1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: _borderSideColor),
          ),
          title: const Text(
            'Arkadaş Ekle',
            style: TextStyle(color: _primaryTextColor, fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: _primaryTextColor),
            decoration: InputDecoration(
              labelText: 'Arkadaş Kodu',
              labelStyle: const TextStyle(color: _secondaryTextColor),
              filled: true,
              fillColor: const Color(0xFF2C2C2E),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _accentColor),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Vazgeç',
                style: TextStyle(color: _secondaryTextColor),
              ),
            ),
            FilledButton(
              onPressed: () {
                final text = controller.text.trim();
                if (text.isEmpty) return;
                Navigator.pop(ctx, text);
              },
              style: FilledButton.styleFrom(
                backgroundColor: _accentColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('İstek Gönder', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (result == null) return;

    try {
      await ref.read(friendsControllerProvider.notifier).sendFriendRequestByCode(result);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Arkadaşlık isteği gönderildi')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('İstek gönderilemedi: $e')),
        );
      }
    }
  }
}
