import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../logic/training_controller.dart';
import '../models/training_models.dart';
import '../data/subject_summaries_data.dart';
import 'worksheet_page.dart';
import '../../grammar/logic/grammar_providers.dart';

class TrainingHomePage extends ConsumerStatefulWidget {
  static const routeName = 'training_home';
  final bool showAppBar;

  const TrainingHomePage({super.key, this.showAppBar = true});

  @override
  ConsumerState<TrainingHomePage> createState() => _TrainingHomePageState();
}

class _TrainingHomePageState extends ConsumerState<TrainingHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _levels = ['A1', 'A2', 'B1', 'B2', 'Tense'];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _levels.length,
      vsync: this,
      initialIndex: 1, // Start at A2 (index 1)
    );
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Color _getLevelColor(String level) {
    switch (level) {
      case 'A1':
        return AppColors.success;
      case 'A2':
        return AppColors.warning;
      case 'B1':
        return Colors.blue;
      case 'B2':
        return Colors.purple;
      case 'Tense':
        return Colors.orange;
      default:
        return AppColors.primary;
    }
  }

  void _showLearnTrainSelectionSheet(
    BuildContext context,
    WorksheetMetadata ws,
    List<WorksheetMetadata> allWorksheets,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceMedium,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final lessonIndexAsync = ref.watch(lessonIndexProvider);
            return lessonIndexAsync.when(
              data: (index) {
                // Find if there is a lesson for this worksheet
                String? lessonId;
                for (var levelLessons in index.lessonsByLevel.values) {
                  for (var entry in levelLessons) {
                    // Check for exact ID match or if the trainWorksheetId exactly matches
                    if (entry.trainWorksheetId == ws.worksheetId ||
                        entry.lessonId == ws.worksheetId) {
                      lessonId = entry.lessonId;
                      break;
                    }
                  }
                  if (lessonId != null) break;
                }

                final summary = subjectSummaries[ws.worksheetId];
                final worksheetCount = summary?.worksheetIds.length ?? 0;

                return SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          ws.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: _SelectionCard(
                                title: 'Learn',
                                subtitle: 'Mikro Ders',
                                icon: Icons.school,
                                color: Colors.blue,
                                isEnabled: lessonId != null,
                                onTap: () {
                                  Navigator.pop(context);
                                  context.push('/grammar/learn/$lessonId');
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _SelectionCard(
                                title: 'Train',
                                subtitle: 'Pratik Yap',
                                icon: Icons.fitness_center,
                                color: AppColors.primary,
                                topLabel:
                                    worksheetCount > 1
                                        ? '$worksheetCount set'
                                        : null,
                                onTap: () {
                                  Navigator.pop(context);
                                  if (summary != null &&
                                      summary.worksheetIds.length > 1) {
                                    _showWorksheetSelectionSheet(
                                      context,
                                      summary,
                                      allWorksheets,
                                    );
                                  } else {
                                    context.goNamed(
                                      WorksheetPage.routeName,
                                      queryParameters: {'path': ws.path},
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading:
                  () => const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  ),
              error:
                  (_, __) => const SizedBox(
                    height: 200,
                    child: Center(child: Text('Error loading lessons')),
                  ),
            );
          },
        );
      },
    );
  }

  void _showWorksheetSelectionSheet(
    BuildContext context,
    SubjectSummary summary,
    List<WorksheetMetadata> levelWorksheets,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceMedium,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.library_books,
                      color: AppColors.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        summary.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children:
                          summary.worksheetIds.asMap().entries.map((entry) {
                            final index = entry.key;
                            final id = entry.value;
                            final ws = levelWorksheets.firstWhere(
                              (w) => w.worksheetId == id,
                              orElse:
                                  () => WorksheetMetadata(
                                    worksheetId: id,
                                    title: id,
                                    path: '',
                                    tags: [],
                                    level: '',
                                  ),
                            );

                            if (ws.path.isEmpty) return const SizedBox.shrink();

                            // Title is already cleaned in repository
                            final cleanTitle = ws.title;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.textSecondary.withValues(
                                    alpha: 0.1,
                                  ),
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                leading: Container(
                                  width: 36,
                                  height: 36,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.primary,
                                      width: 2,
                                    ),
                                  ),
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  cleanTitle.isNotEmpty ? cleanTitle : ws.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                trailing:
                                    ws.bestScore != null
                                        ? Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.success.withValues(
                                              alpha: 0.2,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: AppColors.success,
                                            ),
                                          ),
                                          child: Text(
                                            '%${ws.bestScore}',
                                            style: const TextStyle(
                                              color: AppColors.success,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        )
                                        : const Icon(
                                          Icons.arrow_forward_ios,
                                          color: Colors.white54,
                                          size: 16,
                                        ),
                                onTap: () {
                                  Navigator.pop(context);
                                  context.goNamed(
                                    WorksheetPage.routeName,
                                    queryParameters: {'path': ws.path},
                                  );
                                },
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final indexAsync = ref.watch(trainingIndexProvider);

    final content = indexAsync.when(
      data: (data) {
        if (_searchQuery.isNotEmpty) {
          final allWorksheets = data.values.expand((x) => x).toList();
          final filtered =
              allWorksheets.where((ws) {
                final summary = subjectSummaries[ws.worksheetId];
                if (summary != null && summary.worksheetIds.isNotEmpty) {
                  if (summary.worksheetIds.first != ws.worksheetId) {
                    return false;
                  }
                }
                return ws.title.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                    ws.tags.any(
                      (tag) => tag.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ),
                    );
              }).toList();

          if (filtered.isEmpty) {
            return const Center(
              child: Text(
                'No results found',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final ws = filtered[index];
              return _WorksheetCard(
                worksheet: ws,
                color: _getLevelColor(ws.level),
                onTap: () {
                  _showLearnTrainSelectionSheet(
                    context,
                    ws,
                    data[ws.level] ?? [],
                  );
                },
              );
            },
          );
        }

        return TabBarView(
          controller: _tabController,
          children:
              _levels.map((level) {
                if (level == 'Tense') {
                  // All worksheets that are tenses
                  final allWorksheets = data.values.expand((x) => x).toList();
                  final tenseWorksheets =
                      allWorksheets.where((ws) {
                        final title = ws.title.toLowerCase();
                        final tags = ws.tags.map((t) => t.toLowerCase());

                        // Genişletilmiş zaman anahtar kelimeleri
                        final tenseKeywords = [
                          'tense',
                          'present simple',
                          'present continuous',
                          'past simple',
                          'past continuous',
                          'present perfect',
                          'past perfect',
                          'future simple',
                          'going to',
                          'will',
                          'continuous',
                          'perfect',
                        ];

                        return title.contains('tense') ||
                            tenseKeywords.any((k) => title.contains(k)) ||
                            tags.any(
                              (t) =>
                                  t.contains('tense') ||
                                  tenseKeywords.any((k) => t.contains(k)),
                            );
                      }).toList();

                  return _TrainingLevelTab(
                    allWorksheets: tenseWorksheets,
                    level: 'Tense',
                    levelColor: _getLevelColor('Tense'),
                    onWorksheetTap: (ws, _) {
                      _showLearnTrainSelectionSheet(
                        context,
                        ws,
                        tenseWorksheets,
                      );
                    },
                    useOriginalLevelColors: true, // Yeni parametre
                  );
                }

                final levelWorksheets = data[level] ?? [];
                return _TrainingLevelTab(
                  allWorksheets: levelWorksheets,
                  level: level,
                  levelColor: _getLevelColor(level),
                  onWorksheetTap: (ws, worksheets) {
                    _showLearnTrainSelectionSheet(context, ws, worksheets);
                  },
                );
              }).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (err, stack) => Center(
            child: Text(
              'Error: $err',
              style: const TextStyle(color: Colors.white),
            ),
          ),
    );

    if (!widget.showAppBar) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search worksheets...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () => _searchController.clear(),
                        )
                        : null,
                filled: true,
                fillColor: AppColors.surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              ),
            ),
          ),
          TabBar(
            controller: _tabController,
            indicatorColor: AppColors.primary,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
            tabs: _levels.map((level) => Tab(text: level)).toList(),
          ),
          Expanded(child: content),
        ],
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Training', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton.icon(
              onPressed: () => context.push('/multiplayer/grammar-arena'),
              icon: const Icon(Icons.people, color: Colors.white, size: 20),
              label: const Text(
                'Arkadaşla Oyna',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search worksheets...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon:
                        _searchQuery.isNotEmpty
                            ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () => _searchController.clear(),
                            )
                            : null,
                    filled: true,
                    fillColor: AppColors.surfaceLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                ),
              ),
              TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey,
                tabs: _levels.map((level) => Tab(text: level)).toList(),
              ),
            ],
          ),
        ),
      ),
      body: content,
    );
  }
}

