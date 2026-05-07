// achievement_service.dart: Achievement checking and unlock logic (#136)
//
// Evaluates whether achievements should be unlocked based on current data.
// Definitions live in constants/achievements.dart; unlock state is persisted
// in the UnlockedAchievements table via services/database.dart.
//
// Cross-ref:
//   - Achievement definitions: constants/achievements.dart
//   - DB helpers: services/database.dart (achievement tracking section)
//   - Triggered from: screens/entry_screen.dart (after save),
//     screens/settings/export_data_screen.dart (after export)
//   - Retroactive scan: main.dart (first launch after update)
//   - Toast notifier: app.dart (achievementUnlockedNotifier)

import 'package:shared_preferences/shared_preferences.dart';

import '../constants/achievements.dart';
import '../constants/defaults.dart';
import '../models/achievement_models.dart';
import 'database.dart';

/// Static service for checking and unlocking achievements.
///
/// All methods are static — no instance state. The database stores unlock
/// state; this service only contains the checking logic.
class AchievementService {
  // ---------------------------------------------------------------------------
  // Incremental checks (called after specific user actions)
  // ---------------------------------------------------------------------------

  /// Checks milestone, streak, time-of-day, diverse tracker, weekend warrior,
  /// mood explorer, note, and tag achievements after saving an entry.
  ///
  /// Returns a list of newly unlocked achievement IDs (empty if none).
  static Future<List<String>> checkAfterSave(
    AppDatabase database, {
    required DateTime entryDateTime,
    required int symptomCount,
    required bool hasNote,
    required bool hasTags,
  }) async {
    final newlyUnlocked = <String>[];

    // Load all unlocked IDs upfront to avoid per-achievement DB lookups.
    final alreadyUnlocked = (await database.getUnlockedAchievements())
        .map((item) => item.achievementId)
        .toSet();

    // If everything is already unlocked, skip all checks.
    if (alreadyUnlocked.length >= totalAchievementCount) return newlyUnlocked;

    // Milestone achievements — only query entry count if any are still locked.
    final lockedMilestones = allAchievements.where((achievement) =>
        achievement.category == AchievementCategory.milestone &&
        !alreadyUnlocked.contains(achievement.id));
    if (lockedMilestones.isNotEmpty) {
      final totalEntries = await database.getTotalEntryCount();
      for (final achievement in lockedMilestones) {
        if (totalEntries >= achievement.threshold) {
          await database.unlockAchievement(achievement.id, totalEntries);
          newlyUnlocked.add(achievement.id);
        }
      }
    }

    // Streak, weekend warrior, and missed-day all need entry dates.
    final lockedStreaks = allAchievements.where((achievement) =>
        achievement.category == AchievementCategory.streak &&
        !alreadyUnlocked.contains(achievement.id));
    final needsWeekendCheck =
        !alreadyUnlocked.contains('usage_weekend_warrior') &&
            (entryDateTime.weekday == DateTime.saturday ||
                entryDateTime.weekday == DateTime.sunday);
    final needsMissedDayCheck = !alreadyUnlocked.contains('usage_missed_day');

    List<DateTime>? dates;
    if (lockedStreaks.isNotEmpty || needsWeekendCheck || needsMissedDayCheck) {
      dates = await database.getAllEntryDates();
    }

    if (lockedStreaks.isNotEmpty && dates != null) {
      final currentStreak = computeCurrentStreak(dates);
      for (final achievement in lockedStreaks) {
        if (currentStreak >= achievement.threshold) {
          await database.unlockAchievement(achievement.id, currentStreak);
          newlyUnlocked.add(achievement.id);
        }
      }
    }

    // Night Owl: entry between midnight and 5 AM
    final hour = entryDateTime.hour;
    if (hour >= 0 && hour < 5 && !alreadyUnlocked.contains('usage_night_owl')) {
      await database.unlockAchievement('usage_night_owl', 1);
      newlyUnlocked.add('usage_night_owl');
    }

    // Early Bird: entry between 5 AM and 8 AM
    if (hour >= 5 &&
        hour < 8 &&
        !alreadyUnlocked.contains('usage_early_bird')) {
      await database.unlockAchievement('usage_early_bird', 1);
      newlyUnlocked.add('usage_early_bird');
    }

    // Diverse Tracker: 5+ symptoms in a single entry
    if (symptomCount >= 5 &&
        !alreadyUnlocked.contains('usage_diverse_tracker')) {
      await database.unlockAchievement('usage_diverse_tracker', symptomCount);
      newlyUnlocked.add('usage_diverse_tracker');
    }

    // Mood Explorer: 5+ distinct moods — only query if still locked.
    if (!alreadyUnlocked.contains('usage_mood_explorer')) {
      final distinctMoods = await database.getDistinctMoodCount();
      if (distinctMoods >= 5) {
        await database.unlockAchievement('usage_mood_explorer', distinctMoods);
        newlyUnlocked.add('usage_mood_explorer');
      }
    }

    // Weekend Warrior: Saturday and Sunday entries in the same ISO week
    if (needsWeekendCheck && dates != null) {
      final weekday = entryDateTime.weekday;
      final otherDay =
          weekday == DateTime.saturday ? DateTime.sunday : DateTime.saturday;

      final hasOtherDay = dates.any((date) =>
          date.weekday == otherDay && _isSameIsoWeek(date, entryDateTime));

      if (hasOtherDay) {
        await database.unlockAchievement('usage_weekend_warrior', 1);
        newlyUnlocked.add('usage_weekend_warrior');
      }
    }

    // Only Human: missed a day after a streak of 2+ days
    if (needsMissedDayCheck && dates != null) {
      if (_hasMissedDayAfterStreak(dates)) {
        await database.unlockAchievement('usage_missed_day', 1);
        newlyUnlocked.add('usage_missed_day');
      }
    }

    // First note
    if (hasNote && !alreadyUnlocked.contains('usage_first_note')) {
      await database.unlockAchievement('usage_first_note', 1);
      newlyUnlocked.add('usage_first_note');
    }

    // First tag
    if (hasTags && !alreadyUnlocked.contains('usage_first_tag')) {
      await database.unlockAchievement('usage_first_tag', 1);
      newlyUnlocked.add('usage_first_tag');
    }

    return newlyUnlocked;
  }

