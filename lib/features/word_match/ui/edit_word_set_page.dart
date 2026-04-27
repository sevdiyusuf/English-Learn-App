import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../data/word_match_providers.dart';
import '../data/word_match_repo_interface.dart';
import '../logic/word_match_sync_service.dart';
import '../models/word_pair.dart';
import '../models/word_set.dart';
import 'word_match_set_detail_page.dart';
import 'widgets/pair_edit_row.dart';

class WordSetDetail {
  WordSetDetail({required this.set, required this.pairs});

  final WordSet set;
  final List<WordPair> pairs;
}

final wordSetDetailProvider = FutureProvider.autoDispose
    .family<WordSetDetail, int>((ref, setId) async {
      final repo = await ref.watch(wordMatchRepoProvider.future);
      final set = await repo.getSet(setId);
      if (set == null) {
        throw StateError('Set bulunamadı');
      }
      final pairs = await repo.fetchPairs(setId);
      return WordSetDetail(set: set, pairs: pairs);
    });

class EditWordSetPage extends ConsumerStatefulWidget {
  const EditWordSetPage({super.key, required this.setId});

  static const routeName = 'editWordSet';

  final int setId;

  @override
  ConsumerState<EditWordSetPage> createState() => _EditWordSetPageState();
}

class _EditWordSetPageState extends ConsumerState<EditWordSetPage> {
  final _nameController = TextEditingController();
  final List<_PairControllers> _rows = [];
  bool _initialized = false;
  bool _isSaving = false;

  // Yeni kelime ekleme için sabit input alanları
  final _newEnglishController = TextEditingController();
  final _newTurkishController = TextEditingController();
  final _newEnglishFocus = FocusNode();
  final _newTurkishFocus = FocusNode();
  bool _showSuccessAnimation = false;

