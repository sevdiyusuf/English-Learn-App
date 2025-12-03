import 'package:flutter/material.dart';

class WordBox extends StatelessWidget {
  const WordBox({
    required this.english,
    required this.turkish,
    super.key,
  });

  final String english;
  final String turkish;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF8B6F47), // Brown box color
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.brown.shade800,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          english,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

