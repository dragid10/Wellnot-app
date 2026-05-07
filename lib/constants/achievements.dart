// achievements.dart: Achievement definitions for the gamification system (#136)
//
// All achievement metadata lives here in code — the database only stores
// which achievements have been unlocked (see services/database.dart).
//
// Cross-ref:
//   - Unlock state: services/database.dart (UnlockedAchievements table)
//   - Checking logic: services/achievement_service.dart
//   - UI: screens/achievements_screen.dart
//   - Toast: screens/calendar_screen.dart (listens to achievementUnlockedNotifier)

import 'package:flutter/material.dart';

/// Categories that group related achievements.
enum AchievementCategory {
  streak(label: 'Streaks', icon: Icons.local_fire_department),
  milestone(label: 'Milestones', icon: Icons.flag),
  usage(label: 'Tracking', icon: Icons.star),
  secret(label: 'Secrets', icon: Icons.lock);

  final String label;
  final IconData icon;

  const AchievementCategory({required this.label, required this.icon});
}

/// A single achievement definition — immutable metadata, not unlock state.
class AchievementDefinition {
  final String id;
  final String name;
  final String description;
  final AchievementCategory category;
  final int threshold;
  final String quote;

  /// Alternate name revealed only after unlocking. When set, [name] is shown
  /// while locked and [unlockedName] replaces it once the achievement unlocks.
  final String? unlockedName;

  const AchievementDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.threshold,
    required this.quote,
    this.unlockedName,
  });
}