  @override
  void dispose() {
    _nameController.dispose();
    _newEnglishController.dispose();
    _newTurkishController.dispose();
    _newEnglishFocus.dispose();
    _newTurkishFocus.dispose();
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(wordSetDetailProvider(widget.setId));

    detailAsync.whenData(_ensureInitialized);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final detail = detailAsync.valueOrNull;
          // "Words from Games" seti düzenlenebilir olmalı
          final isEditable =
              detail != null &&
              (!detail.set.isBuiltin || detail.set.name == 'Words from Games');
          if (isEditable) {
            // Değişiklik var mı kontrol et
            final hasChanges =
                _nameController.text.trim() != detail.set.name ||
                _rows.length != detail.pairs.length ||
                _rows.any((row) {
                  final pair = detail.pairs.firstWhere(
                    (p) => p.id == row.id,
                    orElse:
                        () =>
                            WordPair()
                              ..english = ''
                              ..turkish = '',
                  );
                  return row.english.text.trim() != pair.english ||
                      row.turkish.text.trim() != pair.turkish;
                });
            if (hasChanges) {
              // Kaydet ve sonra çık
              await _save(detailAsync);
            }
          }
          if (context.mounted) {
            context.go('/word-match/sets');
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Kelime Setini Düzenle',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, size: 28),
            onPressed: () async {
              final detail = detailAsync.valueOrNull;
              // "Words from Games" seti düzenlenebilir olmalı
              final isEditable =
                  detail != null &&
                  (!detail.set.isBuiltin ||
                      detail.set.name == 'Words from Games');
              if (isEditable) {
                // Değişiklik var mı kontrol et
                final hasChanges =
                    _nameController.text.trim() != detail.set.name ||
                    _rows.length != detail.pairs.length ||
                    _rows.any((row) {
                      final pair = detail.pairs.firstWhere(
                        (p) => p.id == row.id,
                        orElse:
                            () =>
                                WordPair()
                                  ..english = ''
                                  ..turkish = '',
                      );
                      return row.english.text.trim() != pair.english ||
                          row.turkish.text.trim() != pair.turkish;
                    });
                if (hasChanges) {
                  // Kaydet ve sonra çık
                  await _save(detailAsync);
                }
              }
              if (context.mounted) {
                context.go('/word-match/sets');
              }
            },
            tooltip: 'Set listesine dön',
          ),
          actions: [
            IconButton(
              icon:
                  _isSaving
                      ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                      : const Icon(Icons.check, size: 28),
              onPressed:
                  _isSaving
                      ? null
                      : () async {
                        final detail = detailAsync.valueOrNull;
                        // "Words from Games" seti düzenlenebilir olmalı
                        final isEditable =
                            detail != null &&
                            (!detail.set.isBuiltin ||
                                detail.set.name == 'Words from Games');
                        if (!isEditable) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Yerleşik setler düzenlenemez'),
                            ),
                          );
                          return;
                        }
                        await _save(detailAsync);
                      },
              tooltip: 'Kaydet',
            ),
          ],
        ),
        // FloatingActionButton kaldırıldı - artık üstte sabit input alanı var
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        body: GradientBackground(
          child: SafeArea(
            child: detailAsync.when(
              data:
                  (detail) =>
                      (detail.set.isBuiltin &&
                              detail.set.name != 'Words from Games')
                          ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.lock_outline, size: 64),
                                const SizedBox(height: 16),
                                const Text(
                                  'Yerleşik setler düzenlenemez',
                                  style: TextStyle(fontSize: 18),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Bu seti görüntüleyebilir ve eşleştirme oyunu olarak oynayabilirsiniz.',
                                ),
                                const SizedBox(height: 24),
                                FilledButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    Navigator.of(context).pushNamed(
                                      '/word-match/practice/${detail.set.id}',
                                    );
                                  },
                                  icon: const Icon(Icons.play_arrow),
                                  label: const Text('Eşleştirmeye Başla'),
                                ),
                              ],
                            ),
                          )
                          : _buildForm(),
              loading: () => const Center(child: CircularProgressIndicator()),
              error:
                  (error, stackTrace) =>
                      Center(child: Text('Sayfa yüklenemedi: $error')),
            ),
          ),
        ),
      ),
    );
  }

  void _ensureInitialized(WordSetDetail detail) {
    if (_initialized) {
      return;
    }
    _initialized = true;
    _nameController.text = detail.set.name;
    // Mevcut kelimeleri yükle
    for (final pair in detail.pairs) {
      _rows.add(_PairControllers.fromPair(pair, onChanged: _markDirty));
    }
    setState(() {});
  }

  Widget _buildForm() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Set adı',
              hintText: 'Ünite 5 Fiiller',
            ),
            onChanged: (_) => _markDirty(),
          ),
          const SizedBox(height: 16),
          // Sabit yeni kelime ekleme alanı
          _buildNewWordInput(),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _rows.length,
              itemBuilder: (context, index) {
                final row = _rows[index];
                return PairEditRow(
                  index: index,
                  englishController: row.english,
                  turkishController: row.turkish,
                  onChanged: _markDirty,
                  onRemove: () {
                    setState(() => _rows.removeAt(index));
                    if (_rows.isEmpty) {
                      _rows.add(_PairControllers.empty(onChanged: _markDirty));
                    }
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 72),
        ],
      ),
    );
  }

  Widget _buildNewWordInput() {
    return Card(
      color: AppColors.surfaceDark.withValues(alpha: 0.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Yeni Kelime Ekle',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_showSuccessAnimation)
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 300),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 28 * value,
                        ),
                      );
                    },
                    onEnd: () {
                      Future.delayed(const Duration(milliseconds: 500), () {
                        if (mounted) {
                          setState(() => _showSuccessAnimation = false);
                        }
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newEnglishController,
                    focusNode: _newEnglishFocus,
                    decoration: const InputDecoration(
                      labelText: 'İngilizce',
                      hintText: 'hello',
                      filled: true,
                    ),
                    textCapitalization: TextCapitalization.none,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) {
                      _newTurkishFocus.requestFocus();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _newTurkishController,
                    focusNode: _newTurkishFocus,
                    decoration: const InputDecoration(
                      labelText: 'Türkçe',
                      hintText: 'merhaba',
                      filled: true,
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) {
                      _addNewWord();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _addNewWord,
                icon: const Icon(Icons.add_circle),
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Kelime Ekle'),
                    const SizedBox(width: 8),
                    SvgPicture.asset(
                      'assets/icons/add.svg',
                      width: 20,
                      height: 20,
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                    ),
                  ],
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addNewWord() {
    final english = _newEnglishController.text.trim();
    if (english.isEmpty) {
      _newEnglishFocus.requestFocus();
      return;
    }

    if (_rows.length >= WordMatchRepoInterface.maxPairsPerSet) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Bir sette en fazla ${WordMatchRepoInterface.maxPairsPerSet} kelime çifti olabilir.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _rows.add(
        _PairControllers._(
          0,
          TextEditingController(text: english),
          TextEditingController(text: _newTurkishController.text.trim()),
          _markDirty,
        ),
      );
      _showSuccessAnimation = true;
    });

    // Input alanlarını temizle ve İngilizce alanına odaklan
    _newEnglishController.clear();
    _newTurkishController.clear();
    _newEnglishFocus.requestFocus();
    _markDirty();
  }

  Future<void> _save(AsyncValue<WordSetDetail> detailAsync) async {
    final detail = detailAsync.valueOrNull;
    if (detail == null) {
      return;
    }
    final validRows = _rows
        .where((row) => row.english.text.trim().isNotEmpty)
        .toList(growable: false);
    if (validRows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('En az bir İngilizce kelime girin.')),
      );
      return;
    }
    final repo = await ref.read(wordMatchRepoProvider.future);
    setState(() => _isSaving = true);
    try {
      final pairs = validRows
          .map(
            (row) =>
                WordPair()
                  ..id =
                      row
                          .id // Mevcut ID'yi koru (yeni pair'ler için 0)
                  ..setId = widget.setId
                  ..english = row.english.text.trim()
                  ..turkish = row.turkish.text.trim(),
          )
          .toList(growable: false);
      await repo.savePairs(
        setId: widget.setId,
        setName: _nameController.text,
        pairs: pairs,
      );

      // Trigger sync
      try {
        final syncService = await ref.read(wordMatchSyncProvider.future);
        await syncService.syncSet(widget.setId);
      } catch (e) {
        debugPrint('Sync failed after savePairs: $e');
      }

      // Invalidate all related providers to refresh UI in both edit and detail pages
      ref.invalidate(wordSetDetailProvider(widget.setId));
      // Import and invalidate detail page providers
      ref.invalidate(wordMatchPairsProvider(widget.setId));
      ref.invalidate(wordMatchLearnedStatusesProvider(widget.setId));
      ref.invalidate(wordMatchSetProvider(widget.setId));
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Set kaydedildi')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kaydedilirken hata oluştu: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _markDirty() {
    // reserved for future dirty state handling
  }
}

class _PairControllers {
  _PairControllers._(this.id, this.english, this.turkish, this.onChanged);

  factory _PairControllers.empty({required VoidCallback onChanged}) {
    return _PairControllers._(
      0, // Yeni pair için 0 (repo'da yeni ID atanacak)
      TextEditingController(),
      TextEditingController(),
      onChanged,
    );
  }

  factory _PairControllers.fromPair(
    WordPair pair, {
    required VoidCallback onChanged,
  }) {
    return _PairControllers._(
      pair.id, // Mevcut pair'in ID'sini koru
      TextEditingController(text: pair.english),
      TextEditingController(text: pair.turkish),
      onChanged,
    );
  }

  final int id; // Pair ID'sini sakla
  final TextEditingController english;
  final TextEditingController turkish;
  final VoidCallback onChanged;

  void dispose() {
    english.dispose();
    turkish.dispose();
  }
}
