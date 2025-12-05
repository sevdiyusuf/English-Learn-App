import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/cargo_categories_state.dart';

class ScoreDialog extends StatefulWidget {
  const ScoreDialog({
    required this.score,
    required this.correctCount,
    required this.wrongCount,
    required this.missedCount,
    required this.elapsedTime,
    required this.difficulty,
    required this.selectedCategories,
    required this.onPlayAgain,
    required this.onBack,
    required this.onToggleTranslate,
    super.key,
  });

  final int score;
  final int correctCount;
  final int wrongCount;
  final int missedCount;
  final Duration elapsedTime;
  final Difficulty? difficulty;
  final List<String> selectedCategories;
  final VoidCallback onPlayAgain;
  final VoidCallback onBack;
  final VoidCallback onToggleTranslate;

  @override
  State<ScoreDialog> createState() => _ScoreDialogState();
}

class _ScoreDialogState extends State<ScoreDialog> {
  void _handleToggleTranslate() {
    widget.onToggleTranslate();
    // Force rebuild of this dialog to reflect the change
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Get screen height and constrain dialog to 40% of screen
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = screenHeight * 0.4;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withValues(alpha: 0.90),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(30),
              ),
              border: Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 30,
                  offset: const Offset(0, -10),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 1. Tutamaç (Handle Bar)
                      Container(
                        width: 48,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),

                      // 2. Ana Başlık ve Skor Kartı
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Arka plan: Sol ve Sağ öğeler
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Sol Taraf: Tebrik Mesajı
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Tebrikler!',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      widget.difficulty?.displayName ??
                                          'Oyun Bitti',
                                      style: TextStyle(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.8,
                                        ),
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Sağ Taraf: Skor Göstergesi
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primary,
                                      const Color(0xFF2C3E50),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'SKOR',
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.7,
                                        ),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    Text(
                                      '${widget.score}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900,
                                        height: 1.1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          // Orta: Çevir Butonu (Tam Ortada)
                          OutlinedButton(
                            onPressed: _handleToggleTranslate,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text(
                              'Çevir',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // 3. İstatistikler Paneli (Kompakt Grid)
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildVerticalStat(
                              icon: Icons.check_circle_rounded,
                              color: AppColors.success,
                              value: '${widget.correctCount}',
                              label: 'Doğru',
                            ),
                            _buildDivider(),
                            _buildVerticalStat(
                              icon: Icons.cancel_rounded,
                              color: AppColors.error,
                              value: '${widget.wrongCount}',
                              label: 'Yanlış',
                            ),
                            _buildDivider(),
                            _buildVerticalStat(
                              icon: Icons.timer_rounded,
                              color: Colors.amber,
                              value: _formatDuration(widget.elapsedTime),
                              label: 'Süre',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // 4. Aksiyon Butonları
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: widget.onBack,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                foregroundColor: Colors.white,
                              ),
                              child: const Text(
                                'Çıkış',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: FilledButton(
                              onPressed: widget.onPlayAgain,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                shadowColor: AppColors.primary.withValues(
                                  alpha: 0.4,
                                ),
                                elevation: 8,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.replay_rounded, size: 22),
                                  SizedBox(width: 8),
                                  Text(
                                    'Tekrar Oyna',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerticalStat({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.white.withValues(alpha: 0.1),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
