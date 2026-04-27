import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../logic/irregular_verbs_provider.dart';

class IrregularVerbsPracticePage extends ConsumerWidget {
  const IrregularVerbsPracticePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(practiceProvider);
    final notifier = ref.read(practiceProvider.notifier);

    if (state.currentVerb == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF050505),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final verb = state.currentVerb!;

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: SafeArea(
        child: Column(
          children: [
            // Top Progress Bar
            LinearProgressIndicator(
              value: state.total == 0 ? 0 : state.score / (state.score + state.remainingVerbs.length + 1),
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
              minHeight: 2,
            ),
            
            // Score Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white30),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Text(
                    'Score: ${state.score}',
                    style: const TextStyle(color: Colors.white60, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Question Section
            Column(
              children: [
                Text(
                  verb.v1,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  verb.meaningTr,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 60),

            // Answer Slots (Placeholders)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                children: [
                  _AnswerSlot(
                    label: 'V2',
                    value: state.selectedV2,
                    isCorrect: state.isV2Correct,
                    showGlow: state.showCorrectGlow,
                  ),
                  const SizedBox(width: 20),
                  _AnswerSlot(
                    label: 'V3',
                    value: state.selectedV3,
                    isCorrect: state.isV3Correct,
                    showGlow: state.showCorrectGlow,
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Options Section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: state.currentDistractors.map((option) {
                  final isWrong = state.wrongOptions.contains(option);
                  final isUsed = (state.selectedV2 == option && state.isV2Correct && verb.v2 != verb.v3) || 
                                 (state.selectedV3 == option && state.isV3Correct);
                  
                  return _OptionChip(
                    label: option,
                    isWrong: isWrong,
                    isUsed: isUsed,
                    onTap: () {
                      if (isUsed || isWrong) return;
                      
                      // Haptic Feedback before state update
                      if (verb.v2 == option || verb.v3 == option) {
                        HapticFeedback.lightImpact();
                      } else {
                        HapticFeedback.heavyImpact();
                      }
                      
                      notifier.selectOption(option);
                    },
                  );
                }).toList(),
              ),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _AnswerSlot extends StatelessWidget {
  final String label;
  final String? value;
  final bool isCorrect;
  final bool showGlow;

  const _AnswerSlot({
    required this.label,
    this.value,
    required this.isCorrect,
    required this.showGlow,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white24, fontSize: 12, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: showGlow 
                ? Colors.green.withOpacity(0.15) 
                : (isCorrect ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.04)),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: showGlow 
                  ? Colors.green.withOpacity(0.4) 
                  : (isCorrect ? Colors.white.withOpacity(0.2) : Colors.white.withOpacity(0.05)),
                width: isCorrect ? 2 : 1,
              ),
              boxShadow: showGlow ? [
                BoxShadow(
                  color: Colors.green.withOpacity(0.2),
                  blurRadius: 15,
                  spreadRadius: 2,
                )
              ] : [],
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: value != null 
                ? Text(
                    value!,
                    key: ValueKey(value),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                : Container(key: const ValueKey('empty'), width: 20, height: 2, color: Colors.white10),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionChip extends StatelessWidget {
  final String label;
  final bool isWrong;
  final bool isUsed;
  final VoidCallback onTap;

  const _OptionChip({
    required this.label,
    required this.isWrong,
    required this.isUsed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isUsed ? 0.0 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: isWrong ? Colors.red.withOpacity(0.2) : Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isWrong ? Colors.red.withOpacity(0.5) : Colors.white.withOpacity(0.05),
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isWrong ? Colors.red.shade200 : Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
