import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Configuration for Word Echo Personal Echo feature
class WordEchoConfig {
  const WordEchoConfig({this.selectedWordSetId});

  final int? selectedWordSetId;

  WordEchoConfig copyWith({int? selectedWordSetId}) {
    return WordEchoConfig(
      selectedWordSetId: selectedWordSetId ?? this.selectedWordSetId,
    );
  }

  bool get isPersonalEchoActive => selectedWordSetId != null;
}

class WordEchoConfigController extends StateNotifier<WordEchoConfig> {
  WordEchoConfigController() : super(const WordEchoConfig());

  void selectWordSet(int? wordSetId) {
    state = state.copyWith(selectedWordSetId: wordSetId);
  }

  void clearSelection() {
    state = const WordEchoConfig();
  }
}

final wordEchoConfigProvider =
    StateNotifierProvider<WordEchoConfigController, WordEchoConfig>((ref) {
  return WordEchoConfigController();
});

