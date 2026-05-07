import 'package:flutter_test/flutter_test.dart';
import 'package:symptom_tracker_app/constants/achievements.dart';
import 'package:symptom_tracker_app/models/achievement_models.dart';

void main() {
  group('Achievement', () {
    test(
        'As a user, I expect two achievements with the same ID to be treated as equal regardless of unlock state',
        () {
      final achievementA = Achievement(
        id: 'streak_3',
        name: 'Getting Started',
        description: 'Log entries 3 days in a row',
        category: AchievementCategory.streak,
        threshold: 3,
        quote: 'Test quote',
        isUnlocked: true,
        unlockedAt: DateTime(2025, 1, 1),
        progress: 1.0,
      );
      final achievementB = Achievement(
        id: 'streak_3',
        name: 'Getting Started',
        description: 'Log entries 3 days in a row',
        category: AchievementCategory.streak,
        threshold: 3,
        quote: 'Test quote',
        isUnlocked: false,
        progress: 0.5,
      );
      final achievementC = Achievement(
        id: 'streak_7',
        name: 'One Week Strong',
        description: 'Log entries 7 days in a row',
        category: AchievementCategory.streak,
        threshold: 7,
        quote: 'Another quote',
      );

      expect(achievementA, equals(achievementB));
      expect(achievementA, isNot(equals(achievementC)));
    });

    test(
        'As a user, I expect equal achievements to work correctly in collections - consistent hashCode',
        () {
      final achievementA = Achievement(
        id: 'milestone_1',
        name: 'First Step',
        description: 'Log your first entry',
        category: AchievementCategory.milestone,
        threshold: 1,
        quote: 'Quote A',
        isUnlocked: true,
        unlockedAt: DateTime(2025, 3, 1),
      );
      final achievementB = Achievement(
        id: 'milestone_1',
        name: 'First Step',
        description: 'Log your first entry',
        category: AchievementCategory.milestone,
        threshold: 1,
        quote: 'Quote B',
        isUnlocked: false,
      );

      expect(achievementA.hashCode, equals(achievementB.hashCode));
    });

    test(
        'As a user, I expect unlocked achievements to have defaults of false and 0.0 progress',
        () {
      final achievement = Achievement(
        id: 'usage_first_tag',
        name: 'Tag, You\'re It',
        description: 'Use a tag for the first time',
        category: AchievementCategory.usage,
        threshold: 1,
        quote: 'Test',
      );

      expect(achievement.isUnlocked, false);
      expect(achievement.unlockedAt, isNull);
      expect(achievement.progress, 0.0);
    });

    test(
        'As a user, I expect copyWith to preserve identity fields and allow overriding unlock state',
        () {
      final original = Achievement(
        id: 'streak_7',
        name: 'One Week Strong',
        description: 'Log entries 7 days in a row',
        category: AchievementCategory.streak,
        threshold: 7,
        quote: 'A whole week.',
        isUnlocked: false,
        progress: 0.5,
      );
      final unlockDate = DateTime(2025, 6, 15);
      final copy = original.copyWith(
        isUnlocked: true,
        unlockedAt: unlockDate,
        progress: 1.0,
      );

      expect(copy.id, 'streak_7');
      expect(copy.name, 'One Week Strong');
      expect(copy.quote, 'A whole week.');
      expect(copy.isUnlocked, true);
      expect(copy.unlockedAt, unlockDate);
      expect(copy.progress, 1.0);
    });

    test(
        'As a user, I expect copyWith without arguments to produce an equivalent copy',
        () {
      final original = Achievement(
        id: 'milestone_100',
        name: 'Century Club',
        description: 'Log 100 entries',
        category: AchievementCategory.milestone,
        threshold: 100,
        quote: 'One hundred.',
        isUnlocked: true,
        unlockedAt: DateTime(2025, 4, 1),
        progress: 1.0,
      );
      final copy = original.copyWith();

      expect(copy, equals(original));
      expect(copy.isUnlocked, original.isUnlocked);
      expect(copy.unlockedAt, original.unlockedAt);
      expect(copy.progress, original.progress);
    });
  });
}