  /// Unlocks the summary view achievement when the user opens the summary screen.
  static Future<List<String>> checkAfterSummaryView(
    AppDatabase database,
  ) async {
    if (!await database.isAchievementUnlocked('usage_first_summary')) {
      await database.unlockAchievement('usage_first_summary', 1);
      return ['usage_first_summary'];
    }
    return [];
  }

  /// Unlocks the easter egg achievement.
  static Future<List<String>> checkAfterEasterEgg(
    AppDatabase database,
  ) async {
    if (!await database.isAchievementUnlocked('usage_easter_egg')) {
      await database.unlockAchievement('usage_easter_egg', 1);
      return ['usage_easter_egg'];
    }
    return [];
  }

  /// Unlocks the pin achievement when the user pins a symptom or tag.
  static Future<List<String>> checkAfterPin(AppDatabase database) async {
    if (!await database.isAchievementUnlocked('usage_first_pin')) {
      await database.unlockAchievement('usage_first_pin', 1);
      return ['usage_first_pin'];
    }
    return [];
  }

  /// Unlocks the hide achievement when the user hides a symptom or tag.
  static Future<List<String>> checkAfterHide(AppDatabase database) async {
    if (!await database.isAchievementUnlocked('usage_first_hide')) {
      await database.unlockAchievement('usage_first_hide', 1);
      return ['usage_first_hide'];
    }
    return [];
  }

  /// Unlocks the feedback achievement when the user sends feedback.
  static Future<List<String>> checkAfterFeedback(AppDatabase database) async {
    if (!await database.isAchievementUnlocked('usage_first_feedback')) {
      await database.unlockAchievement('usage_first_feedback', 1);
      return ['usage_first_feedback'];
    }
    return [];
  }

