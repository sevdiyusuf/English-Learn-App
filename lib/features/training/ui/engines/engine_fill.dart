import 'package:flutter/material.dart';
import '../../models/training_models.dart';
import '../../../../core/theme/app_colors.dart';

class EngineFill extends StatefulWidget {
  final WorksheetItem item;
  final String? currentText;
  final ValueChanged<String> onChanged;
  final bool isLocked;

  const EngineFill({
    super.key,
    required this.item,
    required this.currentText,
    required this.onChanged,
    required this.isLocked,
  });

  @override
  State<EngineFill> createState() => _EngineFillState();
}

class _EngineFillState extends State<EngineFill> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentText);
    _controller.addListener(() {
      widget.onChanged(_controller.text);
    });
  }

  @override
  void didUpdateWidget(covariant EngineFill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentText != _controller.text) {
      // Only update if different to avoid cursor jumping,
      // but here currentText is driven by parent which is driven by us, so it should be fine.
      // However, if parent resets (next question), we need to update.
      // If parent passes null (new question), we clear.
      if (widget.currentText == null) {
        _controller.clear();
      } else {
        // If locked, we definitely want to show what's passed
        if (widget.isLocked && widget.currentText != _controller.text) {
          _controller.text = widget.currentText!;
        }
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If locked, determine color
    Color? fillColor = AppColors.surfaceMedium;
    Color borderColor = AppColors.surfaceLight;

    if (widget.isLocked) {
      // We don't know if it is correct here directly unless we check against answer again
      // or pass isCorrect from parent.
      // But we can check loosely or just rely on parent's feedback panel.
      // Actually, standard is: Input field shows user input.
      // If we want to colorize the input field itself based on correctness:
      // We can re-validate or pass `isCorrect` to EngineRenderer -> EngineFill.
      // For now, let's keep it simple: neutral or disabled style.
      fillColor = AppColors.surfaceLight.withValues(alpha: 0.5);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceMedium,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            widget.item.prompt,
            style: const TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _controller,
          enabled: !widget.isLocked,
          style: const TextStyle(color: Colors.white, fontSize: 18),
          decoration: InputDecoration(
            filled: true,
            fillColor: fillColor,
            hintText: 'Type your answer...',
            hintStyle: const TextStyle(color: Colors.white30),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor.withValues(alpha: 0.3)),
            ),
          ),
          onSubmitted: (_) {
            // Optional: trigger submit if we had access to controller
          },
        ),
        if (widget.isLocked &&
            widget.item.translation != null &&
            widget.item.translation!.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'Çeviri:',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.item.translation!,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
            ),
          ),
        ],
      ],
    );
  }
}
