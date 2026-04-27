import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/animations/animations.dart';
import '../../../../core/audio/sound_manager.dart';
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
import '../models/room.dart'; // RoomStatus, GameMode
import 'components/game_background.dart';
import 'components/game_header.dart';
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
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameAsync = ref.watch(gameControllerProvider(widget.roomId));
    final timerState = ref.watch(timerServiceProvider);
    final authState = ref.watch(authControllerProvider);
    final userUid = authState.value?.uid;

    // Listen for turn changes to show notifications
    ref.listen(gameControllerProvider(widget.roomId), (previous, next) {
      next.whenData((game) {
        final room = game.room;
        final currentTurnUid = room.currentTurnUid;

        // Check if turn changed to current user
        if (_previousTurnUid != currentTurnUid && currentTurnUid == userUid) {
          if (_previousTurnUid != null && userUid != null) {
            GameNotifications.setupGameNotifications(ref, room, userUid);
          }
        }
        _previousTurnUid = currentTurnUid;
      });
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

          // Check for new words to show round summary
          final prevWords = prevGame?.playedWords ?? [];
          final nextWords = game.playedWords;
          if (nextWords.length > prevWords.length) {
            final lastWord = nextWords.last;
            final player = game.room.playerNames[lastWord.byUid] ?? 'Oyuncu';

            // Check if it's my word
            final isMyWord = lastWord.byUid == userUid;
            if (isMyWord) {
              _confettiController.play();
              // Play success sound
              ref.read(soundManagerProvider).playSuccess();
            }

            // Show toast for round summary
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '$player: "${lastWord.word}" (+10 puan)',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                backgroundColor: Colors.green.shade700,
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          }

          if (isFinished && !wasFinished && !_gameEndDialogShown) {
            _gameEndDialogShown = true;

            // Play victory/game over sound
            final winner = game.room.winnerUid;
            final isWinner = winner == userUid;
            if (isWinner) {
              ref.read(soundManagerProvider).playVictory();
            }

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) {
                return;
              }
              final winner = game.room.winnerUid;

              // Get winner name from playerNames map
              final winnerName =
                  winner != null
                      ? (game.room.playerNames[winner] ?? winner)
                      : 'Berabere';

              // Prepare score summary
              final scores = game.computedScores;
              final sortedScores =
                  scores.entries.toList()
                    ..sort((a, b) => b.value.compareTo(a.value));

              final scoreSummary = sortedScores
                  .map((e) {
                    final name = game.room.playerNames[e.key] ?? 'Oyuncu';
                    final isWinner = e.key == winner;
                    return '${isWinner ? "🏆 " : ""}$name: ${e.value} puan';
                  })
                  .join('\n');

              showDialog<void>(
                context: context,
                barrierDismissible: false,
                builder:
                    (ctx) => SuccessAnimation(
                      child: AlertDialog(
                        title: const Text('Oyun bitti!'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              winner != null
                                  ? 'Kazanan: $winnerName'
                                  : 'Oyun berabere bitti!',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text('Skor Tablosu:'),
                            const SizedBox(height: 8),
                            Text(scoreSummary),
                          ],
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
            final timerOffset = timerState.asData?.value ?? Duration.zero;

            return Stack(
              children: [
                // Background image
                const GameBackground(),
                // Confetti
                Align(
                  alignment: Alignment.topCenter,
                  child: ConfettiWidget(
                    confettiController: _confettiController,
                    blastDirectionality: BlastDirectionality.explosive,
                    shouldLoop: false,
                    colors: const [
                      Colors.green,
                      Colors.blue,
                      Colors.pink,
                      Colors.orange,
                      Colors.purple,
                    ],
                  ),
                ),
                // Content with padding and semi-transparent white overlay
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header with countdown and player info
                      GameHeader(
                        room: game.room,
                        currentUserUid: userUid,
                        scores: game.computedScores,
                        serverOffset: timerOffset,
                        gameController: ref.read(
                          gameControllerProvider(widget.roomId).notifier,
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
                              game.room.currentTurnUid == userUid &&
                              game.room.status == RoomStatus.active,
                          currentWordType: game.room.currentWordType,
                          gameMode: game.room.gameMode,
                          settings: game.room.settings,
                          onWordSubmit: (word) async {
                            try {
                              final type = await ref
                                  .read(
                                    gameControllerProvider(
                                      widget.roomId,
                                    ).notifier,
                                  )
                                  .handleWordSubmission(word);

                              if (!mounted) return;

                              String message = 'Kelime gönderildi';
                              if (type == 'verb')
                                message = 'Fiil gönderildi, sıra rakibinde';
                              if (type == 'adjective')
                                message = 'Sıfat gönderildi, şimdi fiil yaz';

                              ref
                                  .read(notificationServiceProvider)
                                  .showSuccess(
                                    title: 'Başarılı',
                                    message: message,
                                  );
                            } catch (err) {
                              if (!mounted) return;
                              ref
                                  .read(notificationServiceProvider)
                                  .showError(
                                    title: 'Hata',
                                    message: err.toString().replaceAll(
                                      'Exception: ',
                                      '',
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
                  '• Tema Savaşı: Seçilen temayla ilgili bir kelime yaz.\n'
                  '• Core English: Seçilen türde (fiil/sıfat/isim/zarf) bir kelime yaz.\n'
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