  /// Unlocks the shake feedback achievement when the user opens
  /// feedback via shake gesture.
  static Future<List<String>> checkAfterShakeFeedback(
    AppDatabase database,
  ) async {
    if (!await database.isAchievementUnlocked('usage_shake_feedback')) {
      await database.unlockAchievement('usage_shake_feedback', 1);
      return ['usage_shake_feedback'];
    }
    return [];
  }

  /// Checks the custom symptom achievement after adding a new symptom.
  static Future<List<String>> checkAfterCustomSymptomAdd(
    AppDatabase database,
  ) async {
    if (!await database.isAchievementUnlocked('usage_first_custom_symptom')) {
      final customSymptoms = await database.getCustomSymptoms();
      if (customSymptoms.isNotEmpty) {
        await database.unlockAchievement('usage_first_custom_symptom', 1);
        return ['usage_first_custom_symptom'];
      }
    }
    return [];
  }

  /// Unlocks the export achievement after a successful data export.
  static Future<List<String>> checkAfterExport(AppDatabase database) async {
    if (!await database.isAchievementUnlocked('usage_first_export')) {
      await database.unlockAchievement('usage_first_export', 1);
      return ['usage_first_export'];
    }
    return [];
  }

  // ---------------------------------------------------------------------------
  // Streak computation (pure functions, testable without DB)
  // ---------------------------------------------------------------------------

