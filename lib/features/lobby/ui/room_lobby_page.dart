import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/notifications/notification_service.dart';
import '../../../core/responsive/responsive_utils.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/error_message_helper.dart';
import '../../../core/utils/retry_helper.dart';
import '../../../core/utils/storage_service.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../../auth/logic/auth_controller.dart';
import '../../game/models/room.dart';
import '../logic/room_controller.dart';

class RoomLobbyPage extends ConsumerStatefulWidget {
  const RoomLobbyPage({required this.roomId, super.key});

  static const routeName = 'room-lobby';

  final String roomId;

  @override
  ConsumerState<RoomLobbyPage> createState() => _RoomLobbyPageState();
}

class _RoomLobbyPageState extends ConsumerState<RoomLobbyPage> {
  @override
  Widget build(BuildContext context) {
    try {
      // Check if roomId is a roomCode (5 digits) or document ID
      // If it's 5 digits, treat it as roomCode, otherwise as document ID
      final isRoomCode = RegExp(r'^\d{5}$').hasMatch(widget.roomId);
      final roomAsync =
          isRoomCode
              ? ref.watch(roomStreamProvider(widget.roomId))
              : ref.watch(roomStreamByIdProvider(widget.roomId));

      // Listen for room status changes - redirect to game when status becomes active
      // Only redirect if we're not already on game page (prevents double navigation)
      final roomStream =
          isRoomCode
              ? roomStreamProvider(widget.roomId)
              : roomStreamByIdProvider(widget.roomId);
      ref.listen<AsyncValue<Room?>>(roomStream, (prev, next) {
        final room = next.valueOrNull;
        final prevRoom = prev?.valueOrNull;

        // If room becomes null (deleted), clear storage and redirect to home
        if (room == null && prevRoom != null) {
          // Room was deleted - clear storage and redirect
          Future.microtask(() async {
            await StorageService.clearRoomData();
            if (mounted && context.mounted) {
              context.go('/');
            }
          });
          return;
        }

        if (room == null) {
          return;
        }
        if (!mounted) return;
        // Only redirect if status changed from non-active to active
        if (room.status == RoomStatus.active &&
            prevRoom?.status != RoomStatus.active) {
          // Small delay to ensure room is fully updated on server
          Future.delayed(const Duration(milliseconds: 500), () {
            if (!mounted || !context.mounted) return;
            // Use room.id for game page (it needs the document ID)
            final gameRoomId = room.id ?? widget.roomId;
            if (gameRoomId.isNotEmpty) {
              context.go('/game/$gameRoomId');
            }
          });
        }
      });

      final authState = ref.watch(authControllerProvider);
      final user = authState.value;
      final controllerState = ref.watch(roomControllerProvider);

      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.surfaceDark.withValues(alpha: 0.9),
          title: Text(
            'Oda lobisi',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize:
                  (Theme.of(context).textTheme.titleLarge?.fontSize ?? 20) *
                  1.35,
              fontWeight: FontWeight.bold,
              color: const Color.fromARGB(255, 252, 217, 217),
            ),
          ),
          actions: [
            Builder(
              builder: (context) {
                // Use the same logic as main build method
                final isRoomCode = RegExp(r'^\d{5}$').hasMatch(widget.roomId);
                final roomAsync =
                    isRoomCode
                        ? ref.watch(roomStreamProvider(widget.roomId))
                        : ref.watch(roomStreamByIdProvider(widget.roomId));
                final room = roomAsync.valueOrNull;
                final roomCode =
                    room?.roomCode ?? (isRoomCode ? widget.roomId : null);
                if (roomCode == null) {
                  return const SizedBox.shrink();
                }
                return IconButton(
                  tooltip: 'Oda kodunu kopyala',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: roomCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Oda kodu kopyalandı: $roomCode')),
                    );
                  },
                  icon: const Icon(Icons.copy_outlined),
                );
              },
            ),
          ],
        ),
        body: Builder(
          builder: (context) {
            return roomAsync.when(
              loading: () {
                return const PageSkeleton();
              },
              error:
                  (error, stack) => Center(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Oda yüklenemedi',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            SelectableText(
                              ErrorMessageHelper.getErrorMessage(
                                error,
                                defaultMessage:
                                    'Oda yüklenirken bir hata oluştu.',
                              ),
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                            if (ErrorMessageHelper.isRetryable(error) ||
                                RetryHelper.isRetryableError(error)) ...[
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () {
                                  // Retry by invalidating the room stream
                                  final isRoomCode = RegExp(
                                    r'^\d{5}$',
                                  ).hasMatch(widget.roomId);
                                  if (isRoomCode) {
                                    ref.invalidate(
                                      roomStreamProvider(widget.roomId),
                                    );
                                  } else {
                                    ref.invalidate(
                                      roomStreamByIdProvider(widget.roomId),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.refresh),
                                label: const Text('Yeniden Dene'),
                              ),
                            ],
                            if (kDebugMode) ...[
                              const SizedBox(height: 16),
                              Container(
                                constraints: const BoxConstraints(
                                  maxHeight: 200,
                                ),
                                child: SingleChildScrollView(
                                  child: SelectableText(
                                    'Stack trace:\n$stack',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
              data: (room) {
                if (room == null) {
                  // Clear storage and redirect to home when room is null
                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                    await StorageService.clearRoomData();
                    if (mounted && context.mounted) {
                      context.go('/');
                    }
                  });
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Oda bulunamadı veya silinmiş.',
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Ana sayfaya yönlendiriliyorsunuz...',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                final isHost = user?.uid == room.hostUid;

                return ResponsiveBuilder(
                  builder: (context, screenSize) {
                    final isDesktop =
                        screenSize == ScreenSize.desktop ||
                        screenSize == ScreenSize.wide ||
                        screenSize == ScreenSize.ultraWide;
                    final padding = ResponsiveUtils.responsivePadding(context);
                    final spacing = ResponsiveUtils.responsiveSpacing(context);

                    return SingleChildScrollView(
                      child: AdaptiveContainer(
                        padding: padding,
                        child:
                            isDesktop
                                ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: _buildPlayersList(
                                        context,
                                        room,
                                        user?.uid,
                                      ),
                                    ),
                                    SizedBox(width: spacing * 2),
                                    SizedBox(
                                      width: ResponsiveUtils.responsive<double>(
                                        context: context,
                                        mobile: double.infinity,
                                        tablet: 350,
                                        desktop: 400,
                                        wide: 450,
                                      ),
                                      child: _buildSidebar(
                                        context,
                                        room,
                                        isHost,
                                        controllerState.isLoading,
                                      ),
                                    ),
                                  ],
                                )
                                : Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _buildPlayersList(context, room, user?.uid),
                                    SizedBox(height: spacing * 2),
                                    _buildSidebar(
                                      context,
                                      room,
                                      isHost,
                                      controllerState.isLoading,
                                    ),
                                  ],
                                ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      );
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('RoomLobbyPage: Exception in build: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.surfaceDark.withValues(alpha: 0.9),
          title: const Text('Hata'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                const Text('Sayfa yüklenirken hata oluştu'),
                const SizedBox(height: 8),
                SelectableText('$e'),
                if (kDebugMode) ...[
                  const SizedBox(height: 16),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        '$stackTrace',
                        style: const TextStyle(
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildPlayersList(
    BuildContext context,
    Room room,
    String? currentUid,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Oda kodu: ${room.roomCode ?? widget.roomId}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text(
              'Oyuncular (${room.players.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 400),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: room.players.length,
                itemBuilder: (context, index) {
                  final playerUid = room.players[index];
                  final playerName = room.playerNames[playerUid] ?? playerUid;
                  final isCurrent = playerUid == currentUid;
                  final isActive = room.activePlayerIds.contains(playerUid);
                  final isPlayerHost = playerUid == room.hostUid;
                  return ListTile(
                    leading: CircleAvatar(child: Text('${index + 1}')),
                    title: Text(playerName),
                    subtitle: Text(
                      isPlayerHost
                          ? 'Host'
                          : isActive
                          ? 'Aktif oyuncu'
                          : 'Bekliyor',
                    ),
                    trailing:
                        isCurrent ? const Icon(Icons.person_outline) : null,
                  );
                },
                separatorBuilder: (_, __) => const Divider(height: 1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar(
    BuildContext context,
    Room room,
    bool isHost,
    bool isBusy,
  ) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Durum: ${room.status.name}'),
            Text('Tur süresi: ${room.turnDurationSeconds} sn'),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed:
                  isBusy
                      ? null
                      : () async {
                        try {
                          // Use room.id (document ID) for leaveRoom, fallback to widget.roomId
                          // room_controller will handle roomCode vs document ID conversion
                          final roomId = room.id ?? widget.roomId;
                          await ref
                              .read(roomControllerProvider.notifier)
                              .leaveRoom(roomId: roomId);
                          // Clear room data from storage when leaving
                          await StorageService.clearRoomData();
                          if (!mounted || !context.mounted) return;
                          context.go('/');
                        } on Object catch (err) {
                          if (!mounted || !context.mounted) return;
                          final messenger = ScaffoldMessenger.of(context);
                          messenger.showSnackBar(
                            SnackBar(content: Text('$err')),
                          );
                        }
                      },
              icon: const Icon(Icons.logout),
              label: const Text('Odadan ayrıl'),
            ),
            const SizedBox(height: 16),
            if (isHost)
              FilledButton.icon(
                onPressed:
                    (isBusy ||
                            room.players.length < 2 ||
                            (room.status != RoomStatus.waiting &&
                                room.status != RoomStatus.finished))
                        ? null
                        : () async {
                          if (kDebugMode) {
                            debugPrint('Start game button clicked');
                            debugPrint('Room ID: ${room.id}');
                            debugPrint('Widget roomId: ${widget.roomId}');
                            debugPrint('Room status: ${room.status}');
                            debugPrint('Room players: ${room.players.length}');
                          }
                          try {
                            // Use room.id (document ID) for startGame, fallback to widget.roomId
                            // room_controller will handle roomCode vs document ID conversion
                            final roomId = room.id ?? widget.roomId;
                            if (roomId.isEmpty) {
                              if (!mounted) return;
                              ref
                                  .read(notificationServiceProvider)
                                  .showError(
                                    title: 'Hata',
                                    message: 'Oda ID bulunamadı',
                                  );
                              return;
                            }
                            if (kDebugMode) {
                              debugPrint(
                                'Calling startGame with roomId: $roomId',
                              );
                            }
                            await ref
                                .read(roomControllerProvider.notifier)
                                .startGame(roomId: roomId);
                            if (!mounted) return;
                            if (kDebugMode) {
                              debugPrint('Start game succeeded');
                            }
                            // Wait for room status to become active before navigating
                            // Use the actual roomId (document ID) for navigation
                            final actualRoomId = room.id ?? roomId;
                            if (actualRoomId.isNotEmpty) {
                              // Wait for room to become active (up to 5 seconds)
                              try {
                                final isRoomCode = RegExp(
                                  r'^\d{5}$',
                                ).hasMatch(actualRoomId);
                                final roomProvider =
                                    isRoomCode
                                        ? roomStreamProvider(actualRoomId)
                                        : roomStreamByIdProvider(actualRoomId);

                                Future<void> waitForActive() async {
                                  final current =
                                      ref.read(roomProvider).valueOrNull;
                                  if (current?.status == RoomStatus.active) {
                                    return;
                                  }
                                  final completer = Completer<void>();
                                  final sub = ref.listenManual<
                                    AsyncValue<Room?>
                                  >(roomProvider, (previous, next) {
                                    final room = next.valueOrNull;
                                    if (room?.status == RoomStatus.active &&
                                        !completer.isCompleted) {
                                      completer.complete();
                                    }
                                  }, fireImmediately: true);
                                  try {
                                    await completer.future.timeout(
                                      const Duration(seconds: 5),
                                    );
                                  } finally {
                                    sub.close();
                                  }
                                }

                                await waitForActive();

                                if (!mounted || !context.mounted) return;
                                if (kDebugMode) {
                                  debugPrint(
                                    'Room is now active, navigating to game',
                                  );
                                }
                                context.go('/game/$actualRoomId');
                              } catch (e) {
                                if (kDebugMode) {
                                  debugPrint(
                                    'Timeout waiting for room to become active: $e',
                                  );
                                }
                                if (!mounted || !context.mounted) return;
                                // Still navigate even if timeout - game page will handle it
                                context.go('/game/$actualRoomId');
                              }
                            }
                          } on Object catch (err, stackTrace) {
                            if (kDebugMode) {
                              debugPrint('Start game error: $err');
                              debugPrint('Stack trace: $stackTrace');
                            }
                            if (!mounted) return;
                            // Show error notification with user-friendly message
                            ref
                                .read(notificationServiceProvider)
                                .showError(
                                  title: 'Oyun başlatılamadı',
                                  message: ErrorMessageHelper.getErrorMessage(
                                    err,
                                    defaultMessage:
                                        'Oyun başlatılırken bir hata oluştu. Lütfen tekrar deneyin.',
                                  ),
                                );
                          }
                        },
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(
                  room.status == RoomStatus.finished
                      ? 'Yeniden Başlat'
                      : 'Oyunu başlat',
                ),
              )
            else
              const Text(
                'Host oyunu başlatınca tur otomatik başlayacak.',
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}
