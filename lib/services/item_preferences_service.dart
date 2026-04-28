// item_preferences_service.dart: Manages pin and hide preferences for
// symptoms, tags, and moods.
//
// All preferences are stored in SharedPreferences as JSON string lists.
// No database migration needed — defaults remain in code, only the
// user's personalization is stored.
//
// Cross-ref:
//   - Preference keys: constants/defaults.dart
//   - Consumed by: screens/entry_screen.dart, screens/manage_list_screen.dart,
//     screens/manage_items_screen.dart

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import '../constants/defaults.dart';

/// Service for loading and saving pin/hide preferences.
///
/// Pinned items appear at the top of chip lists on the entry screen.
/// Hidden items are filtered out of the entry screen but shown greyed
/// out on the manage screens so users can re-enable them.
class ItemPreferencesService {
  // ---------------------------------------------------------------------------
  // Generic helpers for reading/writing string lists to SharedPreferences
  // ---------------------------------------------------------------------------

  /// Reads a JSON-encoded string list from SharedPreferences.
  /// Returns an empty list if the key doesn't exist.
  static Future<List<String>> _loadStringList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(key);
    if (json == null) return [];
    return List<String>.from(jsonDecode(json) as List);
  }

  /// Writes a string list as JSON to SharedPreferences.
  static Future<void> _saveStringList(String key, List<String> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(items));
  }

  // ---------------------------------------------------------------------------
  // Pinned items
  // ---------------------------------------------------------------------------

  /// Returns the list of pinned symptom names (case-sensitive).
  static Future<List<String>> loadPinnedSymptoms() async {
    return _loadStringList(prefKeyPinnedSymptoms);
  }

  /// Returns the list of pinned tag names (case-sensitive).
  static Future<List<String>> loadPinnedTags() async {
    return _loadStringList(prefKeyPinnedTags);
  }

  /// Toggles the pin state of a symptom. Returns the new pinned list.
  static Future<List<String>> togglePinSymptom(String name) async {
    final pinned = await loadPinnedSymptoms();
    if (pinned.contains(name)) {
      pinned.remove(name);
    } else {
      pinned.add(name);
    }
    await _saveStringList(prefKeyPinnedSymptoms, pinned);
    return pinned;
  }

  /// Toggles the pin state of a tag. Returns the new pinned list.
  static Future<List<String>> togglePinTag(String name) async {
    final pinned = await loadPinnedTags();
    if (pinned.contains(name)) {
      pinned.remove(name);
    } else {
      pinned.add(name);
    }
    await _saveStringList(prefKeyPinnedTags, pinned);
    return pinned;
  }

  // ---------------------------------------------------------------------------
  // Hidden items
  // ---------------------------------------------------------------------------

  /// Returns the list of hidden symptom names.
  static Future<List<String>> loadHiddenSymptoms() async {
    return _loadStringList(prefKeyHiddenSymptoms);
  }

  /// Returns the list of hidden tag names.
  static Future<List<String>> loadHiddenTags() async {
    return _loadStringList(prefKeyHiddenTags);
  }

  /// Toggles the hidden state of a symptom. Returns the new hidden list.
  static Future<List<String>> toggleHideSymptom(String name) async {
    final hidden = await loadHiddenSymptoms();
    if (hidden.contains(name)) {
      hidden.remove(name);
    } else {
      hidden.add(name);
    }
    await _saveStringList(prefKeyHiddenSymptoms, hidden);
    return hidden;
  }

  /// Toggles the hidden state of a tag. Returns the new hidden list.
  static Future<List<String>> toggleHideTag(String name) async {
    final hidden = await loadHiddenTags();
    if (hidden.contains(name)) {
      hidden.remove(name);
    } else {
      hidden.add(name);
    }
    await _saveStringList(prefKeyHiddenTags, hidden);
    return hidden;
  }

  // ---------------------------------------------------------------------------
  // Sorting helpers
  // ---------------------------------------------------------------------------

  /// Sorts a list with pinned items first (alphabetical), then unpinned
  /// (alphabetical). Items in [pinnedNames] appear at the top.
  static List<T> sortWithPinnedFirst<T>(
    List<T> items,
    List<String> pinnedNames,
    String Function(T) getName,
  ) {
    final pinned = <T>[];
    final unpinned = <T>[];
    for (final item in items) {
      if (pinnedNames.contains(getName(item))) {
        pinned.add(item);
      } else {
        unpinned.add(item);
      }
    }
    // Sort each group alphabetically by name.
    pinned.sort(
        (a, b) => getName(a).toLowerCase().compareTo(getName(b).toLowerCase()));
    unpinned.sort(
        (a, b) => getName(a).toLowerCase().compareTo(getName(b).toLowerCase()));
    return [...pinned, ...unpinned];
  }
}
