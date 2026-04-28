// item_preferences_test.dart: Unit tests for pin/hide preferences service.
//
// Tests cover: loading/saving pinned and hidden items, toggle behavior,
// sorting with pinned items first.
//
// Cross-ref:
//   - Service under test: lib/services/item_preferences_service.dart
//   - Preference keys: lib/constants/defaults.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:symptom_tracker_app/services/item_preferences_service.dart';

void main() {
  // Initialize mock SharedPreferences before each test.
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // ---------------------------------------------------------------------------
  // Pinned symptoms
  // ---------------------------------------------------------------------------
  group('pinned symptoms', () {
    // Should return empty list when nothing is pinned.
    test(
        'As a user, I expect no symptoms to be pinned by default on first launch',
        () async {
      final pinned = await ItemPreferencesService.loadPinnedSymptoms();
      expect(pinned, isEmpty);
    });

    // Toggling a symptom should add it to the pinned list.
    test(
        'As a user, I expect long-pressing a symptom to pin it to the top of the list',
        () async {
      final result = await ItemPreferencesService.togglePinSymptom('Headache');
      expect(result, contains('Headache'));
    });

    // Toggling a pinned symptom should remove it.
    test('As a user, I expect long-pressing a pinned symptom to unpin it',
        () async {
      await ItemPreferencesService.togglePinSymptom('Headache');
      final result = await ItemPreferencesService.togglePinSymptom('Headache');
      expect(result, isNot(contains('Headache')));
    });

    // Pinned state should persist across loads.
    test(
        'As a user, I expect my pinned symptoms to persist when I reopen the app',
        () async {
      await ItemPreferencesService.togglePinSymptom('Headache');
      final loaded = await ItemPreferencesService.loadPinnedSymptoms();
      expect(loaded, contains('Headache'));
    });
  });

  // ---------------------------------------------------------------------------
  // Hidden symptoms
  // ---------------------------------------------------------------------------
  group('hidden symptoms', () {
    // Should return empty list when nothing is hidden.
    test(
        'As a user, I expect no symptoms to be hidden by default on first launch',
        () async {
      final hidden = await ItemPreferencesService.loadHiddenSymptoms();
      expect(hidden, isEmpty);
    });

    // Toggling should add/remove from hidden list.
    test(
        'As a user, I expect hiding a symptom to remove it from the list, and unhiding to bring it back',
        () async {
      await ItemPreferencesService.toggleHideSymptom('Fatigue');
      var hidden = await ItemPreferencesService.loadHiddenSymptoms();
      expect(hidden, contains('Fatigue'));

      await ItemPreferencesService.toggleHideSymptom('Fatigue');
      hidden = await ItemPreferencesService.loadHiddenSymptoms();
      expect(hidden, isNot(contains('Fatigue')));
    });
  });

  // ---------------------------------------------------------------------------
  // Sorting with pinned first
  // ---------------------------------------------------------------------------
  group('sortWithPinnedFirst', () {
    // Pinned items should appear before unpinned, both sorted alphabetically.
    test(
        'As a user, I expect pinned items to appear at the top of the list, both groups sorted alphabetically',
        () {
      final items = ['Dizziness', 'Fatigue', 'Headache', 'Nausea'];
      final pinned = ['Nausea', 'Fatigue'];

      final sorted = ItemPreferencesService.sortWithPinnedFirst(
        items,
        pinned,
        (item) => item,
      );

      // Pinned first (alphabetical): Fatigue, Nausea
      // Then unpinned (alphabetical): Dizziness, Headache
      expect(sorted, ['Fatigue', 'Nausea', 'Dizziness', 'Headache']);
    });

    // With no pinned items, should be normal alphabetical order.
    test(
        'As a user, I expect items to be sorted alphabetically when nothing is pinned',
        () {
      final items = ['Headache', 'Dizziness', 'Fatigue'];

      final sorted = ItemPreferencesService.sortWithPinnedFirst(
        items,
        [],
        (item) => item,
      );

      expect(sorted, ['Dizziness', 'Fatigue', 'Headache']);
    });
  });
}
