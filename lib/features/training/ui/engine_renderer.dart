import 'package:flutter/material.dart';
import '../models/training_models.dart';
import 'engines/engine_mcq.dart';
import 'engines/engine_fill.dart';
import 'engines/engine_tap.dart';
import 'engines/engine_order.dart';
import 'engines/engine_transform.dart';
import 'engines/engine_error_spot.dart';
import 'engines/engine_matching.dart';

class EngineRenderer extends StatelessWidget {
  final WorksheetItem item;
  final dynamic userAnswer;
  final ValueChanged<dynamic> onAnswerChanged;
  final bool isLocked;

  const EngineRenderer({
    super.key,
    required this.item,
    required this.userAnswer,
    required this.onAnswerChanged,
    required this.isLocked,
  });

  @override
  Widget build(BuildContext context) {
    switch (item.engine) {
      case EngineType.mcq:
        return EngineMcq(
          item: item,
          selected: userAnswer as String?,
          onChanged: (val) => onAnswerChanged(val),
          isLocked: isLocked,
        );
      case EngineType.fill:
        return EngineFill(
          item: item,
          currentText: userAnswer as String?,
          onChanged: (val) => onAnswerChanged(val),
          isLocked: isLocked,
        );
      case EngineType.tap:
        return EngineTap(
          item: item,
          selected: userAnswer as String?,
          onChanged: (val) => onAnswerChanged(val),
          isLocked: isLocked,
        );
      case EngineType.order:
        return EngineOrder(
          item: item,
          currentOrder:
              userAnswer is List ? List<String>.from(userAnswer) : null,
          onChanged: (val) => onAnswerChanged(val),
          isLocked: isLocked,
        );
      case EngineType.transform:
        // Ensure userAnswer is treated as List<String> or null
        final List<String>? transformAnswer =
            userAnswer is List
                ? List<String>.from(userAnswer)
                : (userAnswer is String
                    ? [userAnswer]
                    : null); // Fallback if somehow string

        return EngineTransform(
          item: item,
          currentAnswer: transformAnswer,
          onChanged: (val) => onAnswerChanged(val),
          isLocked: isLocked,
        );
      case EngineType.error_spotting:
        return EngineErrorSpot(
          item: item,
          currentAnswer: userAnswer as String?,
          onChanged: (val) => onAnswerChanged(val),
          isLocked: isLocked,
        );
      case EngineType.matching:
        return EngineMatching(
          item: item,
          currentMatches:
              userAnswer != null
                  ? Map<String, String>.from(userAnswer as Map)
                  : null,
          onChanged: (val) => onAnswerChanged(val),
          isLocked: isLocked,
        );
      default:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Unknown engine: ${item.engine}',
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Raw value: "${item.raw['engine']}"',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        );
    }
  }
}