  /// Computes the current consecutive streak ending at the most recent date.
  ///
  /// Walks backward from the last date — each date must be exactly 1 day
  /// before the next to continue the streak.
  static int computeCurrentStreak(List<DateTime> sortedDates) {
    if (sortedDates.isEmpty) return 0;

    final uniqueDates = _deduplicateDates(sortedDates);
    if (uniqueDates.isEmpty) return 0;

    int streak = 1;
    for (int index = uniqueDates.length - 1; index > 0; index--) {
      final current = uniqueDates[index];
      final previous = uniqueDates[index - 1];
      if (current.difference(previous).inDays == 1) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  /// Computes the longest consecutive streak anywhere in the date list.
  /// Used by the retroactive scan (historical streaks may be longer than
  /// the current one).
  static int computeLongestStreak(List<DateTime> sortedDates) {
    if (sortedDates.isEmpty) return 0;

    final uniqueDates = _deduplicateDates(sortedDates);
    if (uniqueDates.isEmpty) return 0;

    int longest = 1;
    int current = 1;
    for (int index = 1; index < uniqueDates.length; index++) {
      if (uniqueDates[index].difference(uniqueDates[index - 1]).inDays == 1) {
        current++;
        if (current > longest) longest = current;
      } else {
        current = 1;
      }
    }
    return longest;
  }

  /// Removes duplicate dates and sorts ascending.
  static List<DateTime> _deduplicateDates(List<DateTime> dates) {
    final seen = <int>{};
    final unique = <DateTime>[];
    for (final date in dates) {
      final normalized = DateTime(date.year, date.month, date.day);
      final key = normalized.millisecondsSinceEpoch;
      if (seen.add(key)) {
        unique.add(normalized);
      }
    }
    unique.sort();
    return unique;
  }

  // ---------------------------------------------------------------------------
  // Retroactive scan (one-time on first launch after update)
  // ---------------------------------------------------------------------------

  /// Scans all existing data and batch-unlocks any earned achievements.
  ///
  /// Does NOT return IDs or trigger toasts — retroactive unlocks are silent.
  /// The user discovers them when they open the Achievements screen.
  static Future<void> retroactiveScan(AppDatabase database) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(prefKeyAchievementsScanned) ?? false) return;

    final batch = <({String id, int progress, DateTime unlockedAt})>[];
    final now = DateTime.now();

    // Milestone achievements
    final totalEntries = await database.getTotalEntryCount();
    for (final achievement in allAchievements) {
      if (achievement.category != AchievementCategory.milestone &&
          achievement.id != 'usage_mood_explorer' &&
          achievement.id != 'usage_diverse_tracker') {
        continue;
      }

      if (achievement.category == AchievementCategory.milestone &&
          totalEntries >= achievement.threshold) {
        batch.add((
          id: achievement.id,
          progress: totalEntries,
          unlockedAt: now,
        ));
      }
    }

    // Streak achievements
    final dates = await database.getAllEntryDates();
    final longestStreak = computeLongestStreak(dates);
    for (final achievement in allAchievements) {
      if (achievement.category != AchievementCategory.streak) continue;
      if (longestStreak >= achievement.threshold) {
        batch.add((
          id: achievement.id,
          progress: longestStreak,
          unlockedAt: now,
        ));
      }
    }

    // Usage: custom symptoms
    final customSymptoms = await database.getCustomSymptoms();
    if (customSymptoms.isNotEmpty) {
      batch.add((
        id: 'usage_first_custom_symptom',
        progress: 1,
        unlockedAt: now,
      ));
    }

    // Usage: tags
    final hasTags = await database.hasEntriesWithTags();
    if (hasTags) {
      batch.add((id: 'usage_first_tag', progress: 1, unlockedAt: now));
    }

    // Usage: notes
    final hasNotes = await database.hasEntriesWithNotes();
    if (hasNotes) {
      batch.add((id: 'usage_first_note', progress: 1, unlockedAt: now));
    }

    // Usage: mood explorer (5+ distinct moods)
    final distinctMoods = await database.getDistinctMoodCount();
    if (distinctMoods >= 5) {
      batch.add((
        id: 'usage_mood_explorer',
        progress: distinctMoods,
        unlockedAt: now,
      ));
    }

    // Usage: night owl / early bird (scan entry times)
    final allEntries = await database.getAllEntriesWithDetails();
    bool nightOwlFound = false;
    bool earlyBirdFound = false;
    bool diverseTrackerFound = false;
    final weekendEntries = <int, Set<int>>{}; // ISO week -> set of weekdays

    for (final entry in allEntries) {
      final entryHour = entry.dateTime.hour;
      if (!nightOwlFound && entryHour >= 0 && entryHour < 5) {
        nightOwlFound = true;
        batch.add((id: 'usage_night_owl', progress: 1, unlockedAt: now));
      }
      if (!earlyBirdFound && entryHour >= 5 && entryHour < 8) {
        earlyBirdFound = true;
        batch.add((id: 'usage_early_bird', progress: 1, unlockedAt: now));
      }
      if (!diverseTrackerFound && entry.symptoms.length >= 5) {
        diverseTrackerFound = true;
        batch.add((
          id: 'usage_diverse_tracker',
          progress: entry.symptoms.length,
          unlockedAt: now,
        ));
      }

      // Track weekend entries by ISO week
      final weekday = entry.dateTime.weekday;
      if (weekday == DateTime.saturday || weekday == DateTime.sunday) {
        final isoWeek = _isoWeekNumber(entry.dateTime);
        final yearWeek = entry.dateTime.year * 100 + isoWeek;
        weekendEntries.putIfAbsent(yearWeek, () => {}).add(weekday);
      }
    }

    // Weekend warrior: check if any week has both Saturday and Sunday
    final hasWeekendPair = weekendEntries.values.any(
      (days) =>
          days.contains(DateTime.saturday) && days.contains(DateTime.sunday),
    );
    if (hasWeekendPair) {
      batch.add((id: 'usage_weekend_warrior', progress: 1, unlockedAt: now));
    }

    // Only Human: missed a day after building a 2+ day streak
    if (_hasMissedDayAfterStreak(dates)) {
      batch.add((id: 'usage_missed_day', progress: 1, unlockedAt: now));
    }

    if (batch.isNotEmpty) {
      await database.unlockAchievements(batch);
    }

    await prefs.setBool(prefKeyAchievementsScanned, true);
  }

  // ---------------------------------------------------------------------------
  // Combined model resolution (for achievements screen)
  // ---------------------------------------------------------------------------

