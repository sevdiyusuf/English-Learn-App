import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../logic/irregular_verbs_provider.dart';
import '../models/irregular_verb.dart';

class IrregularVerbsTutorialPage extends ConsumerStatefulWidget {
  const IrregularVerbsTutorialPage({super.key});

  @override
  ConsumerState<IrregularVerbsTutorialPage> createState() => _IrregularVerbsTutorialPageState();
}

class _IrregularVerbsTutorialPageState extends ConsumerState<IrregularVerbsTutorialPage> {
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);
  }

  Future<void> _speak(String text) async {
    await _flutterTts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    final verbsAsync = ref.watch(irregularVerbsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Tutorial Mode'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: verbsAsync.when(
        data: (verbs) {
          final groups = _groupVerbs(verbs);
          final groupKeys = groups.keys.toList();

          return PageView.builder(
            itemCount: groupKeys.length,
            itemBuilder: (context, index) {
              final key = groupKeys[index];
              final groupVerbs = groups[key]!;
              return _GroupView(
                title: key,
                verbs: groupVerbs,
                onSpeak: _speak,
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Map<String, List<IrregularVerb>> _groupVerbs(List<IrregularVerb> verbs) {
    final Map<String, List<IrregularVerb>> groups = {};
    for (var verb in verbs) {
      final desc = verb.patternDescription;
      if (!groups.containsKey(desc)) {
        groups[desc] = [];
      }
      groups[desc]!.add(verb);
    }
    return groups;
  }
}

class _GroupView extends StatelessWidget {
  final String title;
  final List<IrregularVerb> verbs;
  final Function(String) onSpeak;

  const _GroupView({
    required this.title,
    required this.verbs,
    required this.onSpeak,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.blueAccent,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: verbs.length,
            itemBuilder: (context, index) {
              final verb = verbs[index];
              return _VerbBentoCard(verb: verb, onSpeak: onSpeak);
            },
          ),
        ),
      ],
    );
  }
}

class _VerbBentoCard extends StatelessWidget {
  final IrregularVerb verb;
  final Function(String) onSpeak;

  const _VerbBentoCard({required this.verb, required this.onSpeak});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                verb.meaningTr,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.volume_up_rounded, color: Colors.white30),
                onPressed: () => onSpeak('${verb.v1}, ${verb.v2}, ${verb.v3}'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _FormColumn(label: 'V1', value: verb.v1, onSpeak: onSpeak),
              _FormColumn(label: 'V2', value: verb.v2, onSpeak: onSpeak),
              _FormColumn(label: 'V3', value: verb.v3, onSpeak: onSpeak),
            ],
          ),
        ],
      ),
    );
  }
}

class _FormColumn extends StatelessWidget {
  final String label;
  final String value;
  final Function(String) onSpeak;

  const _FormColumn({required this.label, required this.value, required this.onSpeak});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onSpeak(value),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
