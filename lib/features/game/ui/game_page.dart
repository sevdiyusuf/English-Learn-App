import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/animations/animations.dart';
import '../../../../core/notifications/game_notifications.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/error_message_helper.dart';
import '../../../../core/utils/retry_helper.dart';
import '../../../../core/utils/storage_service.dart';
import '../../../../core/widgets/loading_skeleton.dart';
import '../../auth/logic/auth_controller.dart';
import '../logic/game_controller.dart';
import '../logic/timer_service.dart';
import '../models/game_state.dart';
import '../models/room.dart';
import 'components/countdown_widget.dart';
import 'components/player_badges.dart';
import 'components/word_input.dart';
import 'components/word_pool.dart';

class GamePage extends ConsumerStatefulWidget {
  const GamePage({required this.roomId, super.key});

  static const routeName = 'game';

  final String roomId;

  @override
  ConsumerState<GamePage> createState() => _GamePageState();
}

class _GamePageState extends ConsumerState<GamePage> {
  String? _previousTurnUid;
  bool _gameEndDialogShown = false;

  @override
  Widget build(BuildContext context) {
    final gameAsync = ref.watch(gameControllerProvider(widget.roomId));
    final timerState = ref.watch(timerServiceProvider);
    final authState = ref.watch(authControllerProvider);
    final userUid = authState.value?.uid;

    // Handle game notifications - only notify when turn changes
    gameAsync.whenData((game) {
      final room = game.room;
      final currentTurnUid = room.currentTurnUid;

      // Only notify when it's the user's turn (not on status changes)
      if (_previousTurnUid != currentTurnUid && currentTurnUid == userUid) {
        GameNotifications.setupGameNotifications(ref, room, userUid);
      }

      _previousTurnUid = currentTurnUid;
    });

    // Listen for game finished state - must be in build method
    ref.listen<AsyncValue<GameState>>(gameControllerProvider(widget.roomId), (
      prev,
      next,
    ) {
      next.whenOrNull(
        data: (game) {
          // Only show dialog once when game finishes
          final prevGame = prev?.valueOrNull;
          final wasFinished = prevGame?.room.status == RoomStatus.finished;
          final isFinished = game.room.status == RoomStatus.finished;

          if (isFinished && !wasFinished && !_gameEndDialogShown) {
            _gameEndDialogShown = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              final winner = game.room.winnerUid;

              // Get winner name from playerNames map
              final winnerName =
                  winner != null
                      ? (game.room.playerNames[winner] ?? winner)
                      : 'Berabere';

              showDialog<void>(
                context: context,
                barrierDismissible: false,
                builder:
                    (ctx) => SuccessAnimation(
                      child: AlertDialog(
                        title: const Text('Oyun bitti!'),
                        content: Text(
                          winner != null
                              ? 'Kazanan: $winnerName'
                              : 'Oyun berabere bitti!',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              setState(() {
                                _gameEndDialogShown = false;
                              });
                              // Always use widget.roomId (the document ID we're currently viewing)
                              // Navigate immediately without async operations
                              if (widget.roomId.isNotEmpty) {
                                context.go('/room/${widget.roomId}');
                              } else {
                                context.go('/');
                              }
                            },
                            child: const Text('Odaya dön'),
                          ),
                        ],
                      ),
                    ),
              );
            });
          }
        },
      );
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          // Navigate to lobby instead of popping
          final savedRoomId = StorageService.getRoomId();
          final savedRoomCode = StorageService.getRoomCode();

          if (savedRoomId != null && savedRoomId.isNotEmpty) {
            context.go('/room/$savedRoomId');
          } else if (savedRoomCode != null && savedRoomCode.isNotEmpty) {
            context.go('/room/$savedRoomCode');
          } else {
            context.go('/');
          }
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: const Color(0xFF4F46E5), // Dark purple
          foregroundColor: Colors.white,
          leading: IconButton(
            tooltip: 'Odaya dön',
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              final savedRoomId = StorageService.getRoomId();
              final savedRoomCode = StorageService.getRoomCode();

              if (savedRoomId != null && savedRoomId.isNotEmpty) {
                context.go('/room/$savedRoomId');
              } else if (savedRoomCode != null && savedRoomCode.isNotEmpty) {
                context.go('/room/$savedRoomCode');
              } else {
                context.go('/');
              }
            },
          ),
          title: gameAsync.when(
            data: (game) {
              if (game.room.status == RoomStatus.active) {
                final timerOffset = timerState.asData?.value ?? Duration.zero;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Word Battle',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _GameTimer(
                      startTime: game.room.createdAt,
                      serverOffset: timerOffset,
                    ),
                  ],
                );
              }
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Word Battle',
                  style: TextStyle(color: Colors.white),
                ),
              );
            },
            loading:
                () => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Word Battle',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
            error:
                (_, __) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Word Battle',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
          ),
          actions: [
            IconButton(
              tooltip: 'Nasıl oynanır?',
              onPressed: () => _showHowToPlayDialog(context),
              icon: const Icon(Icons.help_outline),
            ),
            IconButton(
              tooltip: 'Oyundan çık',
              onPressed: () {
                final savedRoomId = StorageService.getRoomId();
                final savedRoomCode = StorageService.getRoomCode();

                if (savedRoomId != null && savedRoomId.isNotEmpty) {
                  context.go('/room/$savedRoomId');
                } else if (savedRoomCode != null && savedRoomCode.isNotEmpty) {
                  context.go('/room/$savedRoomCode');
                } else {
                  context.go('/');
                }
              },
              icon: const Icon(Icons.exit_to_app),
            ),
          ],
        ),
        body: gameAsync.when(
          loading: () => const GamePageSkeleton(),
          error: (error, stack) {
            // If room not found, clear storage and redirect
            final errorMessage = ErrorMessageHelper.getErrorMessage(error);
            final isRoomNotFound =
                errorMessage.contains('bulunamadı') ||
                errorMessage.contains('silinmiş') ||
                error.toString().contains('bulunamadı') ||
                error.toString().contains('silinmiş');

            if (isRoomNotFound) {
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                await StorageService.clearRoomData();
                if (mounted && context.mounted) {
                  context.go('/');
                }
              });
            }

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      ErrorMessageHelper.getErrorIcon(error),
                      size: 48,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Oyun yüklenemedi',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ErrorMessageHelper.getErrorMessage(
                        error,
                        defaultMessage: 'Oyun yüklenirken bir hata oluştu.',
                      ),
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    if (isRoomNotFound) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Ana sayfaya yönlendiriliyorsunuz...',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ] else if (ErrorMessageHelper.isRetryable(error) ||
                        RetryHelper.isRetryableError(error)) ...[
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          // Retry by refreshing the game state
                          ref.invalidate(gameControllerProvider(widget.roomId));
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Yeniden Dene'),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
          data: (game) {
            // Handle finished or waiting game state - but don't redirect if dialog is showing
            // This prevents errors when "Yeniden başlat" is clicked
            if (game.room.status == RoomStatus.finished ||
                game.room.status == RoomStatus.waiting) {
              // Don't redirect if game end dialog is showing
              if (!_gameEndDialogShown) {
                // Only redirect if we're waiting (not finished, as dialog should handle that)
                if (game.room.status == RoomStatus.waiting) {
                  Future.microtask(() {
                    if (mounted && context.mounted) {
                      context.go('/room/${widget.roomId}');
                    }
                  });
                  return const Center(child: CircularProgressIndicator());
                }
                // If finished, show loading but let dialog handle navigation
                return const Center(child: CircularProgressIndicator());
              }
              // Dialog is showing, just show loading
              return const Center(child: CircularProgressIndicator());
            }

            // Only show game UI if room is active
            final isPlayerTurn = game.room.currentTurnUid == userUid;
            final timerOffset = timerState.asData?.value ?? Duration.zero;

            return Stack(
              children: [
                // Background image
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/background.png',
                    fit: BoxFit.cover,
                  ),
                ),
                // Content with padding and semi-transparent white overlay
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header with countdown and player info
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceDark.withValues(alpha: 0.9),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Game elapsed time
                            if (game.room.status == RoomStatus.active)
                              _GameTimer(
                                startTime: game.room.createdAt,
                                serverOffset: timerOffset,
                              ),
                            FadeInAnimation(
                              child: CountdownWidget(
                                deadline: game.room.turnDeadlineAt,
                                turnDurationSeconds:
                                    game.room.turnDurationSeconds,
                                isActiveTurn: isPlayerTurn,
                                serverOffset: timerOffset,
                                onTimeout: () async {
                                  try {
                                    await ref
                                        .read(
                                          gameControllerProvider(
                                            widget.roomId,
                                          ).notifier,
                                        )
                                        .resolveTimeout();
                                  } on Object catch (_) {}
                                },
                              ),
                            ),
                            const SizedBox(height: 8),
                            SlideInAnimation(
                              delay: const Duration(milliseconds: 100),
                              child: PlayerBadges(
                                room: game.room,
                                currentUid: userUid,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Messages area - takes most of the space
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.surfaceDark.withValues(alpha: 0.9),
                          ),
                          child: WordPool(
                            playedWords: game.playedWords,
                            room: game.room,
                            currentUid: userUid,
                          ),
                        ),
                      ),
                      // Input area at the bottom
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F46E5), // Dark purple
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: WordInput(
                          enabled:
                              isPlayerTurn &&
                              game.room.status == RoomStatus.active,
                          currentWordType: game.room.currentWordType,
                          onWordSubmit: (word) async {
                            try {
                              final isVerb =
                                  game.room.currentWordType == 'verb' ||
                                  game.room.currentWordType == null;

                              if (isVerb) {
                                await ref
                                    .read(
                                      gameControllerProvider(
                                        widget.roomId,
                                      ).notifier,
                                    )
                                    .submitVerb(verb: word);
                                if (!mounted) return;
                                ref
                                    .read(notificationServiceProvider)
                                    .showSuccess(
                                      title: 'Fiil gönderildi',
                                      message: 'Sıra rakibinde',
                                    );
                              } else {
                                await ref
                                    .read(
                                      gameControllerProvider(
                                        widget.roomId,
                                      ).notifier,
                                    )
                                    .submitAdjective(adjective: word);
                                if (!mounted) return;
                                ref
                                    .read(notificationServiceProvider)
                                    .showSuccess(
                                      title: 'Sıfat gönderildi!',
                                      message: 'Sıra rakibinde',
                                    );
                              }
                            } on Object catch (err) {
                              if (!mounted) return;
                              ref
                                  .read(notificationServiceProvider)
                                  .showError(
                                    title: 'Hata',
                                    message: ErrorMessageHelper.getErrorMessage(
                                      err,
                                    ),
                                  );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showHowToPlayDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Nasıl oynanır?'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• Oyuncular sırayla kelime yazar.\n'
                  '• Sıra sende olduğunda, altta gözüken kelime türüne göre (fiil / sıfat) bir kelime gir.\n'
                  '• Süre bittiğinde hamle yapmadıysan tur otomatik geçer.\n'
                  '• Geçerli kelime yazan oyuncu puan kazanır; tekrar eden kelimeler sayılmaz.',
                ),
                SizedBox(height: 12),
                Text(
                  'İpucu: Rakibinin kelimelerini tekrar etmemeye ve daha zor kelimeler seçmeye çalış!',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Tamam'),
              ),
            ],
          ),
    );
  }
}

class _GameTimer extends StatefulWidget {
  const _GameTimer({required this.startTime, required this.serverOffset});

  final DateTime startTime;
  final Duration serverOffset;

  @override
  State<_GameTimer> createState() => _GameTimerState();
}

class _GameTimerState extends State<_GameTimer> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateElapsed();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateElapsed();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateElapsed() {
    final adjustedNow = DateTime.now().add(widget.serverOffset);
    final elapsed = adjustedNow.difference(widget.startTime);
    if (mounted) {
      setState(() {
        _elapsed = elapsed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final minutes = _elapsed.inMinutes;
    final seconds = _elapsed.inSeconds % 60;
    final formattedTime =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            formattedTime,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
