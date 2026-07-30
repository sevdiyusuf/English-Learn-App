import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:math';
import '../data/word_match_providers.dart';
import '../models/word_pair.dart';

class WordTestPage extends ConsumerStatefulWidget {
  const WordTestPage({super.key, required this.setId});

  static const routeName = 'wordTest';
  final int setId;

  @override
  ConsumerState<WordTestPage> createState() => _WordTestPageState();
}

class _WordTestPageState extends ConsumerState<WordTestPage> {
  List<_TestQuestion> _questions = [];
  int _currentIndex = 0;
  int _score = 0;
  bool _isLoading = true;
  bool _isFinished = false;
  int? _selectedOptionIndex;
  bool _showAnswer = false;

  @override
  void initState() {
    super.initState();
    _loadTestData();
  }

  Future<void> _loadTestData() async {
    final repo = await ref.read(wordMatchRepoProvider.future);
    final pairs = await repo.fetchPairs(widget.setId);

    if (pairs.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    // Karışık 20 soru seç (veya eldeki tüm kelimeler 20'den azsa hepsi)
    final random = Random();
    final shuffledPairs = List<WordPair>.from(pairs)..shuffle(random);
    final selectedPairs = shuffledPairs.take(20).toList();

    final List<_TestQuestion> questions = [];
    for (var pair in selectedPairs) {
      // 3 yanlış şık bul (diğer tüm kelimeler arasından)
      final otherPairs = pairs.where((p) => p.id != pair.id).toList();
      otherPairs.shuffle(random);

      final wrongOptions = otherPairs.take(3).map((p) => p.turkish).toList();
      // Eğer yeterli yanlış şık yoksa (set çok küçükse), placeholder ekle
      while (wrongOptions.length < 3) {
        wrongOptions.add('...');
      }

      final options = [pair.turkish, ...wrongOptions];
      options.shuffle(random);

      questions.add(
        _TestQuestion(
          english: pair.english,
          correctTurkish: pair.turkish,
          options: options,
        ),
      );
    }

    if (mounted) {
      setState(() {
        _questions = questions;
        _isLoading = false;
      });
    }
  }

  void _handleOptionTap(int index) {
    if (_showAnswer) return;

    setState(() {
      _selectedOptionIndex = index;
      _showAnswer = true;
      if (_questions[_currentIndex].options[index] ==
          _questions[_currentIndex].correctTurkish) {
        _score++;
      }
    });

    // 1.5 saniye sonra sonraki soruya geç
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      if (_currentIndex < _questions.length - 1) {
        setState(() {
          _currentIndex++;
          _selectedOptionIndex = null;
          _showAnswer = false;
        });
      } else {
        setState(() {
          _isFinished = true;
        });
        // İstatistikleri güncelle (opsiyonel)
        _recordResult();
      }
    });
  }

  Future<void> _recordResult() async {
    final repo = await ref.read(wordMatchRepoProvider.future);
    await repo.recordPractice(widget.setId);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(
          child: CircularProgressIndicator(color: Colors.blueAccent),
        ),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(
          child: Text(
            'Bu sette henüz kelime yok.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    if (_isFinished) {
      return _buildResultView();
    }

    final question = _questions[_currentIndex];

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Column(
          children: [
            Text(
              'SORU ${_currentIndex + 1} / ${_questions.length}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                width: 120,
                height: 6,
                child: LinearProgressIndicator(
                  value: (_currentIndex + 1) / _questions.length,
                  backgroundColor: Colors.white10,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF26A69A),
                  ),
                ),
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Soru Kartı
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Text(
                question.english,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 48),
            // Şıklar
            ...List.generate(question.options.length, (index) {
              final option = question.options[index];
              final isSelected = _selectedOptionIndex == index;
              final isCorrect = option == question.correctTurkish;

              Color bgColor = const Color(0xFF1E293B);
              Color textColor = Colors.white;
              Color borderColor = Colors.white.withValues(alpha: 0.1);

              if (_showAnswer) {
                if (isCorrect) {
                  bgColor = Colors.green.withValues(alpha: 0.2);
                  borderColor = Colors.greenAccent;
                } else if (isSelected) {
                  bgColor = Colors.red.withValues(alpha: 0.2);
                  borderColor = Colors.redAccent;
                }
              } else if (isSelected) {
                borderColor = Colors.blueAccent;
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: InkWell(
                  onTap: () => _handleOptionTap(index),
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 24,
                    ),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor, width: 2),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          option,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_showAnswer && isCorrect)
                          const Icon(
                            Icons.check_circle,
                            color: Colors.greenAccent,
                          )
                        else if (_showAnswer && isSelected && !isCorrect)
                          const Icon(Icons.cancel, color: Colors.redAccent),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildResultView() {
    final percent = (_score / _questions.length * 100).round();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.emoji_events, color: Colors.amber, size: 80),
              const SizedBox(height: 24),
              const Text(
                'Test Tamamlandı!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '%$percent Başarı',
                style: TextStyle(
                  color:
                      percent > 70 ? Colors.greenAccent : Colors.orangeAccent,
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$_score doğru / ${_questions.length} soru',
                style: const TextStyle(color: Colors.white70, fontSize: 18),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Kapat',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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
}

class _TestQuestion {
  final String english;
  final String correctTurkish;
  final List<String> options;

  _TestQuestion({
    required this.english,
    required this.correctTurkish,
    required this.options,
  });
}
