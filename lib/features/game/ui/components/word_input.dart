import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/input_validator.dart';

class WordInput extends StatefulWidget {
  const WordInput({
    super.key,
    required this.enabled,
    required this.onWordSubmit,
    this.currentWordType, // 'verb' or 'adjective' from room
  });

  final bool enabled;
  final Future<void> Function(String word) onWordSubmit;
  final String? currentWordType; // Track server-side word type

  @override
  State<WordInput> createState() => _WordInputState();
}

class _WordInputState extends State<WordInput> {
  final _wordController = TextEditingController();
  bool _isSubmitting = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    // Reset state when enabled changes (new turn)
    if (!widget.enabled) {
      _resetState();
    }
    // Listen to text changes for button state
    _wordController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasText = _wordController.text.trim().isNotEmpty;
    if (_hasText != hasText) {
      setState(() => _hasText = hasText);
    }
  }

  @override
  void didUpdateWidget(WordInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset when turn becomes enabled (new turn started)
    if (!oldWidget.enabled && widget.enabled) {
      // New turn started - reset everything including submitting flag
      setState(() {
        _resetState();
      });
    }
    // Also reset if enabled was true and becomes false (turn ended)
    if (oldWidget.enabled && !widget.enabled) {
      // Turn ended - clear submission state
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _resetState() {
    _wordController.clear();
    _hasText = false;
    _isSubmitting = false;
  }

  @override
  void dispose() {
    _wordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!widget.enabled || _isSubmitting) {
      return;
    }
    final rawWord = _wordController.text;
    final word = rawWord.trim();
    
    if (word.isEmpty || !_hasText) {
      return;
    }
    
    // Validate input
    final validationError = InputValidator.validateWord(word);
    if (validationError != null) {
      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(validationError),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    
    // Sanitize word before submission
    final sanitizedWord = InputValidator.sanitizeWord(word);
    
    // Prevent double submission
    if (_isSubmitting) return;
    
    setState(() => _isSubmitting = true);
    try {
      await widget.onWordSubmit(sanitizedWord);
      // Reset state after successful submission
      if (mounted) {
        setState(() {
          _resetState();
        });
      }
    } catch (e) {
      // On error, keep the state so user can retry
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _wordController,
            enabled: widget.enabled && !_isSubmitting,
            decoration: InputDecoration(
              hintText: 'Cevap yaz...',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
              filled: true,
              fillColor: AppColors.surfaceDark.withValues(alpha: 0.9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            textInputAction: TextInputAction.send,
            onFieldSubmitted: (_) {
              _handleSubmit();
            },
            style: const TextStyle(color: Colors.white),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceDark.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: (widget.enabled &&
                      !_isSubmitting &&
                      _hasText)
                  ? _handleSubmit
                  : null,
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Cevapla',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