  /// Merges all achievement definitions with their unlock state and progress
  /// into a single list of [Achievement] objects for direct UI consumption.
  static Future<List<Achievement>> resolveAll(AppDatabase database) async {
    final unlocked = await database.getUnlockedAchievements();
    final unlockedMap = {
      for (final row in unlocked) row.achievementId: row,
    };
    final progress = await computeProgress(database);

    return allAchievements.map((definition) {
      final unlockRecord = unlockedMap[definition.id];
      return Achievement(
        id: definition.id,
        name: definition.name,
        unlockedName: definition.unlockedName,
        description: definition.description,
        category: definition.category,
        threshold: definition.threshold,
        quote: definition.quote,
        isUnlocked: unlockRecord != null,
        unlockedAt: unlockRecord?.unlockedAt,
        progress: progress[definition.id] ?? 0.0,
      );
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // Progress computation (for achievements screen)
  // ---------------------------------------------------------------------------

  /// Returns progress fractions (0.0–1.0) for all achievements.
  static Future<Map<String, double>> computeProgress(
    AppDatabase database,
  ) async {
    final progress = <String, double>{};
    final unlocked = await database.getUnlockedAchievements();
    final unlockedIds = unlocked.map((u) => u.achievementId).toSet();

    final totalEntries = await database.getTotalEntryCount();
    final dates = await database.getAllEntryDates();
    final currentStreak = computeCurrentStreak(dates);
    final distinctMoods = await database.getDistinctMoodCount();

    for (final achievement in allAchievements) {
      if (unlockedIds.contains(achievement.id)) {
        progress[achievement.id] = 1.0;
        continue;
      }

      switch (achievement.category) {
        case AchievementCategory.milestone:
          progress[achievement.id] =
              (totalEntries / achievement.threshold).clamp(0.0, 1.0);

        case AchievementCategory.streak:
          progress[achievement.id] =
              (currentStreak / achievement.threshold).clamp(0.0, 1.0);

        case AchievementCategory.usage:
          if (achievement.id == 'usage_mood_explorer') {
            progress[achievement.id] =
                (distinctMoods / achievement.threshold).clamp(0.0, 1.0);
          } else {
            progress[achievement.id] = 0.0;
          }

        case AchievementCategory.secret:
          progress[achievement.id] = 0.0;
      }
    }

    return progress;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Returns the ISO 8601 week number for a given date.
  static int _isoWeekNumber(DateTime date) {
    final thursday =
        date.subtract(Duration(days: date.weekday - DateTime.thursday));
    final jan1 = DateTime(thursday.year, 1, 1);
    return ((thursday.difference(jan1).inDays) / 7).ceil() + 1;
  }

  /// Returns true if two dates fall in the same ISO week.
  static bool _isSameIsoWeek(DateTime dateA, DateTime dateB) {
    if (dateA.year != dateB.year) {
      final weekA = _isoWeekNumber(dateA);
      final weekB = _isoWeekNumber(dateB);
      final thursdayA =
          dateA.subtract(Duration(days: dateA.weekday - DateTime.thursday));
      final thursdayB =
          dateB.subtract(Duration(days: dateB.weekday - DateTime.thursday));
      return thursdayA.year == thursdayB.year && weekA == weekB;
    }
    return _isoWeekNumber(dateA) == _isoWeekNumber(dateB);
  }

  /// Returns true if the date history contains a streak of 2+ consecutive
  /// days followed by a gap (a missed day).
  static bool _hasMissedDayAfterStreak(List<DateTime> sortedDates) {
    final uniqueDates = _deduplicateDates(sortedDates);
    if (uniqueDates.length < 2) return false;

    int streak = 1;
    for (int index = 1; index < uniqueDates.length; index++) {
      final gap = uniqueDates[index].difference(uniqueDates[index - 1]).inDays;
      if (gap == 1) {
        streak++;
      } else if (gap > 1 && streak >= 2) {
        return true;
      } else {
        streak = 1;
      }
    }
    return false;
  }
}
