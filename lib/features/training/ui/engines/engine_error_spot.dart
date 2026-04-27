import 'package:flutter/material.dart';
import '../../models/training_models.dart';
import '../../../../core/theme/app_colors.dart';

class EngineErrorSpot extends StatefulWidget {
  final WorksheetItem item;
  final String? currentAnswer;
  final ValueChanged<String> onChanged;
  final bool isLocked;

  const EngineErrorSpot({
    super.key,
    required this.item,
    required this.currentAnswer,
    required this.onChanged,
    required this.isLocked,
  });

  @override
  State<EngineErrorSpot> createState() => _EngineErrorSpotState();
}

class _EngineErrorSpotState extends State<EngineErrorSpot> {
  late TextEditingController _controller;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentAnswer ?? widget.item.prompt);
  }

  @override
  void didUpdateWidget(covariant EngineErrorSpot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentAnswer != oldWidget.currentAnswer &&
        widget.currentAnswer != _controller.text) {
      _controller.text = widget.currentAnswer ?? widget.item.prompt;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCorrect = widget.isLocked && (widget.currentAnswer?.trim() == widget.item.answer);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.item.hint != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              widget.item.hint!,
              style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
            ),
          ),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isLocked
                  ? (isCorrect ? AppColors.success : AppColors.error)
                  : (_isEditing ? AppColors.primary : Colors.transparent),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              if (!_isEditing && !widget.isLocked)
                InkWell(
                  onTap: () {
                    setState(() {
                      _isEditing = true;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        const Icon(Icons.edit, color: Colors.white54, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.currentAnswer ?? widget.item.prompt,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                TextField(
                  controller: _controller,
                  enabled: !widget.isLocked,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Type the correct sentence...',
                    hintStyle: TextStyle(color: Colors.white30),
                  ),
                  maxLines: null,
                  onChanged: (val) {
                    widget.onChanged(val);
                  },
                ),
            ],
          ),
        ),
        
        if (widget.isLocked && !isCorrect) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.success.withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Correct Answer:',
                  style: TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.item.answer.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                if (widget.item.translation != null &&
                    widget.item.translation!.isNotEmpty) ...[
                  const SizedBox(height: 8),
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
            ),
          ),
        ],
      ],
    );
  }
}
