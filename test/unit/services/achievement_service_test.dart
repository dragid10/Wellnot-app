import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:symptom_tracker_app/constants/defaults.dart';
import 'package:symptom_tracker_app/models/symptom_models.dart';
import 'package:symptom_tracker_app/services/achievement_service.dart';

import '../../helpers/test_database.dart';

void main() {
  // ---------------------------------------------------------------------------
  // computeCurrentStreak (pure function, no DB)
  // ---------------------------------------------------------------------------
  group('computeCurrentStreak', () {
    test('As a user, I expect an empty date list to return a streak of 0', () {
      expect(AchievementService.computeCurrentStreak([]), 0);
    });

    test('As a user, I expect a single date to return a streak of 1', () {
      final dates = [DateTime(2025, 1, 1)];
      expect(AchievementService.computeCurrentStreak(dates), 1);
    });

    test('As a user, I expect two consecutive dates to return a streak of 2',
        () {
      final dates = [DateTime(2025, 1, 1), DateTime(2025, 1, 2)];
      expect(AchievementService.computeCurrentStreak(dates), 2);
    });

    test(
        'As a user, I expect a gap in dates to break the streak and return only the trailing consecutive days',
        () {
      final dates = [
        DateTime(2025, 1, 1),
        DateTime(2025, 1, 2),
        DateTime(2025, 1, 5),
        DateTime(2025, 1, 6),
      ];
      expect(AchievementService.computeCurrentStreak(dates), 2);
    });

    test(
        'As a user, I expect a 30-day consecutive run to return a streak of 30',
        () {
      final dates = List.generate(
        30,
        (index) => DateTime(2025, 1, 1).add(Duration(days: index)),
      );
      expect(AchievementService.computeCurrentStreak(dates), 30);
    });

    test(
        'As a user, I expect duplicate dates to be handled correctly without inflating the streak',
        () {
      final dates = [
        DateTime(2025, 1, 1),
        DateTime(2025, 1, 1),
        DateTime(2025, 1, 2),
      ];
      expect(AchievementService.computeCurrentStreak(dates), 2);
    });

    test(
        'As a user, I expect a streak spanning a month boundary to count correctly',
        () {
      final dates = [
        DateTime(2025, 1, 30),
        DateTime(2025, 1, 31),
        DateTime(2025, 2, 1),
      ];
      expect(AchievementService.computeCurrentStreak(dates), 3);
    });
  });

  // ---------------------------------------------------------------------------
  // computeLongestStreak (pure function, no DB)
  // ---------------------------------------------------------------------------
  group('computeLongestStreak', () {
    test('As a user, I expect an empty date list to return longest streak of 0',
        () {
      expect(AchievementService.computeLongestStreak([]), 0);
    });

    test(
        'As a user, I expect the longest streak to be found even if the current streak is shorter',
        () {
      final dates = [
        DateTime(2025, 1, 1),
        DateTime(2025, 1, 2),
        DateTime(2025, 1, 3),
        DateTime(2025, 1, 4),
        DateTime(2025, 1, 5),
        // gap
        DateTime(2025, 1, 10),
        DateTime(2025, 1, 11),
        DateTime(2025, 1, 12),
      ];
      expect(AchievementService.computeLongestStreak(dates), 5);
    });

    test(
        'As a user, I expect a single continuous run to be both the current and longest streak',
        () {
      final dates = [
        DateTime(2025, 3, 1),
        DateTime(2025, 3, 2),
        DateTime(2025, 3, 3),
      ];
      expect(AchievementService.computeLongestStreak(dates), 3);
    });
  });

  // ---------------------------------------------------------------------------
  // Milestone checks (with DB)
  // ---------------------------------------------------------------------------
  group('Milestone achievements', () {
    test(
        'As a user, I expect saving my first entry to unlock the milestone_1 achievement',
        () async {
      final db = createTestDatabase();
      addTearDown(() => db.close());

      await db.saveEntry(
        dateTime: DateTime(2025, 1, 1, 10),
        mood: '😊',
        symptoms: [UserSymptomModel(id: 1, name: 'Headache')],
        tags: [],
      );

      final unlocked = await AchievementService.checkAfterSave(
        db,
        entryDateTime: DateTime(2025, 1, 1, 10),
        symptomCount: 1,
        hasNote: false,
        hasTags: false,
      );

      expect(unlocked, contains('milestone_1'));
    });

    test('As a user, I expect 9 entries not to unlock milestone_10', () async {
      final db = createTestDatabase();
      addTearDown(() => db.close());

      for (int index = 0; index < 9; index++) {
        await db.saveEntry(
          dateTime: DateTime(2025, 1, 1, 10 + index),
          mood: '😊',
          symptoms: [UserSymptomModel(id: 1, name: 'Headache')],
          tags: [],
        );
      }

      final unlocked = await AchievementService.checkAfterSave(
        db,
        entryDateTime: DateTime(2025, 1, 1, 19),
        symptomCount: 1,
        hasNote: false,
        hasTags: false,
      );

      expect(unlocked, isNot(contains('milestone_10')));
    });

    test(
        'As a user, I expect achievement checks to be idempotent - calling twice does not double-unlock',
        () async {
      final db = createTestDatabase();
      addTearDown(() => db.close());

      await db.saveEntry(
        dateTime: DateTime(2025, 1, 1, 10),
        mood: '😊',
        symptoms: [UserSymptomModel(id: 1, name: 'Headache')],
        tags: [],
      );

      final firstCheck = await AchievementService.checkAfterSave(
        db,
        entryDateTime: DateTime(2025, 1, 1, 10),
        symptomCount: 1,
        hasNote: false,
        hasTags: false,
      );
      final secondCheck = await AchievementService.checkAfterSave(
        db,
        entryDateTime: DateTime(2025, 1, 1, 10),
        symptomCount: 1,
        hasNote: false,
        hasTags: false,
      );

      expect(firstCheck, contains('milestone_1'));
      expect(secondCheck, isNot(contains('milestone_1')));
    });
  });

  // ---------------------------------------------------------------------------
  // Usage achievements
  // ---------------------------------------------------------------------------
  group('Usage achievements', () {
    test(
        'As a user, I expect saving an entry with notes to unlock usage_first_note',
        () async {
      final db = createTestDatabase();
      addTearDown(() => db.close());

      await db.saveEntry(
        dateTime: DateTime(2025, 1, 1, 10),
        mood: '😊',
        notes: 'Feeling good today',
        symptoms: [UserSymptomModel(id: 1, name: 'Headache')],
        tags: [],
      );

      final unlocked = await AchievementService.checkAfterSave(
        db,
        entryDateTime: DateTime(2025, 1, 1, 10),
        symptomCount: 1,
        hasNote: true,
        hasTags: false,
      );

      expect(unlocked, contains('usage_first_note'));
    });

    test(
        'As a user, I expect saving an entry with tags to unlock usage_first_tag',
        () async {
      final db = createTestDatabase();
      addTearDown(() => db.close());

      await db.saveEntry(
        dateTime: DateTime(2025, 1, 1, 10),
        mood: '😊',
        symptoms: [UserSymptomModel(id: 1, name: 'Headache')],
        tags: [UserTagModel(id: 1, name: 'Exercise')],
      );

      final unlocked = await AchievementService.checkAfterSave(
        db,
        entryDateTime: DateTime(2025, 1, 1, 10),
        symptomCount: 1,
        hasNote: false,
        hasTags: true,
      );

      expect(unlocked, contains('usage_first_tag'));
    });

    test('As a user, I expect exporting data to unlock usage_first_export',
        () async {
      final db = createTestDatabase();
      addTearDown(() => db.close());

      final unlocked = await AchievementService.checkAfterExport(db);

      expect(unlocked, contains('usage_first_export'));
    });

    test(
        'As a user, I expect adding a custom symptom to unlock usage_first_custom_symptom',
        () async {
      final db = createTestDatabase();
      addTearDown(() => db.close());

      await db.addSymptom('Custom Symptom');

      final unlocked = await AchievementService.checkAfterCustomSymptomAdd(db);

      expect(unlocked, contains('usage_first_custom_symptom'));
    });

    test(
        'As a user, I expect viewing the summary screen to unlock usage_first_summary',
        () async {
      final db = createTestDatabase();
      addTearDown(() => db.close());

      final unlocked = await AchievementService.checkAfterSummaryView(db);

      expect(unlocked, contains('usage_first_summary'));
    });

    test(
        'As a user, I expect viewing the summary screen twice to not double-unlock',
        () async {
      final db = createTestDatabase();
      addTearDown(() => db.close());

      await AchievementService.checkAfterSummaryView(db);
      final secondCall = await AchievementService.checkAfterSummaryView(db);

      expect(secondCall, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // Missed day achievement
  // ---------------------------------------------------------------------------
  group('Missed day achievement', () {
    test(
        'As a user, I expect missing a day after a 2-day streak to unlock usage_missed_day',
        () async {
      final db = createTestDatabase();
      addTearDown(() => db.close());

      // Day 1 and Day 2 (streak of 2), then skip Day 3, log Day 4
      await db.saveEntry(
        dateTime: DateTime(2025, 1, 1, 10),
        mood: '😊',
        symptoms: [],
        tags: [],
      );
      await db.saveEntry(
        dateTime: DateTime(2025, 1, 2, 10),
        mood: '😊',
        symptoms: [],
        tags: [],
      );
      await db.saveEntry(
        dateTime: DateTime(2025, 1, 4, 10),
        mood: '😊',
        symptoms: [],
        tags: [],
      );

      final unlocked = await AchievementService.checkAfterSave(
        db,
        entryDateTime: DateTime(2025, 1, 4, 10),
        symptomCount: 0,
        hasNote: false,
        hasTags: false,
      );

      expect(unlocked, contains('usage_missed_day'));
    });

    test(
        'As a user, I expect no missed-day achievement when logging consecutively',
        () async {
      final db = createTestDatabase();
      addTearDown(() => db.close());

      await db.saveEntry(
        dateTime: DateTime(2025, 1, 1, 10),
        mood: '😊',
        symptoms: [],
        tags: [],
      );
      await db.saveEntry(
        dateTime: DateTime(2025, 1, 2, 10),
        mood: '😊',
        symptoms: [],
        tags: [],
      );
      await db.saveEntry(
        dateTime: DateTime(2025, 1, 3, 10),
        mood: '😊',
        symptoms: [],
        tags: [],
      );

      final unlocked = await AchievementService.checkAfterSave(
        db,
        entryDateTime: DateTime(2025, 1, 3, 10),
        symptomCount: 0,
        hasNote: false,
        hasTags: false,
      );

      expect(unlocked, isNot(contains('usage_missed_day')));
    });

    test(
        'As a user, I expect no missed-day achievement with only a single entry before a gap',
        () async {
      final db = createTestDatabase();
      addTearDown(() => db.close());

      // Only 1 entry then a gap - no streak to break
      await db.saveEntry(
        dateTime: DateTime(2025, 1, 1, 10),
        mood: '😊',
        symptoms: [],
        tags: [],
      );
      await db.saveEntry(
        dateTime: DateTime(2025, 1, 5, 10),
        mood: '😊',
        symptoms: [],
        tags: [],
      );

      final unlocked = await AchievementService.checkAfterSave(
        db,
        entryDateTime: DateTime(2025, 1, 5, 10),
        symptomCount: 0,
        hasNote: false,
        hasTags: false,
      );

      expect(unlocked, isNot(contains('usage_missed_day')));
    });
  });

  // ---------------------------------------------------------------------------
  // Night Owl / Early Bird
  // ---------------------------------------------------------------------------
  group('Time-of-day achievements', () {
    test('As a user, I expect logging at 2 AM to unlock usage_night_owl',
        () async {
      final db = createTestDatabase();
      addTearDown(() => db.close());

      await db.saveEntry(
        dateTime: DateTime(2025, 1, 1, 2),
        mood: '😊',
        symptoms: [UserSymptomModel(id: 1, name: 'Headache')],
        tags: [],
      );

      final unlocked = await AchievementService.checkAfterSave(
        db,
        entryDateTime: DateTime(2025, 1, 1, 2),
        symptomCount: 1,
        hasNote: false,
        hasTags: false,
      );

      expect(unlocked, contains('usage_night_owl'));
      expect(unlocked, isNot(contains('usage_early_bird')));
    });

    test('As a user, I expect logging at 6 AM to unlock usage_early_bird',
        () async {
      final db = createTestDatabase();
      addTearDown(() => db.close());

      await db.saveEntry(
        dateTime: DateTime(2025, 1, 1, 6),
        mood: '😊',
        symptoms: [UserSymptomModel(id: 1, name: 'Headache')],
        tags: [],
      );

      final unlocked = await AchievementService.checkAfterSave(
        db,
        entryDateTime: DateTime(2025, 1, 1, 6),
        symptomCount: 1,
        hasNote: false,
        hasTags: false,
      );

      expect(unlocked, contains('usage_early_bird'));
      expect(unlocked, isNot(contains('usage_night_owl')));
    });

    test(
        'As a user, I expect logging at 10 AM to unlock neither night owl nor early bird',
        () async {
      final db = createTestDatabase();
      addTearDown(() => db.close());

      await db.saveEntry(
        dateTime: DateTime(2025, 1, 1, 10),
        mood: '😊',
        symptoms: [UserSymptomModel(id: 1, name: 'Headache')],
        tags: [],
      );

      final unlocked = await AchievementService.checkAfterSave(
        db,
        entryDateTime: DateTime(2025, 1, 1, 10),
        symptomCount: 1,
        hasNote: false,
        hasTags: false,
      );

      expect(unlocked, isNot(contains('usage_night_owl')));
      expect(unlocked, isNot(contains('usage_early_bird')));
    });
  });

  // ---------------------------------------------------------------------------
  // Retroactive scan
  // ---------------------------------------------------------------------------
  group('Retroactive scan', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test(
        'As a user, I expect existing data to be retroactively scanned and achievements batch-unlocked',
        () async {
      final db = createTestDatabase();
      addTearDown(() => db.close());

      for (int index = 0; index < 5; index++) {
        await db.saveEntry(
          dateTime: DateTime(2025, 1, 1 + index, 10),
          mood: '😊',
          symptoms: [UserSymptomModel(id: 1, name: 'Headache')],
          tags: [],
        );
      }

      await AchievementService.retroactiveScan(db);

      final unlocked = await db.getUnlockedAchievements();
      final unlockedIds = unlocked.map((item) => item.achievementId).toSet();

      expect(unlockedIds, contains('milestone_1'));
      expect(unlockedIds, contains('streak_3'));
    });

    test(
        'As a user, I expect the retroactive scan to not re-unlock already-unlocked achievements',
        () async {
      final db = createTestDatabase();
      addTearDown(() => db.close());

      await db.saveEntry(
        dateTime: DateTime(2025, 1, 1, 10),
        mood: '😊',
        symptoms: [UserSymptomModel(id: 1, name: 'Headache')],
        tags: [],
      );

      await db.unlockAchievement('milestone_1', 1);
      final originalUnlock = await db.getUnlockedAchievements();
      final originalTime = originalUnlock
          .firstWhere((item) => item.achievementId == 'milestone_1')
          .unlockedAt;

      await AchievementService.retroactiveScan(db);

      final afterScan = await db.getUnlockedAchievements();
      final afterTime = afterScan
          .firstWhere((item) => item.achievementId == 'milestone_1')
          .unlockedAt;

      expect(afterTime, equals(originalTime));
    });
  });

  // ---------------------------------------------------------------------------
  // Progress computation
  // ---------------------------------------------------------------------------
  group('computeProgress', () {
    test('As a user, I expect unlocked achievements to show 1.0 progress',
        () async {
      final db = createTestDatabase();
      addTearDown(() => db.close());

      await db.unlockAchievement('milestone_1', 1);

      final progress = await AchievementService.computeProgress(db);

      expect(progress['milestone_1'], 1.0);
    });

    test('As a user, I expect partial progress to be shown as a fraction',
        () async {
      final db = createTestDatabase();
      addTearDown(() => db.close());

      for (int index = 0; index < 5; index++) {
        await db.saveEntry(
          dateTime: DateTime(2025, 1, 1 + index, 10),
          mood: '😊',
          symptoms: [UserSymptomModel(id: 1, name: 'Headache')],
          tags: [],
        );
      }

      final progress = await AchievementService.computeProgress(db);

      expect(progress['milestone_10'], closeTo(0.5, 0.01));
    });
  });

  // ---------------------------------------------------------------------------
  // Full Spectrum achievement (all default moods)
  // ---------------------------------------------------------------------------
  group('Full Spectrum achievement', () {
    test(
        'As a user, I expect using all default moods to unlock usage_full_spectrum',
        () async {
      final db = createTestDatabase();
      addTearDown(() => db.close());

      for (int index = 0; index < defaultMoods.length; index++) {
        await db.saveEntry(
          dateTime: DateTime(2025, 1, index + 1, 10),
          mood: defaultMoods[index],
          symptoms: [UserSymptomModel(id: 1, name: 'Headache')],
          tags: [],
        );
      }

      final unlocked = await AchievementService.checkAfterSave(
        db,
        entryDateTime: DateTime(2025, 1, defaultMoods.length + 1, 10),
        symptomCount: 1,
        hasNote: false,
        hasTags: false,
      );

      expect(unlocked, contains('usage_full_spectrum'));
    });

    test(
        'As a user, I expect one less than the default mood count not to unlock usage_full_spectrum',
        () async {
      final db = createTestDatabase();
      addTearDown(() => db.close());

      for (int index = 0; index < defaultMoods.length - 1; index++) {
        await db.saveEntry(
          dateTime: DateTime(2025, 1, index + 1, 10),
          mood: defaultMoods[index],
          symptoms: [UserSymptomModel(id: 1, name: 'Headache')],
          tags: [],
        );
      }

      final unlocked = await AchievementService.checkAfterSave(
        db,
        entryDateTime: DateTime(2025, 1, defaultMoods.length, 10),
        symptomCount: 1,
        hasNote: false,
        hasTags: false,
      );

      expect(unlocked, isNot(contains('usage_full_spectrum')));
    });
  });

  // ---------------------------------------------------------------------------
  // Complete Catalog achievement (all default symptoms)
  // ---------------------------------------------------------------------------
  group('Complete Catalog achievement', () {
    test(
        'As a user, I expect tracking all default symptoms to unlock usage_complete_catalog',
        () async {
      final db = createTestDatabase();
      addTearDown(() => db.close());

      for (int index = 0; index < defaultSymptoms.length; index++) {
        await db.saveEntry(
          dateTime: DateTime(2025, 1, index + 1, 10),
          mood: '😊',
          symptoms: [
            UserSymptomModel(id: index + 1, name: defaultSymptoms[index])
          ],
          tags: [],
        );
      }

      final unlocked = await AchievementService.checkAfterSave(
        db,
        entryDateTime: DateTime(2025, 1, defaultSymptoms.length + 1, 10),
        symptomCount: 1,
        hasNote: false,
        hasTags: false,
      );

      expect(unlocked, contains('usage_complete_catalog'));
    });

    test(
        'As a user, I expect one less than the default symptom count not to unlock usage_complete_catalog',
        () async {
      final db = createTestDatabase();
      addTearDown(() => db.close());

      for (int index = 0; index < defaultSymptoms.length - 1; index++) {
        await db.saveEntry(
          dateTime: DateTime(2025, 1, index + 1, 10),
          mood: '😊',
          symptoms: [
            UserSymptomModel(id: index + 1, name: defaultSymptoms[index])
          ],
          tags: [],
        );
      }

      final unlocked = await AchievementService.checkAfterSave(
        db,
        entryDateTime: DateTime(2025, 1, defaultSymptoms.length, 10),
        symptomCount: 1,
        hasNote: false,
        hasTags: false,
      );

      expect(unlocked, isNot(contains('usage_complete_catalog')));
    });
  });

  // ---------------------------------------------------------------------------
  // Double Down achievement (2+ entries same day)
  // ---------------------------------------------------------------------------
  group('Double Down achievement', () {
    test(
        'As a user, I expect logging 2 entries on the same day to unlock usage_double_entry',
        () async {
      final db = createTestDatabase();
      addTearDown(() => db.close());

      await db.saveEntry(
        dateTime: DateTime(2025, 1, 1, 8),
        mood: '😊',
        symptoms: [UserSymptomModel(id: 1, name: 'Headache')],
        tags: [],
      );
      await db.saveEntry(
        dateTime: DateTime(2025, 1, 1, 18),
        mood: '😴',
        symptoms: [UserSymptomModel(id: 1, name: 'Fatigue')],
        tags: [],
      );

      final unlocked = await AchievementService.checkAfterSave(
        db,
        entryDateTime: DateTime(2025, 1, 1, 18),
        symptomCount: 1,
        hasNote: false,
        hasTags: false,
      );

      expect(unlocked, contains('usage_double_entry'));
    });

    test('As a user, I expect 1 entry per day not to unlock usage_double_entry',
        () async {
      final db = createTestDatabase();
      addTearDown(() => db.close());

      await db.saveEntry(
        dateTime: DateTime(2025, 1, 1, 10),
        mood: '😊',
        symptoms: [UserSymptomModel(id: 1, name: 'Headache')],
        tags: [],
      );
      await db.saveEntry(
        dateTime: DateTime(2025, 1, 2, 10),
        mood: '😊',
        symptoms: [UserSymptomModel(id: 1, name: 'Headache')],
        tags: [],
      );

      final unlocked = await AchievementService.checkAfterSave(
        db,
        entryDateTime: DateTime(2025, 1, 2, 10),
        symptomCount: 1,
        hasNote: false,
        hasTags: false,
      );

      expect(unlocked, isNot(contains('usage_double_entry')));
    });
  });

  // ---------------------------------------------------------------------------
  // Personal Touch 2.0 achievement (5 custom symptoms)
  // ---------------------------------------------------------------------------
  group('Personal Touch 2.0 achievement', () {
    test(
        'As a user, I expect creating 5 custom symptoms to unlock usage_personal_touch_2',
        () async {
      final db = createTestDatabase();
      addTearDown(() => db.close());

      for (int index = 0; index < 5; index++) {
        await db.addSymptom('Custom Symptom $index');
      }

      final unlocked = await AchievementService.checkAfterCustomSymptomAdd(db);

      expect(unlocked, contains('usage_personal_touch_2'));
    });

    test(
        'As a user, I expect 4 custom symptoms not to unlock usage_personal_touch_2',
        () async {
      final db = createTestDatabase();
      addTearDown(() => db.close());

      for (int index = 0; index < 4; index++) {
        await db.addSymptom('Custom Symptom $index');
      }

      final unlocked = await AchievementService.checkAfterCustomSymptomAdd(db);

      expect(unlocked, isNot(contains('usage_personal_touch_2')));
    });

    test(
        'As a user, I expect usage_first_custom_symptom to unlock before usage_personal_touch_2',
        () async {
      final db = createTestDatabase();
      addTearDown(() => db.close());

      await db.addSymptom('Custom Symptom 1');
      final firstUnlock =
          await AchievementService.checkAfterCustomSymptomAdd(db);
      expect(firstUnlock, contains('usage_first_custom_symptom'));
      expect(firstUnlock, isNot(contains('usage_personal_touch_2')));

      await db.addSymptom('Custom Symptom 2');
      await db.addSymptom('Custom Symptom 3');
      await db.addSymptom('Custom Symptom 4');
      await db.addSymptom('Custom Symptom 5');
      final secondUnlock =
          await AchievementService.checkAfterCustomSymptomAdd(db);
      expect(secondUnlock, contains('usage_personal_touch_2'));
    });
  });

  // ---------------------------------------------------------------------------
  // On Schedule achievement (same time on 5+ days)
  // ---------------------------------------------------------------------------
  group('On Schedule achievement', () {
    test(
        'As a user, I expect logging at roughly the same time on 5 days to unlock usage_consistent_tracker',
        () async {
      final db = createTestDatabase();
      addTearDown(() => db.close());

      for (int index = 0; index < 5; index++) {
        await db.saveEntry(
          dateTime: DateTime(2025, 1, index + 1, 9),
          mood: '😊',
          symptoms: [UserSymptomModel(id: 1, name: 'Headache')],
          tags: [],
        );
      }

      final unlocked = await AchievementService.checkAfterSave(
        db,
        entryDateTime: DateTime(2025, 1, 5, 9),
        symptomCount: 1,
        hasNote: false,
        hasTags: false,
      );

      expect(unlocked, contains('usage_consistent_tracker'));
    });

    test(
        'As a user, I expect only 4 days not to unlock usage_consistent_tracker',
        () async {
      final db = createTestDatabase();
      addTearDown(() => db.close());

      for (int index = 0; index < 4; index++) {
        await db.saveEntry(
          dateTime: DateTime(2025, 1, index + 1, 9),
          mood: '😊',
          symptoms: [UserSymptomModel(id: 1, name: 'Headache')],
          tags: [],
        );
      }

      final unlocked = await AchievementService.checkAfterSave(
        db,
        entryDateTime: DateTime(2025, 1, 4, 9),
        symptomCount: 1,
        hasNote: false,
        hasTags: false,
      );

      expect(unlocked, isNot(contains('usage_consistent_tracker')));
    });

    test(
        'As a user, I expect highly variable times not to unlock usage_consistent_tracker',
        () async {
      final db = createTestDatabase();
      addTearDown(() => db.close());

      await db.saveEntry(
        dateTime: DateTime(2025, 1, 1, 8),
        mood: '😊',
        symptoms: [],
        tags: [],
      );
      await db.saveEntry(
        dateTime: DateTime(2025, 1, 2, 14),
        mood: '😊',
        symptoms: [],
        tags: [],
      );
      await db.saveEntry(
        dateTime: DateTime(2025, 1, 3, 20),
        mood: '😊',
        symptoms: [],
        tags: [],
      );
      await db.saveEntry(
        dateTime: DateTime(2025, 1, 4, 3),
        mood: '😊',
        symptoms: [],
        tags: [],
      );
      await db.saveEntry(
        dateTime: DateTime(2025, 1, 5, 12),
        mood: '😊',
        symptoms: [],
        tags: [],
      );

      final unlocked = await AchievementService.checkAfterSave(
        db,
        entryDateTime: DateTime(2025, 1, 5, 12),
        symptomCount: 0,
        hasNote: false,
        hasTags: false,
      );

      expect(unlocked, isNot(contains('usage_consistent_tracker')));
    });
  });

  // ---------------------------------------------------------------------------
  // Progress computation for new achievements
  // ---------------------------------------------------------------------------
  group('computeProgress for new achievements', () {
    test(
        'As a user, I expect usage_full_spectrum progress to reflect mood count',
        () async {
      final db = createTestDatabase();
      addTearDown(() => db.close());

      for (int index = 0; index < defaultMoods.length - 1; index++) {
        await db.saveEntry(
          dateTime: DateTime(2025, 1, index + 1, 10),
          mood: defaultMoods[index],
          symptoms: [],
          tags: [],
        );
      }

      final progress = await AchievementService.computeProgress(db);

      expect(
        progress['usage_full_spectrum'],
        closeTo((defaultMoods.length - 1) / defaultMoods.length, 0.01),
      );
    });

    test(
        'As a user, I expect usage_complete_catalog progress to reflect symptom count',
        () async {
      final db = createTestDatabase();
      addTearDown(() => db.close());

      for (int index = 0; index < defaultSymptoms.length - 1; index++) {
        await db.saveEntry(
          dateTime: DateTime(2025, 1, index + 1, 10),
          mood: '😊',
          symptoms: [
            UserSymptomModel(id: index + 1, name: defaultSymptoms[index])
          ],
          tags: [],
        );
      }

      final progress = await AchievementService.computeProgress(db);

      expect(
        progress['usage_complete_catalog'],
        closeTo((defaultSymptoms.length - 1) / defaultSymptoms.length, 0.01),
      );
    });

    test(
        'As a user, I expect usage_personal_touch_2 progress to reflect custom symptom count',
        () async {
      final db = createTestDatabase();
      addTearDown(() => db.close());

      for (int index = 0; index < 3; index++) {
        await db.addSymptom('Custom Symptom $index');
      }

      final progress = await AchievementService.computeProgress(db);

      expect(progress['usage_personal_touch_2'], closeTo(3 / 5, 0.01));
    });
  });
}