class _WorksheetCard extends StatelessWidget {
  final WorksheetMetadata worksheet;
  final Color color;
  final VoidCallback onTap;
  final int? orderNumber;

  const _WorksheetCard({
    required this.worksheet,
    required this.color,
    required this.onTap,
    this.orderNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surfaceMedium,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.5), width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (orderNumber != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$orderNumber.',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        if (orderNumber != null) const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            worksheet.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      if (worksheet.bestScore != null) ...[
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.success.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(
                                    Icons.check_circle,
                                    color: AppColors.success,
                                    size: 14,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Done',
                                    style: TextStyle(
                                      color: AppColors.success,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '%${worksheet.bestScore}',
                                style: const TextStyle(
                                  color: AppColors.success,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: color),
                        ),
                        child: Text(
                          worksheet.level,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children:
                    worksheet.tags
                        .map(
                          (tag) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              tag,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        )
                        .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isEnabled;
  final String? topLabel;

  const _SelectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isEnabled = true,
    this.topLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color:
          isEnabled
              ? AppColors.surfaceLight
              : AppColors.surfaceLight.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color:
              isEnabled
                  ? color.withValues(alpha: 0.5)
                  : Colors.grey.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 24,
                child:
                    topLabel != null
                        ? Center(
                          child: Text(
                            topLabel!,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isEnabled ? Colors.white70 : Colors.grey,
                            ),
                          ),
                        )
                        : const SizedBox.shrink(),
              ),
              const SizedBox(height: 8),
              Icon(icon, size: 40, color: isEnabled ? color : Colors.grey),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isEnabled ? Colors.white : Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isEnabled ? subtitle : 'Yakında',
                style: TextStyle(
                  fontSize: 12,
                  color: isEnabled ? Colors.white70 : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrainingLevelTab extends StatefulWidget {
  // This class remains as a StatefulWidget to use AutomaticKeepAliveClientMixin
  final List<WorksheetMetadata> allWorksheets;
  final String level;
  final Color levelColor;
  final Function(WorksheetMetadata, List<WorksheetMetadata>) onWorksheetTap;
  final bool useOriginalLevelColors;

  const _TrainingLevelTab({
    required this.allWorksheets,
    required this.level,
    required this.levelColor,
    required this.onWorksheetTap,
    this.useOriginalLevelColors = false,
  });

  @override
  State<_TrainingLevelTab> createState() => _TrainingLevelTabState();
}

class _TrainingLevelTabState extends State<_TrainingLevelTab>
    with AutomaticKeepAliveClientMixin {
  static const List<String> _a1Order = [
    'A1-TOBE-01',
    'A1-ART-01',
    'A1-CAN-01',
    'A1-CU-01',
    'A1-POSS-01',
    'A1-PREP-01',
    'A1-PS-PC-01',
    'A1-QUEST-01',
    'A1-THERE-01',
    'A1-ADV-01',
  ];

  static const List<String> _a2Order = [
    'A2-COMP-01',
    'A2-FUTURE-01',
    'A2-ING-01',
    'A2-PP-01',
    'A2-PS-PC-01',
    'A2-PP-PS-01',
    'A2-PPC-01',
    'A2-QUANT-01',
    'A2-REL-01',
    'A2-MOD-01',
    'A2-MAN-01',
  ];

  static const List<String> _b1Order = [
    'B1-PASSIVE-01',
    'B1-MODALS-01',
    'B1-REPORTED-01',
    'B1-COND-01',
    'B1-COND-02',
    'B1-GER-01',
    'B1-FUT-01',
    'B1-PPC-PS-01',
    'B1-USED-01',
  ];

  static const List<String> _b2Order = [
    'B2-PASSIVE-02',
    'B2-REPORTED-01',
    'B2-COND-01',
    'B2-REL-01',
    'B2-VERB-01',
    'B2-PMOD-01',
    'B2-WISH-01',
    'B2-INV-01',
    'B2-LINK-01',
    'B2-CAUS-01',
    'B2-PART-01',
    'B2-FIP-01',
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Must call super

    if (widget.allWorksheets.isEmpty) {
      return const Center(
        child: Text(
          'No worksheets found',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    // Filter to show only primary worksheets
    final visibleWorksheets =
        widget.allWorksheets.where((ws) {
          final summary = subjectSummaries[ws.worksheetId];
          // If no summary or no worksheetIds, show it
          if (summary == null || summary.worksheetIds.isEmpty) {
            return true;
          }
          // Only show if it matches the first ID in the list
          return summary.worksheetIds.first == ws.worksheetId;
        }).toList();

    visibleWorksheets.sort((a, b) {
      final aOrder = _getLearningOrderIndex(a);
      final bOrder = _getLearningOrderIndex(b);
      if (aOrder != bOrder) {
        return aOrder.compareTo(bOrder);
      }
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: visibleWorksheets.length,
      itemBuilder: (context, index) {
        final ws = visibleWorksheets[index];
        // Tense sekmesi için orijinal seviye rengini kullan
        final cardColor =
            widget.useOriginalLevelColors
                ? _getLevelColorFromTab(ws.level)
                : widget.levelColor;

        return _WorksheetCard(
          worksheet: ws,
          color: cardColor,
          orderNumber: index + 1,
          onTap: () => widget.onWorksheetTap(ws, widget.allWorksheets),
        );
      },
    );
  }

  // Yardımcı fonksiyon: _TrainingHomePageState içindeki metodu taklit eder
  Color _getLevelColorFromTab(String level) {
    switch (level) {
      case 'A1':
        return const Color(0xFF4CAF50); // AppColors.success
      case 'A2':
        return const Color(0xFFFFC107); // AppColors.warning
      case 'B1':
        return Colors.blue;
      case 'B2':
        return Colors.purple;
      default:
        return const Color(0xFF6366F1); // AppColors.primary
    }
  }

  int _getLearningOrderIndex(WorksheetMetadata ws) {
    List<String> order;
    switch (ws.level) {
      case 'A1':
        order = _a1Order;
        break;
      case 'A2':
        order = _a2Order;
        break;
      case 'B1':
        order = _b1Order;
        break;
      case 'B2':
        order = _b2Order;
        break;
      default:
        return 1000;
    }
    final index = order.indexOf(ws.worksheetId);
    if (index == -1) {
      return 1000;
    }
    return index;
  }
}
