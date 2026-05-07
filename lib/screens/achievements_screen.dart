// achievements_screen.dart: Achievement gallery screen (#136)
//
// Shows all achievements grouped by category with progress indicators
// for locked achievements and unlock dates for unlocked ones. Tapping
// a tile opens a detail modal with full info and the achievement quote.
//
// Cross-ref:
//   - Navigated to from screens/calendar_screen.dart (trophy button)
//   - Achievement definitions: constants/achievements.dart
//   - Combined model: models/achievement_models.dart (Achievement)
//   - Resolver + logic: services/achievement_service.dart
//   - Database: services/database.dart
//   - Layout constants: constants/layout.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../app.dart';
import '../constants/achievements.dart';
import '../constants/layout.dart';
import '../models/achievement_models.dart';
import '../services/achievement_service.dart';
import '../services/database.dart';

/// Achievement gallery screen — shows all achievements grouped by category.
class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  /// Whether an AchievementsScreen instance is currently mounted.
  /// Used by CalendarScreen's toast "View" button to decide whether to
  /// push a new screen or scroll within the existing one.
  static bool isMounted = false;

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  late AppDatabase _database;
  bool _initialized = false;
  bool _isLoading = true;

  List<Achievement> _achievements = [];

  /// GlobalKeys for each achievement tile, keyed by achievement ID.
  /// Used by [_scrollToAchievement] to locate tiles in the scroll view.
  final Map<String, GlobalKey> _achievementKeys = {
    for (final achievement in allAchievements) achievement.id: GlobalKey(),
  };

  @override
  void initState() {
    super.initState();
    AchievementsScreen.isMounted = true;
    achievementScrollToNotifier.addListener(_onScrollToRequested);
  }

  @override
  void dispose() {
    AchievementsScreen.isMounted = false;
    achievementScrollToNotifier.removeListener(_onScrollToRequested);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _database = context.read<AppDatabase>();
      _initialized = true;
      _loadData();
    }
  }

  Future<void> _loadData() async {
    try {
      await AchievementService.retroactiveScan(_database);
      final achievements = await AchievementService.resolveAll(_database);

      if (mounted) {
        setState(() {
          _achievements = achievements;
          _isLoading = false;
        });

        final scrollTarget = achievementScrollToNotifier.value;
        if (scrollTarget.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToAchievement(scrollTarget);
            achievementScrollToNotifier.value = '';
          });
        }
      }
    } catch (error) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load achievements: $error')),
        );
      }
    }
  }

  /// Called when [achievementScrollToNotifier] fires while the screen is open.
  void _onScrollToRequested() {
    final achievementId = achievementScrollToNotifier.value;
    if (achievementId.isEmpty || !mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToAchievement(achievementId);
      achievementScrollToNotifier.value = '';
    });
  }

  /// Scrolls the view so that the achievement tile with [achievementId]
  /// is visible on screen.
  void _scrollToAchievement(String achievementId) {
    final key = _achievementKeys[achievementId];
    if (key?.currentContext == null) return;

    Scrollable.ensureVisible(
      key!.currentContext!,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      alignment: 0.3,
    );
  }

  /// Groups the resolved achievements by category for sectioned display.
  Map<AchievementCategory, List<Achievement>> get _grouped {
    final map = <AchievementCategory, List<Achievement>>{};
    for (final achievement in _achievements) {
      map.putIfAbsent(achievement.category, () => []).add(achievement);
    }
    return map;
  }

  int get _unlockedCount =>
      _achievements.where((achievement) => achievement.isUnlocked).length;

  /// Whether the achievement's name and description should be fully hidden.
  /// Secret achievements show "???" when locked — unless they have an
  /// [unlockedName], in which case they show their regular name while locked.
  bool _isHidden(Achievement achievement) {
    return achievement.category == AchievementCategory.secret &&
        !achievement.isUnlocked &&
        achievement.unlockedName == null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
      ),
      body: SafeArea(
        top: false,
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    final grouped = _grouped;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverviewCard(),
          const SizedBox(height: spacingLg),
          for (final category in AchievementCategory.values) ...[
            if (grouped[category] != null && grouped[category]!.isNotEmpty) ...[
              _buildSectionHeader(category),
              const SizedBox(height: spacingSm),
              _buildAchievementList(grouped[category]!),
              const SizedBox(height: spacingLg),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildOverviewCard() {
    final fraction = totalAchievementCount > 0
        ? _unlockedCount / totalAchievementCount
        : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$_unlockedCount of $totalAchievementCount unlocked',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: spacingMd),
            ClipRRect(
              borderRadius: BorderRadius.circular(spacingXs),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: spacingSm,
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(AchievementCategory category) {
    return Row(
      children: [
        Icon(category.icon,
            size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: spacingSm),
        Text(category.label, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }

  Widget _buildAchievementList(List<Achievement> achievements) {
    return Card(
      child: Column(
        children: [
          for (int index = 0; index < achievements.length; index++) ...[
            _buildAchievementTile(achievements[index]),
            if (index < achievements.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }

  Widget _buildAchievementTile(Achievement achievement) {
    final hidden = _isHidden(achievement);
    final dateFormat = DateFormat.yMMMd();

    return ListTile(
      key: _achievementKeys[achievement.id],
      onTap: hidden ? null : () => _showAchievementDetail(achievement),
      leading: Icon(
        achievement.category.icon,
        color: achievement.isUnlocked
            ? Colors.amber
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      title: Text(
        hidden ? '???' : achievement.displayName,
        style: TextStyle(
          fontWeight:
              achievement.isUnlocked ? FontWeight.bold : FontWeight.normal,
          color: hidden
              ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)
              : null,
        ),
      ),
      subtitle: achievement.isUnlocked
          ? Text('Unlocked ${dateFormat.format(achievement.unlockedAt!)}')
          : hidden
              ? Text(
                  'Keep exploring...',
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.38),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(achievement.description),
                    const SizedBox(height: spacingXs),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: achievement.progress,
                        minHeight: spacingXs,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                      ),
                    ),
                  ],
                ),
      trailing: achievement.isUnlocked
          ? const Icon(Icons.emoji_events, color: Colors.amber)
          : hidden
              ? null
              : _buildProgressText(achievement),
    );
  }

  void _showAchievementDetail(Achievement achievement) {
    final dateFormat = DateFormat.yMMMd();

    showAdaptiveDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog.adaptive(
          title: Row(
            children: [
              Icon(
                achievement.category.icon,
                color: achievement.isUnlocked ? Colors.amber : null,
                size: 24,
              ),
              const SizedBox(width: spacingSm),
              Expanded(child: Text(achievement.displayName)),
              if (achievement.isUnlocked)
                const Icon(Icons.emoji_events, color: Colors.amber),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                achievement.category.label,
                style: Theme.of(dialogContext).textTheme.labelMedium?.copyWith(
                      color:
                          Theme.of(dialogContext).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: spacingSm),
              Text(achievement.description),
              const SizedBox(height: spacingMd),
              if (achievement.isUnlocked) ...[
                Text(
                  'Unlocked ${dateFormat.format(achievement.unlockedAt!)}',
                  style: Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(dialogContext)
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: spacingMd),
                Text(
                  achievement.quote,
                  style: Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: Theme.of(dialogContext)
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                ),
              ] else ...[
                _buildDetailProgress(dialogContext, achievement),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailProgress(
    BuildContext dialogContext,
    Achievement achievement,
  ) {
    final currentValue = (achievement.progress * achievement.threshold).round();
    final showCounter = achievement.category != AchievementCategory.usage ||
        achievement.id == 'usage_mood_explorer';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showCounter)
          Text(
            'Progress: $currentValue / ${achievement.threshold}',
            style: Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(dialogContext).colorScheme.onSurfaceVariant,
                ),
          ),
        if (showCounter) const SizedBox(height: spacingSm),
        ClipRRect(
          borderRadius: BorderRadius.circular(spacingXs),
          child: LinearProgressIndicator(
            value: achievement.progress,
            minHeight: spacingSm,
            backgroundColor:
                Theme.of(dialogContext).colorScheme.surfaceContainerHighest,
          ),
        ),
      ],
    );
  }

  Widget? _buildProgressText(Achievement achievement) {
    if (achievement.category == AchievementCategory.usage &&
        achievement.id != 'usage_mood_explorer') {
      return null;
    }

    if (achievement.category == AchievementCategory.secret) {
      return null;
    }

    final currentValue = (achievement.progress * achievement.threshold).round();
    return Text(
      '$currentValue/${achievement.threshold}',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
    );
  }
}
