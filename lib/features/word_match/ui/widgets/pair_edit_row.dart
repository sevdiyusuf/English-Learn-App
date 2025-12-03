import 'package:flutter/material.dart';

class PairEditRow extends StatelessWidget {
  const PairEditRow({
    super.key,
    required this.index,
    required this.englishController,
    required this.turkishController,
    required this.onRemove,
    required this.onChanged,
  });

  final int index;
  final TextEditingController englishController;
  final TextEditingController turkishController;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Kelime ${index + 1}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Satırı sil',
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: englishController,
              decoration: const InputDecoration(
                labelText: 'İngilizce',
                hintText: 'leather',
              ),
              textCapitalization: TextCapitalization.none,
              onChanged: (_) => onChanged(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: turkishController,
              decoration: const InputDecoration(
                labelText: 'Türkçe',
                hintText: 'deri',
              ),
              onChanged: (_) => onChanged(),
            ),
          ],
        ),
      ),
    );
  }
}
