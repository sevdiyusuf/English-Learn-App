import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/logic/auth_controller.dart';
import '../logic/arena_session_controller.dart';
import '../models/arena_models.dart';

class ArenaResultPage extends ConsumerWidget {
  final String roomId;
  const ArenaResultPage({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(arenaSessionControllerProvider(roomId));
    final currentUser = ref.watch(authControllerProvider).value;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.surfaceDark, AppColors.background],
          ),
        ),
        child: sessionAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
          data: (state) {
            if (state.room == null) {
              return const Center(child: Text('Room not found'));
            }

            final room = state.room!;
            final isHost = currentUser?.uid == room.hostId;
            final myScore = isHost ? room.hostScore : room.guestScore;
            final opponentScore = isHost ? room.guestScore : room.hostScore;

            final isWinner = myScore > opponentScore;
            final isDraw = myScore == opponentScore;

            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isDraw ? 'BERABERE!' : (isWinner ? 'ZAFER!' : 'YENİLGİ'),
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color:
                          isDraw
                              ? Colors.white
                              : (isWinner
                                  ? AppColors.success
                                  : AppColors.error),
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Scores
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildScoreCard('SEN', myScore, isWinner),
                      const SizedBox(width: 32),
                      const Text(
                        'VS',
                        style: TextStyle(
                          color: Colors.white24,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 32),
                      _buildScoreCard(
                        'RAKİP',
                        opponentScore,
                        !isWinner && !isDraw,
                      ),
                    ],
                  ),

                  const SizedBox(height: 64),

                  ElevatedButton(
                    onPressed: () => context.go('/multiplayer/grammar-arena'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'ANA SAYFAYA DÖN',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildScoreCard(String label, int score, bool isWinner) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isWinner ? AppColors.primary : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              if (isWinner)
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Text(
            '$score',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
