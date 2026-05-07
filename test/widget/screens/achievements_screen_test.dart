import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:symptom_tracker_app/constants/achievements.dart';
import 'package:symptom_tracker_app/models/symptom_models.dart';
import 'package:symptom_tracker_app/screens/achievements_screen.dart';
import 'package:symptom_tracker_app/services/database.dart';

import '../../helpers/test_database.dart';

Future<void> pumpAchievements(WidgetTester tester, AppDatabase db) async {
  await tester.runAsync(() async {
    await tester.pumpWidget(
      Provider<AppDatabase>(
        create: (_) => db,
        child: const MaterialApp(home: AchievementsScreen()),
      ),
    );
    await Future.delayed(const Duration(milliseconds: 200));
  });
  await tester.pump();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AchievementsScreen', () {
    testWidgets(
        'As a user, I expect the achievements screen to display the title "Achievements"',
        (tester) async {
      final db = createTestDatabase();
      await pumpAchievements(tester, db);

      expect(find.text('Achievements'), findsOneWidget);
      await db.close();
    });

    testWidgets(
        'As a user, I expect to see "0 of $totalAchievementCount unlocked" with no achievements earned',
        (tester) async {
      final db = createTestDatabase();
      await pumpAchievements(tester, db);

      expect(find.text('0 of $totalAchievementCount unlocked'), findsOneWidget);
      await db.close();
    });

    testWidgets(
        'As a user, I expect all three category headers to be displayed',
        (tester) async {
      final db = createTestDatabase();
      await pumpAchievements(tester, db);

      expect(find.text('Streaks'), findsOneWidget);
      expect(find.text('Milestones'), findsOneWidget);
      expect(find.text('Tracking'), findsOneWidget);
      await db.close();
    });

    testWidgets('As a user, I expect to see achievement names in the list',
        (tester) async {
      final db = createTestDatabase();
      await pumpAchievements(tester, db);

      expect(find.text('Getting Started'), findsOneWidget);
      expect(find.text('First Step'), findsOneWidget);
      await db.close();
    });

    testWidgets(
        'As a user, I expect unlocked achievements to show a trophy icon and unlock count',
        (tester) async {
      final db = createTestDatabase();
      await tester.runAsync(() => db.unlockAchievement('milestone_1', 1));
      await pumpAchievements(tester, db);

      expect(find.text('1 of $totalAchievementCount unlocked'), findsOneWidget);
      expect(find.byIcon(Icons.emoji_events), findsAtLeast(1));
      await db.close();
    });

    testWidgets(
        'As a user, I expect locked achievements to show a progress bar',
        (tester) async {
      final db = createTestDatabase();
      await tester.runAsync(() async {
        await db.saveEntry(
          dateTime: DateTime(2025, 1, 1, 10),
          mood: '😊',
          symptoms: [UserSymptomModel(id: -1, name: 'Headache')],
          tags: [],
        );
      });
      await pumpAchievements(tester, db);

      expect(find.byType(LinearProgressIndicator), findsAtLeast(1));
      await db.close();
    });
  });
}