/// All achievements in the app, ordered by category then threshold.
const List<AchievementDefinition> allAchievements = [
  // Streak achievements — consecutive days with entries
  AchievementDefinition(
    id: 'streak_3',
    name: 'Getting Started',
    description: 'Log entries 3 days in a row',
    category: AchievementCategory.streak,
    threshold: 3,
    quote: 'Three days? That\'s basically a lifestyle change.',
  ),
  AchievementDefinition(
    id: 'streak_7',
    name: 'One Week Strong',
    description: 'Log entries 7 days in a row',
    category: AchievementCategory.streak,
    threshold: 7,
    quote: 'A whole week. Your past self would be impressed.',
  ),
  AchievementDefinition(
    id: 'streak_14',
    name: 'Two-Week Tracker',
    description: 'Log entries 14 days in a row',
    category: AchievementCategory.streak,
    threshold: 14,
    quote: 'Two weeks of consistency. Who even are you anymore?',
  ),
  AchievementDefinition(
    id: 'streak_30',
    name: 'Monthly Devotion',
    description: 'Log entries 30 days in a row',
    category: AchievementCategory.streak,
    threshold: 30,
    quote: 'Thirty days straight. At this point, the app needs you.',
  ),

  // Milestone achievements — total entries logged
  AchievementDefinition(
    id: 'milestone_1',
    name: 'First Step',
    description: 'Log your first entry',
    category: AchievementCategory.milestone,
    threshold: 1,
    quote: 'Every journey starts with a single tap.',
  ),
  AchievementDefinition(
    id: 'milestone_10',
    name: 'Getting Into It',
    description: 'Log 10 entries',
    category: AchievementCategory.milestone,
    threshold: 10,
    quote: 'Double digits! You\'re officially not a quitter.',
  ),
  AchievementDefinition(
    id: 'milestone_25',
    name: 'Quarter Century',
    description: 'Log 25 entries',
    category: AchievementCategory.milestone,
    threshold: 25,
    quote: 'Twenty-five entries. You and this app are getting serious.',
  ),
  AchievementDefinition(
    id: 'milestone_50',
    name: 'Halfway to a Hundred',
    description: 'Log 50 entries',
    category: AchievementCategory.milestone,
    threshold: 50,
    quote: 'Fifty entries. The glass is half full. Probably.',
  ),
  AchievementDefinition(
    id: 'milestone_100',
    name: 'Century Club',
    description: 'Log 100 entries',
    category: AchievementCategory.milestone,
    threshold: 100,
    quote: 'One hundred. Your phone should be paying you rent.',
  ),
  AchievementDefinition(
    id: 'milestone_250',
    name: 'Dedicated Tracker',
    description: 'Log 250 entries',
    category: AchievementCategory.milestone,
    threshold: 250,
    quote: 'You have more entries than most people have houseplants.',
  ),
  AchievementDefinition(
    id: 'milestone_500',
    name: 'Wellness Warrior',
    description: 'Log 500 entries',
    category: AchievementCategory.milestone,
    threshold: 500,
    quote: 'Five hundred entries. This is your magnum opus.',
  ),

  // Usage achievements — first-time actions and behavior
  AchievementDefinition(
    id: 'usage_first_custom_symptom',
    name: 'Personal Touch',
    description: 'Add your first custom symptom',
    category: AchievementCategory.usage,
    threshold: 1,
    quote: 'The default list just wasn\'t you, huh?',
  ),
  AchievementDefinition(
    id: 'usage_first_tag',
    name: 'Tag, You\'re It',
    description: 'Use a tag for the first time',
    category: AchievementCategory.usage,
    threshold: 1,
    quote: 'Organizing your chaos, one tag at a time.',
  ),
  AchievementDefinition(
    id: 'usage_first_note',
    name: 'In Your Own Words',
    description: 'Write your first note on an entry',
    category: AchievementCategory.usage,
    threshold: 1,
    quote: 'Sometimes buttons just aren\'t enough.',
  ),
  AchievementDefinition(
    id: 'usage_first_export',
    name: 'Data Freedom',
    description: 'Export your data for the first time',
    category: AchievementCategory.usage,
    threshold: 1,
    quote: 'Your data, your rules. As it should be.',
  ),
  AchievementDefinition(
    id: 'usage_night_owl',
    name: 'Night Owl',
    description: 'Log an entry between midnight and 5 AM',
    category: AchievementCategory.usage,
    threshold: 1,
    quote: 'Nothing good happens after midnight. Except this.',
  ),
  AchievementDefinition(
    id: 'usage_early_bird',
    name: 'Early Bird',
    description: 'Log an entry between 5 AM and 8 AM',
    category: AchievementCategory.usage,
    threshold: 1,
    quote: 'Up before the sun and already tracking. Respect.',
  ),
  AchievementDefinition(
    id: 'usage_mood_explorer',
    name: 'Mood Explorer',
    description: 'Use 5 different moods across your entries',
    category: AchievementCategory.usage,
    threshold: 5,
    quote: 'Look at you, feeling the full spectrum.',
  ),
  AchievementDefinition(
    id: 'usage_diverse_tracker',
    name: 'Diverse Tracker',
    description: 'Track 5 different symptoms in a single entry',
    category: AchievementCategory.usage,
    threshold: 5,
    quote: 'Five symptoms in one go. That\'s called thoroughness.',
  ),
  AchievementDefinition(
    id: 'usage_weekend_warrior',
    name: 'Weekend Warrior',
    description: 'Log entries on both Saturday and Sunday in the same week',
    category: AchievementCategory.usage,
    threshold: 1,
    quote: 'Weekends are for relaxing. And apparently, logging.',
  ),
  AchievementDefinition(
    id: 'usage_first_summary',
    name: 'Insight Seeker',
    description: 'View the summary screen for the first time',
    category: AchievementCategory.usage,
    threshold: 1,
    quote: 'Curiosity didn\'t hurt the cat. It made it wiser.',
  ),
  AchievementDefinition(
    id: 'usage_missed_day',
    name: 'Only Human',
    description: 'Miss a day of logging after a streak of 2 or more days',
    category: AchievementCategory.usage,
    threshold: 1,
    quote: 'Rest days are part of the training, right?',
  ),
  AchievementDefinition(
    id: 'usage_easter_egg',
    name: 'Super Secret Achievement #1',
    unlockedName: 'Yes Chef!',
    description: 'Some mysteries are best left unsolved... or are they?',
    category: AchievementCategory.secret,
    threshold: 1,
    quote: 'You found it. Now pretend you didn\'t.',
  ),
  AchievementDefinition(
    id: 'usage_first_feedback',
    name: 'Voice Heard',
    description: 'Send feedback for the first time',
    category: AchievementCategory.usage,
    threshold: 1,
    quote: 'Someone actually reads these. Probably.',
  ),
  AchievementDefinition(
    id: 'usage_shake_feedback',
    name: 'Shake It Off',
    description: 'Use shake-to-feedback to send feedback',
    category: AchievementCategory.usage,
    threshold: 1,
    quote: 'Shaking your phone at it is a valid communication method.',
  ),
  AchievementDefinition(
    id: 'usage_first_hide',
    name: 'Out of Sight',
    description: 'Hide a symptom or tag from the entry screen',
    category: AchievementCategory.usage,
    threshold: 1,
    quote: 'If you can\'t see it, it can\'t bother you.',
  ),
  AchievementDefinition(
    id: 'usage_first_pin',
    name: 'Pinned and Ready',
    description: 'Pin a symptom or tag so it always appears first',
    category: AchievementCategory.usage,
    threshold: 1,
    quote: 'Playing favorites has never been this productive.',
  ),

  // 365-day streak
  AchievementDefinition(
    id: 'streak_365',
    name: 'Year of Dedication',
    description: 'Log entries 365 days in a row',
    category: AchievementCategory.streak,
    threshold: 365,
    quote: 'A whole year. You deserve a trophy. Oh wait.',
  ),
];

/// Total number of achievements in the app.
const int totalAchievementCount = 28;

/// Groups all achievements by category for sectioned display.
Map<AchievementCategory, List<AchievementDefinition>>
    get achievementsByCategory {
  final map = <AchievementCategory, List<AchievementDefinition>>{};
  for (final achievement in allAchievements) {
    map.putIfAbsent(achievement.category, () => []).add(achievement);
  }
  return map;
}
