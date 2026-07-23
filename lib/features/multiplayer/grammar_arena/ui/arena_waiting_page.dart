import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../logic/arena_session_controller.dart';
import '../logic/arena_lobby_controller.dart';
import '../models/arena_models.dart';
import '../data/worksheet_catalog_repo.dart';
import '../../../training/models/training_models.dart';
import '../../../auth/logic/auth_controller.dart';
import '../../../friends/ui/friend_selection_sheet.dart';
import '../../../../core/theme/app_colors.dart';

final catalogFutureProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(worksheetCatalogRepoProvider).getCatalog();
});

class ArenaWaitingPage extends ConsumerWidget {
  final String roomId;
  const ArenaWaitingPage({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(arenaSessionControllerProvider(roomId));
    final catalogAsync = ref.watch(catalogFutureProvider);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primaryDark, AppColors.backgroundDark],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            'Bekleme Odası',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.transparent,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: sessionState.when(
          data: (state) {
            final room = state.room;
            if (room == null) {
              return const Center(
                child: Text(
                  'Oda bulunamadı',
                  style: TextStyle(color: Colors.white),
                ),
              );
            }

            // Auto navigate if active
            if (room.status == ArenaStatus.active) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
                  context.go('/multiplayer/grammar-arena/game/$roomId');
                }
              });
            }

            final user = ref.read(authControllerProvider).value;
            final isHost = user?.uid == room.hostId;

            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Room Code
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'ODA KODU',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              room.roomCode,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 4,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy, color: Colors.white),
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: room.roomCode),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Kopyalandı!')),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Players
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildPlayerAvatar(context, room.host, isHost: true),
                      const Text(
                        'VS',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white54,
                        ),
                      ),
                      _buildPlayerAvatar(context, room.guest, isHost: false),
                    ],
                  ),

                  const SizedBox(height: 16),

                  if (isHost && room.guest == null)
                    Center(
                      child: TextButton.icon(
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: AppColors.surface,
                            builder:
                                (context) => FriendSelectionSheet(
                                  roomId: room.roomCode,
                                  gameType: 'grammar_arena',
                                ),
                          );
                        },
                        icon: const Icon(Icons.person_add, color: Colors.white),
                        label: const Text(
                          'Arkadaş Davet Et',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 32),

                  // Config Selection
                  if (catalogAsync.hasValue)
                    _buildConfigSelection(
                      context,
                      ref,
                      isHost,
                      room.config,
                      catalogAsync.value!,
                      roomId,
                    )
                  else if (catalogAsync.isLoading)
                    const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  else
                    const Text(
                      'Katalog yüklenemedi',
                      style: TextStyle(color: Colors.white70),
                    ),

                  const Spacer(),

                  if (isHost)
                    ElevatedButton(
                      onPressed:
                          room.guestId != null
                              ? () {
                                ref
                                    .read(arenaLobbyControllerProvider.notifier)
                                    .startGame(roomId, room.config);
                              }
                              : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48,
                          vertical: 16,
                        ),
                        backgroundColor: Colors.green,
                        disabledBackgroundColor: Colors.grey,
                      ),
                      child: const Text(
                        'OYUNU BAŞLAT',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    )
                  else
                    const Text(
                      'Oda sahibinin başlatması bekleniyor...',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                ],
              ),
            );
          },
          loading:
              () => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
          error:
              (e, st) => Center(
                child: Text(
                  'Hata: $e',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
        ),
      ),
    );
  }

  Widget _buildConfigSelection(
    BuildContext context,
    WidgetRef ref,
    bool isHost,
    ArenaConfig config,
    Map<String, List<WorksheetMetadata>> catalog,
    String roomId,
  ) {
    final levels = ['A1', 'A2', 'B1', 'B2'];
    final worksheets = catalog[config.level] ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'OYUN AYARLARI',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),

          // Level Selection
          Row(
            children: [
              const Icon(
                Icons.signal_cellular_alt,
                color: Colors.white70,
                size: 20,
              ),
              const SizedBox(width: 12),
              const Text('Seviye:', style: TextStyle(color: Colors.white)),
              const SizedBox(width: 16),
              Expanded(
                child:
                    isHost
                        ? DropdownButtonFormField<String>(
                          initialValue: config.level,
                          dropdownColor: AppColors.surfaceDark,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            border: OutlineInputBorder(),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white30),
                            ),
                          ),
                          items:
                              levels.map((level) {
                                return DropdownMenuItem(
                                  value: level,
                                  child: Text(level),
                                );
                              }).toList(),
                          onChanged: (val) {
                            if (val != null && val != config.level) {
                              ref
                                  .read(arenaLobbyControllerProvider.notifier)
                                  .updateRoomConfig(
                                    roomId,
                                    config.copyWith(
                                      level: val,
                                      worksheetId: null,
                                    ),
                                  );
                            }
                          },
                        )
                        : Text(
                          config.level,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Worksheet Selection
          Row(
            children: [
              const Icon(Icons.description, color: Colors.white70, size: 20),
              const SizedBox(width: 12),
              const Text('Konu:', style: TextStyle(color: Colors.white)),
              const SizedBox(width: 16),
              Expanded(
                child:
                    isHost
                        ? DropdownButtonFormField<String?>(
                          initialValue: config.worksheetId,
                          dropdownColor: AppColors.surfaceDark,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            border: OutlineInputBorder(),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white30),
                            ),
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Rastgele'),
                            ),
                            ...worksheets.map((ws) {
                              return DropdownMenuItem<String?>(
                                value: ws.worksheetId,
                                child: Text(
                                  ws.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }),
                          ],
                          onChanged: (val) {
                            if (val != config.worksheetId) {
                              ref
                                  .read(arenaLobbyControllerProvider.notifier)
                                  .updateRoomConfig(
                                    roomId,
                                    config.copyWith(worksheetId: val),
                                  );
                            }
                          },
                        )
                        : Text(
                          config.worksheetId != null
                              ? (worksheets
                                  .firstWhere(
                                    (w) => w.worksheetId == config.worksheetId,
                                    orElse:
                                        () => WorksheetMetadata(
                                          worksheetId: '',
                                          title: 'Bilinmiyor',
                                          path: '',
                                          tags: [],
                                          level: '',
                                        ),
                                  )
                                  .title)
                              : 'Rastgele',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerAvatar(
    BuildContext context,
    ArenaPlayer? player, {
    required bool isHost,
  }) {
    if (player == null) {
      return Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            child: const Icon(
              Icons.person_add,
              color: Colors.white30,
              size: 40,
            ),
          ),
          const SizedBox(height: 8),
          const Text('Bekleniyor...', style: TextStyle(color: Colors.white54)),
        ],
      );
    }
    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundImage:
              player.photoUrl != null ? NetworkImage(player.photoUrl!) : null,
          child:
              player.photoUrl == null
                  ? Text(player.name[0].toUpperCase())
                  : null,
        ),
        const SizedBox(height: 8),
        Text(
          player.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (isHost)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'KURUCU',
              style: TextStyle(fontSize: 10, color: Colors.black),
            ),
          ),
      ],
    );
  }
}
