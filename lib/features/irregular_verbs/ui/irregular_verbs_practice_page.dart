import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../logic/irregular_verbs_provider.dart';

class IrregularVerbsPracticePage extends ConsumerWidget {
  const IrregularVerbsPracticePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(practiceProvider);

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
              value:
                  state.total == 0
                      ? 0
                      : state.score /
                          (state.score + state.remainingVerbs.length + 1),
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Colors.blueAccent,
              ),
              minHeight: 2,
            ),

            // Score Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white30,
                    ),
                    onPressed:
                        () => GoRouter.of(context).go('/irregular-verbs'),
                  ),
                  Text(
                    'Score: ${state.score}',
                    style: const TextStyle(
                      color: Colors.white60,
                      fontWeight: FontWeight.bold,
                    ),
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
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Answer Slots
            Row(
              children: [
                _buildSlot(
                  'V2 (Past)',
                  state.selectedV2,
                  state.isV2Correct,
                  state.showCorrectGlow,
                ),
                const SizedBox(width: 16),
                _buildSlot(
                  'V3 (Past Participle)',
                  state.selectedV3,
                  state.isV3Correct,
                  state.showCorrectGlow,
                ),
              ],
            ),

            const Spacer(),

            // Distractor Options
            Center(
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children:
                    state.currentDistractors.map((option) {
                      final isWrong = state.wrongOptions.contains(option);
                      final isUsed =
                          state.selectedV2 == option ||
                          state.selectedV3 == option;

                      return _OptionChip(
                        label: option,
                        isWrong: isWrong,
                        isUsed: isUsed,
                        onTap: () {
                          ref
                              .read(practiceProvider.notifier)
                              .selectOption(option);
                        },
                      );
                    }).toList(),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSlot(
    String title,
    String? value,
    bool isCorrect,
    bool showGlow,
  ) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color:
                  showGlow
                      ? Colors.green.withValues(alpha: 0.15)
                      : (isCorrect
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.white.withValues(alpha: 0.04)),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:
                    showGlow
                        ? Colors.green.withValues(alpha: 0.4)
                        : (isCorrect
                            ? Colors.white.withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.05)),
                width: isCorrect ? 2 : 1,
              ),
              boxShadow:
                  showGlow
                      ? [
                        BoxShadow(
                          color: Colors.green.withValues(alpha: 0.2),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ]
                      : [],
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child:
                  value != null
                      ? Text(
                        value,
                        key: ValueKey(value),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      )
                      : Container(
                        key: const ValueKey('empty'),
                        width: 20,
                        height: 2,
                        color: Colors.white10,
                      ),
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
            color:
                isWrong
                    ? Colors.red.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  isWrong
                      ? Colors.red.withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: 0.05),
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
