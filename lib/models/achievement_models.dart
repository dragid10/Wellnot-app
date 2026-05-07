// achievement_models.dart: Plain Dart models for the achievement system (#136)
//
// Combined model that merges compile-time definitions (from
// constants/achievements.dart) with runtime unlock state (from the
// UnlockedAchievements DB table). Screens work with this single type
// instead of manually joining two separate data structures.
//
// Cross-ref:
//   - Achievement definitions: constants/achievements.dart
//   - DB table + helpers: services/database.dart
//   - Resolver: services/achievement_service.dart (resolveAll)
//   - UI: screens/achievements_screen.dart

import '../constants/achievements.dart';

/// A fully resolved achievement — definition metadata merged with unlock state.
///
/// Equality is based on [id] only — each achievement is unique by ID.
class Achievement {
  final String id;
  final String name;
  final String? unlockedName;
  final String description;
  final AchievementCategory category;
  final int threshold;
  final String quote;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final double progress;

  const Achievement({
    required this.id,
    required this.name,
    this.unlockedName,
    required this.description,
    required this.category,
    required this.threshold,
    required this.quote,
    this.isUnlocked = false,
    this.unlockedAt,
    this.progress = 0.0,
  });

  /// The name to display based on unlock state. Uses [unlockedName] when
  /// unlocked (if set), otherwise falls back to [name].
  String get displayName {
    if (isUnlocked && unlockedName != null) return unlockedName!;
    return name;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Achievement &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  Achievement copyWith({
    bool? isUnlocked,
    DateTime? unlockedAt,
    double? progress,
  }) {
    return Achievement(
      id: id,
      name: name,
      unlockedName: unlockedName,
      description: description,
      category: category,
      threshold: threshold,
      quote: quote,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      progress: progress ?? this.progress,
    );
  }
}
