import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/logic/auth_controller.dart';
import '../../moderation/moderation_actions.dart';
import '../data/word_match_share_repo.dart';

class SharedWordSetPage extends ConsumerStatefulWidget {
  const SharedWordSetPage({super.key, required this.shareId});

  static const routeName = 'sharedWordSet';

  final String shareId;

  @override
  ConsumerState<SharedWordSetPage> createState() => _SharedWordSetPageState();
}

class _SharedWordSetPageState extends ConsumerState<SharedWordSetPage> {
  bool _isImporting = false;

  @override
  Widget build(BuildContext context) {
    final repoAsync = ref.watch(wordMatchShareRepositoryProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark.withValues(alpha: 0.9),
        title: const Text('Paylaşılan Set'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/word-match/sets'),
        ),
      ),
      body: GradientBackground(
        child: SafeArea(
          child: repoAsync.when(
            data: (repo) => _buildActualContent(repo),
            error: (err, stack) {
              return Scaffold(
                backgroundColor: Colors.black,
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.storage_rounded,
                          color: Colors.orange,
                          size: 54,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "Veritabanı Bağlantısı Yok",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Paylaşılan seti görüntüleyebilirsiniz ancak içe aktarma şu an yapılamaz.\nHata detayı: $err",
                          style: const TextStyle(color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            loading:
                () => const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        "Paylaşım linki kontrol ediliyor...",
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildActualContent(dynamic repo) {
    return FutureBuilder<SharedWordSet?>(
      future: repo.getSharedSet(widget.shareId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Paylaşım yüklenemedi: ${snapshot.error}',
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        final shared = snapshot.data;
        if (shared == null) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Bu paylaşım bulunamadı veya süresi dolmuş olabilir.',
                style: TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final previewPairs = shared.pairs.take(3).toList();
        final l10n = AppLocalizations.of(context)!;
        final isOwner = ref.watch(authControllerProvider).value?.uid == shared.ownerUid;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: isOwner
                    ? TextButton.icon(
                        onPressed: () => _confirmRemove(shared, l10n),
                        icon: const Icon(Icons.delete_outline),
                        label: Text(l10n.removeSharedSet),
                      )
                    : TextButton.icon(
                        onPressed: () => showReportDialog(context, ref, type: 'share', targetId: shared.shareId, title: l10n.reportSharedSet),
                        icon: const Icon(Icons.flag_outlined),
                        label: Text(l10n.report),
                      ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shared.setName,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Paylaşılan seti hesabına içe aktarabilir ve istediğin gibi düzenleyebilirsin.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (previewPairs.isNotEmpty) ...[
                Text(
                  'Örnek kelimeler',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                ...previewPairs.map(
                  (p) => Card(
                    color: AppColors.surfaceDark.withValues(alpha: 0.95),
                    child: ListTile(
                      title: Text(
                        p.front,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        p.back,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ),
                ),
                if (shared.pairs.length > previewPairs.length)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '+ ${shared.pairs.length - previewPairs.length} kelime daha',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed:
                      _isImporting
                          ? null
                          : () async {
                            await _importSharedSet(shared);
                          },
                  icon:
                      _isImporting
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Icon(Icons.download),
                  label: Text(
                    _isImporting ? 'İçe aktarılıyor...' : 'Seti içe aktar',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _importSharedSet(SharedWordSet shared) async {
    setState(() => _isImporting = true);
    try {
      // Ensure we have at least an anonymous user
      final repo = await ref.read(wordMatchShareRepositoryProvider.future);
      final newSetId = await repo.importSharedSetToLocal(shared: shared);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Set kelime listene eklendi')),
      );

      context.go('/word-match/edit/$newSetId');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Set içe aktarılamadı: $e')));
      setState(() => _isImporting = false);
    }
  }

  Future<void> _confirmRemove(SharedWordSet shared, AppLocalizations l10n) async {
    final remove = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: Text(l10n.removeSharedSet), content: Text(l10n.removeSharedSetPrompt), actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.remove)),
      ],
    ));
    if (remove != true || !mounted) return;
    try {
      final repo = await ref.read(wordMatchShareRepositoryProvider.future);
      await repo.removeShare(shared.shareId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.sharedSetRemoved)));
      context.go('/word-match/sets');
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
    }
  }
}
