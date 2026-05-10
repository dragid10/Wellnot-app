// database.dart: Drift database schema and helper methods
//
// This file defines tables for entries, symptoms, tags, and their
// relationships. It also provides high-level helper methods that encapsulate
// common multi-table operations so screens don't need raw Drift queries.
//
// Cross-ref:
//   - Models returned here are defined in models/symptom_models.dart
//   - All 4 screens consume the helper methods via Provider (see main.dart)
//   - Schema changes require regenerating database.g.dart with build_runner
//   - The saveEntry() method writes severity to SymptomEntryWithSymptom,
//     fixing the data-loss bug where severity was captured in the UI
//     (widgets/severity_selector.dart → widgets/symptom_entry_widget.dart →
//     screens/entry_screen.dart) but never persisted.

import 'package:drift/drift.dart';
import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/sqlite3.dart' as raw_sqlite;

import '../constants/defaults.dart' as defaults;
import '../models/summary_models.dart';
import '../models/symptom_models.dart';
import 'encryption_key_service.dart';
import 'preferences_service.dart';

part 'database.g.dart';

/// Table for symptom entries (each log by the user).
@TableIndex(name: 'idx_entry_date_time', columns: {#entryDateTime})
class SymptomEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get entryDateTime => dateTime()();
  TextColumn get mood => text()();
  TextColumn get notes => text().nullable()();
}

/// Table for user-defined symptoms (customizable by user).
class UserSymptoms extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
}

/// Table for user-defined tags (customizable by user).
class UserTags extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
}

/// Join table for many-to-many relationship between entries and symptoms.
/// The `severity` column stores the per-entry severity rating (1–5).
@TableIndex(name: 'idx_sews_entry_id', columns: {#symptomEntryId})
class SymptomEntryWithSymptom extends Table {
  IntColumn get symptomEntryId => integer().references(SymptomEntries, #id)();
  IntColumn get userSymptomId => integer().references(UserSymptoms, #id)();
  IntColumn get severity => integer().withDefault(const Constant(3))();
}

/// Join table for many-to-many relationship between entries and tags.
@TableIndex(name: 'idx_sewt_entry_id', columns: {#symptomEntryId})
class SymptomEntryWithTag extends Table {
  IntColumn get symptomEntryId => integer().references(SymptomEntries, #id)();
  IntColumn get userTagId => integer().references(UserTags, #id)();
}

/// Table for tracking which achievements the user has unlocked.
/// Achievement definitions live in constants/achievements.dart — this table
/// only stores the unlock state.
class UnlockedAchievements extends Table {
  TextColumn get achievementId => text()();
  DateTimeColumn get unlockedAt => dateTime()();
  IntColumn get progress => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {achievementId};
}

/// Lightweight record for raw unlock data returned by [AppDatabase.getUnlockedAchievements].
/// Combined model ([Achievement]) is built by [AchievementService.resolveAll].
typedef UnlockRecord = ({
  String achievementId,
  DateTime unlockedAt,
  int progress
});

/// Main database class — schema + helper methods.
///
/// Helper methods are organized by domain:
///   - Entry CRUD: getAllEntriesWithDetails, saveEntry, deleteEntry
///   - Symptom/Tag management: getAllSymptoms, getAllTags, addSymptom, addTag,
///     deleteSymptom, deleteTag
///   - Achievement tracking: getUnlockedAchievements, unlockAchievement, etc.
///   - Data management: clearAllData
@DriftDatabase(tables: [
  SymptomEntries,
  UserSymptoms,
  UserTags,
  SymptomEntryWithSymptom,
  SymptomEntryWithTag,
  UnlockedAchievements,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Constructor for testing — accepts an in-memory or custom executor.
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            // Add severity column to the join table.
            await m.addColumn(
              symptomEntryWithSymptom,
              symptomEntryWithSymptom.severity,
            );
          }
          if (from < 3) {
            await m.createTable(unlockedAchievements);
          }
          if (from < 4) {
            // Add indexes for frequently filtered/sorted columns.
            // Speeds up date-range queries (calendar), last-severity
            // lookups, and entry-to-symptom/tag joins.
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_entry_date_time '
              'ON symptom_entries (entry_date_time)',
            );
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_sews_entry_id '
              'ON symptom_entry_with_symptom (symptom_entry_id)',
            );
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_sewt_entry_id '
              'ON symptom_entry_with_tag (symptom_entry_id)',
            );
          }
        },
      );

  // ---------------------------------------------------------------------------
  // Legacy helpers (kept for backward compatibility during migration)
  // ---------------------------------------------------------------------------

  /// Gets or creates a symptom by name, returns its ID.
  /// Duplicate check is case-insensitive.
  Future<int> getOrCreateSymptom(String name) async {
    final trimmed = name.trim();
    final all = await select(userSymptoms).get();
    final existing =
        all.where((s) => s.name.toLowerCase() == trimmed.toLowerCase());
    if (existing.isNotEmpty) return existing.first.id;
    return into(userSymptoms)
        .insert(UserSymptomsCompanion(name: Value(trimmed)));
  }

  /// Gets or creates a tag by name, returns its ID.
  /// Duplicate check is case-insensitive.
  Future<int> getOrCreateTag(String name) async {
    final trimmed = name.trim();
    final all = await select(userTags).get();
    final existing =
        all.where((t) => t.name.toLowerCase() == trimmed.toLowerCase());
    if (existing.isNotEmpty) return existing.first.id;
    return into(userTags).insert(UserTagsCompanion(name: Value(trimmed)));
  }

  // ---------------------------------------------------------------------------
  // Entry CRUD
  // ---------------------------------------------------------------------------

  /// Fetches all entries with their linked symptoms (including severity) and
  /// tags, returning fully-populated [SymptomEntryModel] objects.
  ///
  /// Prefer [getEntriesForDateRange] when only a subset of entries is needed
  /// (e.g., loading a single month for the calendar view).
  Future<List<SymptomEntryModel>> getAllEntriesWithDetails() async {
    final entriesData = await select(symptomEntries).get();
    return _buildEntryModels(entriesData);
  }

  /// Fetches a single entry by ID with its linked symptoms and tags.
  /// Returns null if no entry exists with the given [id].
  ///
  /// Used by widget deep link handlers to navigate to the detail screen.
  Future<SymptomEntryModel?> getEntryById(int id) async {
    final entryData = await (select(symptomEntries)
          ..where((e) => e.id.equals(id)))
        .getSingleOrNull();
    if (entryData == null) return null;
    final models = await _buildEntryModels([entryData]);
    return models.firstOrNull;
  }

  /// Fetches entries within a date range (inclusive on both ends) with their
  /// linked symptoms and tags.
  ///
  /// Filters at the SQL level so only matching rows are read from disk.
  /// Used by CalendarScreen to load only the visible month's entries instead
  /// of the entire history.
  Future<List<SymptomEntryModel>> getEntriesForDateRange(
    DateTime from,
    DateTime to,
  ) async {
    final entriesData = await (select(symptomEntries)
          ..where((e) => e.entryDateTime.isBetweenValues(from, to)))
        .get();
    return _buildEntryModels(entriesData);
  }

  /// Converts raw entry rows into fully-populated [SymptomEntryModel] objects
  /// by joining with symptom/tag data.
  ///
  /// Shared by [getAllEntriesWithDetails] and [getEntriesForDateRange] to
  /// avoid duplicating the join logic.
  Future<List<SymptomEntryModel>> _buildEntryModels(
    List<SymptomEntry> entriesData,
  ) async {
    if (entriesData.isEmpty) return [];

    final entryIds = entriesData.map((e) => e.id).toSet();
    final symptomsData = await select(userSymptoms).get();
    final tagsData = await select(userTags).get();
    final symptomLinks = await (select(symptomEntryWithSymptom)
          ..where((link) => link.symptomEntryId.isIn(entryIds)))
        .get();
    final tagLinks = await (select(symptomEntryWithTag)
          ..where((link) => link.symptomEntryId.isIn(entryIds)))
        .get();

    final symptomsMap = {for (var s in symptomsData) s.id: s};
    final tagsMap = {for (var t in tagsData) t.id: t};

    return entriesData.map((entryData) {
      final entrySymptoms = symptomLinks
          .where((link) => link.symptomEntryId == entryData.id)
          .map((link) {
            final s = symptomsMap[link.userSymptomId];
            if (s == null) return null;
            return UserSymptomModel(
              id: s.id,
              name: s.name,
              severity: link.severity,
            );
          })
          .where((s) => s != null)
          .cast<UserSymptomModel>()
          .toList();

      final entryTags = tagLinks
          .where((link) => link.symptomEntryId == entryData.id)
          .map((link) {
            final t = tagsMap[link.userTagId];
            if (t == null) return null;
            return UserTagModel(id: t.id, name: t.name);
          })
          .where((t) => t != null)
          .cast<UserTagModel>()
          .toList();

      return SymptomEntryModel(
        id: entryData.id,
        dateTime: entryData.entryDateTime,
        mood: entryData.mood,
        notes: entryData.notes,
        symptoms: entrySymptoms,
        tags: entryTags,
      );
    }).toList();
  }

  /// Creates or updates a symptom entry with its linked symptoms (including
  /// severity) and tags — all within a single transaction.
  ///
  /// Pass [existingId] to update an existing entry; omit it for a new entry.
  /// Returns the entry ID.
  ///
  /// **This fixes the severity data-loss bug:** severity values from the UI
  /// are now written to the `severity` column on the join table.
  Future<int> saveEntry({
    int? existingId,
    required DateTime dateTime,
    required String mood,
    String? notes,
    required List<UserSymptomModel> symptoms,
    required List<UserTagModel> tags,
  }) async {
    // Trim whitespace from notes before saving.
    final trimmedNotes = notes?.trim();

    return transaction(() async {
      int entryId;

      final companion = SymptomEntriesCompanion(
        entryDateTime: Value(dateTime),
        mood: Value(mood),
        notes: Value(trimmedNotes),
      );

      if (existingId != null) {
        entryId = existingId;
        await update(symptomEntries).replace(
          companion.copyWith(id: Value(entryId)),
        );
        // Remove old links before re-creating.
        await (delete(symptomEntryWithSymptom)
              ..where((tbl) => tbl.symptomEntryId.equals(entryId)))
            .go();
        await (delete(symptomEntryWithTag)
              ..where((tbl) => tbl.symptomEntryId.equals(entryId)))
            .go();
      } else {
        entryId = await into(symptomEntries).insert(companion);
      }

      // Link symptoms with their severity values.
      for (final symptom in symptoms) {
        final symptomId = await getOrCreateSymptom(symptom.name);
        await into(symptomEntryWithSymptom).insert(
          SymptomEntryWithSymptomCompanion(
            symptomEntryId: Value(entryId),
            userSymptomId: Value(symptomId),
            severity: Value(symptom.severity),
          ),
        );
      }

      // Link tags.
      for (final tag in tags) {
        final tagId = await getOrCreateTag(tag.name);
        await into(symptomEntryWithTag).insert(
          SymptomEntryWithTagCompanion(
            symptomEntryId: Value(entryId),
            userTagId: Value(tagId),
          ),
        );
      }

      return entryId;
    });
  }

  /// Bulk-imports multiple entries in a single transaction with cached
  /// symptom/tag lookups.
  ///
  /// Unlike [saveEntry] (which creates a transaction per entry and does a
  /// full-table SELECT per getOrCreate call), this method pre-loads all
  /// existing symptoms and tags into memory, creates new ones on the fly,
  /// and inserts everything in one transaction. This reduces DB round trips
  /// from O(entries * items) to O(entries + unique_items).
  Future<void> importEntries(List<SymptomEntryModel> entries) async {
    if (entries.isEmpty) return;

    await transaction(() async {
      // Pre-load existing symptoms and tags into case-insensitive lookup maps.
      final allSymptoms = await select(userSymptoms).get();
      final symptomCache = <String, int>{
        for (final symptom in allSymptoms)
          symptom.name.toLowerCase(): symptom.id,
      };

      final allTags = await select(userTags).get();
      final tagCache = <String, int>{
        for (final tag in allTags) tag.name.toLowerCase(): tag.id,
      };

      for (final entry in entries) {
        final entryId = await into(symptomEntries).insert(
          SymptomEntriesCompanion(
            entryDateTime: Value(entry.dateTime),
            mood: Value(entry.mood),
            notes: Value(entry.notes?.trim()),
          ),
        );

        for (final symptom in entry.symptoms) {
          final trimmedName = symptom.name.trim();
          final cacheKey = trimmedName.toLowerCase();
          var symptomId = symptomCache[cacheKey];
          if (symptomId == null) {
            symptomId = await into(userSymptoms)
                .insert(UserSymptomsCompanion(name: Value(trimmedName)));
            symptomCache[cacheKey] = symptomId;
          }
          await into(symptomEntryWithSymptom).insert(
            SymptomEntryWithSymptomCompanion(
              symptomEntryId: Value(entryId),
              userSymptomId: Value(symptomId),
              severity: Value(symptom.severity),
            ),
          );
        }

        for (final tag in entry.tags) {
          final trimmedName = tag.name.trim();
          final cacheKey = trimmedName.toLowerCase();
          var tagId = tagCache[cacheKey];
          if (tagId == null) {
            tagId = await into(userTags)
                .insert(UserTagsCompanion(name: Value(trimmedName)));
            tagCache[cacheKey] = tagId;
          }
          await into(symptomEntryWithTag).insert(
            SymptomEntryWithTagCompanion(
              symptomEntryId: Value(entryId),
              userTagId: Value(tagId),
            ),
          );
        }
      }
    });
  }

  /// Deletes an entry and all its join-table links in a single transaction.
  Future<void> deleteEntry(int id) async {
    await transaction(() async {
      await (delete(symptomEntryWithSymptom)
            ..where((tbl) => tbl.symptomEntryId.equals(id)))
          .go();
      await (delete(symptomEntryWithTag)
            ..where((tbl) => tbl.symptomEntryId.equals(id)))
          .go();
      await (delete(symptomEntries)..where((tbl) => tbl.id.equals(id))).go();
    });
  }

  // ---------------------------------------------------------------------------
  // Symptom / Tag management
  // ---------------------------------------------------------------------------

  /// Returns all user-defined symptoms as [UserSymptomModel] objects.
  Future<List<UserSymptomModel>> getAllSymptoms() async {
    final rows = await select(userSymptoms).get();
    return rows.map((s) => UserSymptomModel(id: s.id, name: s.name)).toList();
  }

  /// Returns all user-defined tags as [UserTagModel] objects.
  Future<List<UserTagModel>> getAllTags() async {
    final rows = await select(userTags).get();
    return rows.map((t) => UserTagModel(id: t.id, name: t.name)).toList();
  }

  /// Returns only custom (non-default) symptoms as [UserSymptomModel] objects.
  ///
  /// Default symptoms (from [defaults.defaultSymptoms]) are excluded because
  /// they may be inserted into the UserSymptoms table by [saveEntry] via
  /// [getOrCreateSymptom], but should not appear as user-deletable items in
  /// the ManageItemsScreen.
  ///
  /// Context: default items can be auto-inserted into the DB by saveEntry,
  /// so they must be excluded from user-deletable lists.
  Future<List<UserSymptomModel>> getCustomSymptoms() async {
    final all = await getAllSymptoms();
    final defaultNames =
        defaults.defaultSymptoms.map((s) => s.toLowerCase()).toSet();
    return all
        .where((s) => !defaultNames.contains(s.name.toLowerCase()))
        .toList();
  }

  /// Returns only custom (non-default) tags as [UserTagModel] objects.
  ///
  /// Default tags (from [defaults.defaultTags]) are excluded for the same
  /// reason as [getCustomSymptoms].
  ///
  /// Context: default items can be auto-inserted into the DB by saveEntry,
  /// so they must be excluded from user-deletable lists.
  Future<List<UserTagModel>> getCustomTags() async {
    final all = await getAllTags();
    final defaultNames =
        defaults.defaultTags.map((t) => t.toLowerCase()).toSet();
    return all
        .where((t) => !defaultNames.contains(t.name.toLowerCase()))
        .toList();
  }

  /// Adds a new symptom. Returns the new row ID, or -1 if a symptom with the
  /// same name already exists (case-insensitive check).
  Future<int> addSymptom(String name) async {
    final trimmed = name.trim();
    final all = await select(userSymptoms).get();
    final duplicate =
        all.any((s) => s.name.toLowerCase() == trimmed.toLowerCase());
    if (duplicate) return -1;
    try {
      return await into(userSymptoms)
          .insert(UserSymptomsCompanion(name: Value(trimmed)));
    } on Exception {
      return -1;
    }
  }

  /// Adds a new tag. Returns the new row ID, or -1 if a tag with the same
  /// name already exists (case-insensitive check).
  Future<int> addTag(String name) async {
    final trimmed = name.trim();
    final all = await select(userTags).get();
    final duplicate =
        all.any((t) => t.name.toLowerCase() == trimmed.toLowerCase());
    if (duplicate) return -1;
    try {
      return await into(userTags)
          .insert(UserTagsCompanion(name: Value(trimmed)));
    } on Exception {
      return -1;
    }
  }

  /// Deletes a symptom by ID and removes all join-table links referencing it.
  ///
  /// Refuses to delete symptoms whose names match a default (case-insensitive).
  /// This prevents accidental removal of default symptoms that were inserted
  /// into the UserSymptoms table by [getOrCreateSymptom] during [saveEntry].
  ///
  /// Context: default items can be auto-inserted into the DB by saveEntry,
  /// so they must be excluded from user-deletable lists.
  Future<void> deleteSymptom(int id) async {
    // Look up the symptom name and block deletion if it's a default.
    final existing = await (select(userSymptoms)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
    if (existing != null) {
      final isDefault = defaults.defaultSymptoms
          .any((d) => d.toLowerCase() == existing.name.toLowerCase());
      if (isDefault) return;
    }

    await transaction(() async {
      await (delete(symptomEntryWithSymptom)
            ..where((tbl) => tbl.userSymptomId.equals(id)))
          .go();
      await (delete(userSymptoms)..where((tbl) => tbl.id.equals(id))).go();
    });
  }

  /// Deletes a tag by ID and removes all join-table links referencing it.
  ///
  /// Refuses to delete tags whose names match a default (case-insensitive).
  /// This prevents accidental removal of default tags that were inserted
  /// into the UserTags table by [getOrCreateTag] during [saveEntry].
  ///
  /// Context: default items can be auto-inserted into the DB by saveEntry,
  /// so they must be excluded from user-deletable lists.
  Future<void> deleteTag(int id) async {
    // Look up the tag name and block deletion if it's a default.
    final existing = await (select(userTags)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
    if (existing != null) {
      final isDefault = defaults.defaultTags
          .any((d) => d.toLowerCase() == existing.name.toLowerCase());
      if (isDefault) return;
    }

    await transaction(() async {
      await (delete(symptomEntryWithTag)
            ..where((tbl) => tbl.userTagId.equals(id)))
          .go();
      await (delete(userTags)..where((tbl) => tbl.id.equals(id))).go();
    });
  }

  // ---------------------------------------------------------------------------
  // Summary / aggregation (#45)
  // ---------------------------------------------------------------------------

  /// Fetches entries in [from]..[to] and computes an aggregated summary.
  ///
  /// Returns a [DateRangeSummary] with symptom frequencies (ranked by count),
  /// average severity per symptom, mood distribution, and tag frequencies.
  ///
  /// Cross-ref: consumed by screens/summary_screen.dart
  Future<DateRangeSummary> getSummaryForDateRange(
    DateTime from,
    DateTime to,
  ) async {
    final entries = await getEntriesForDateRange(from, to);
    return DateRangeSummary.fromEntries(entries, from, to);
  }

  // ---------------------------------------------------------------------------
  // Severity context (#48)
  // ---------------------------------------------------------------------------

  /// Returns a map of symptom name → most recent severity value.
  ///
  /// Queries the most recent entry for each symptom and returns its
  /// severity. Used by the entry screen to show "Last: Mild" context
  /// next to the severity slider.
  ///
  /// Cross-ref: consumed by screens/entry_screen.dart (_loadUserItems)
  Future<Map<String, int>> getLastSeverities() async {
    final query = select(symptomEntryWithSymptom).join([
      innerJoin(
        userSymptoms,
        userSymptoms.id.equalsExp(symptomEntryWithSymptom.userSymptomId),
      ),
      innerJoin(
        symptomEntries,
        symptomEntries.id.equalsExp(symptomEntryWithSymptom.symptomEntryId),
      ),
    ]);
    query.orderBy([OrderingTerm.desc(symptomEntries.entryDateTime)]);

    final rows = await query.get();
    final Map<String, int> result = {};
    for (final row in rows) {
      final name = row.readTable(userSymptoms).name;
      final severity = row.readTable(symptomEntryWithSymptom).severity;
      if (!result.containsKey(name)) {
        result[name] = severity;
      }
    }
    return result;
  }

  // ---------------------------------------------------------------------------
  // Achievement tracking (#136)
  // ---------------------------------------------------------------------------

  /// Returns all unlocked achievements as lightweight [UnlockRecord] tuples.
  Future<List<UnlockRecord>> getUnlockedAchievements() async {
    final rows = await select(unlockedAchievements).get();
    return rows
        .map((row) => (
              achievementId: row.achievementId,
              unlockedAt: row.unlockedAt,
              progress: row.progress,
            ))
        .toList();
  }

  /// Unlocks a single achievement. Uses INSERT OR IGNORE so calling this
  /// with an already-unlocked ID is a safe no-op.
  Future<void> unlockAchievement(String achievementId, int progress) async {
    await into(unlockedAchievements).insert(
      UnlockedAchievementsCompanion(
        achievementId: Value(achievementId),
        unlockedAt: Value(DateTime.now()),
        progress: Value(progress),
      ),
      mode: InsertMode.insertOrIgnore,
    );
  }

  /// Batch-unlocks multiple achievements in a single transaction.
  /// Used by the retroactive scan to insert historical unlocks efficiently.
  Future<void> unlockAchievements(
    List<({String id, int progress, DateTime unlockedAt})> batch,
  ) async {
    await transaction(() async {
      for (final item in batch) {
        await into(unlockedAchievements).insert(
          UnlockedAchievementsCompanion(
            achievementId: Value(item.id),
            unlockedAt: Value(item.unlockedAt),
            progress: Value(item.progress),
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
    });
  }

  /// Checks whether a specific achievement is already unlocked.
  Future<bool> isAchievementUnlocked(String achievementId) async {
    final row = await (select(unlockedAchievements)
          ..where((tbl) => tbl.achievementId.equals(achievementId)))
        .getSingleOrNull();
    return row != null;
  }

  /// Returns the total number of symptom entries in the database.
  /// Uses SQL COUNT(*) to avoid loading all entry data.
  Future<int> getTotalEntryCount() async {
    final count = countAll();
    final query = selectOnly(symptomEntries)..addColumns([count]);
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  /// Returns all unique entry dates (date-only, no time), sorted ascending.
  /// Used for streak calculation.
  Future<List<DateTime>> getAllEntryDates() async {
    final query = selectOnly(symptomEntries)
      ..addColumns([symptomEntries.entryDateTime])
      ..orderBy([OrderingTerm.asc(symptomEntries.entryDateTime)]);
    final rows = await query.get();
    final dates = rows
        .map((row) => row.read(symptomEntries.entryDateTime))
        .where((dateTime) => dateTime != null)
        .map((dateTime) =>
            DateTime(dateTime!.year, dateTime.month, dateTime.day))
        .toSet()
        .toList();
    dates.sort();
    return dates;
  }

  /// Returns the number of distinct moods used across all entries.
  Future<int> getDistinctMoodCount() async {
    final query = selectOnly(symptomEntries, distinct: true)
      ..addColumns([symptomEntries.mood]);
    final rows = await query.get();
    return rows.length;
  }

  /// Returns the number of distinct symptoms used across all entries.
  Future<int> getDistinctSymptomCount() async {
    final query = selectOnly(symptomEntryWithSymptom, distinct: true)
      ..addColumns([symptomEntryWithSymptom.userSymptomId]);
    final rows = await query.get();
    return rows.length;
  }

  /// Returns the number of entries on a specific date (date-only, no time).
  Future<int> getEntriesForDay(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final count = countAll();
    final query = selectOnly(symptomEntries)..addColumns([count]);
    query.where(
      symptomEntries.entryDateTime.isBetweenValues(start, end),
    );
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  /// Returns true if any entry has at least one tag linked.
  Future<bool> hasEntriesWithTags() async {
    final count = countAll();
    final query = selectOnly(symptomEntryWithTag)..addColumns([count]);
    final result = await query.getSingle();
    return (result.read(count) ?? 0) > 0;
  }

  /// Returns true if any entry has a non-null, non-empty notes field.
  Future<bool> hasEntriesWithNotes() async {
    final query = select(symptomEntries)
      ..where((tbl) =>
          tbl.notes.isNotNull() & tbl.notes.length.isBiggerThanValue(0))
      ..limit(1);
    final rows = await query.get();
    return rows.isNotEmpty;
  }

  // ---------------------------------------------------------------------------
  // Data management
  // ---------------------------------------------------------------------------

  /// Deletes all unlocked achievements, allowing the user to re-earn them.
  ///
  /// Does NOT clear entry data — only resets achievement progress.
  /// Also resets the retroactive scan flag so achievements are re-scanned
  /// on next launch (if achievements are enabled).
  Future<void> clearAchievements() async {
    await delete(unlockedAchievements).go();
  }

  /// Deletes all entries, join-table links, custom symptoms, custom tags,
  /// and unlocked achievements.
  ///
  /// Used by the "Clear All Data" feature in manage_items_screen.dart.
  Future<void> clearAllData() async {
    await transaction(() async {
      await delete(unlockedAchievements).go();
      await delete(symptomEntryWithSymptom).go();
      await delete(symptomEntryWithTag).go();
      await delete(symptomEntries).go();
      await delete(userSymptoms).go();
      await delete(userTags).go();
    });
  }
}

/// Opens the database connection, stores DB file in app documents directory.
///
/// The database is encrypted at rest using SQLite3MultipleCiphers. On first
/// launch, a random 256-bit encryption key is generated and stored in the
/// platform's secure storage (Android Keystore / iOS Keychain). On subsequent
/// launches, the key is retrieved from secure storage and used to open the
/// encrypted database.
///
/// Existing users upgrading from an unencrypted database get an automatic
/// in-place migration via PRAGMA rekey (encrypts the file without data loss).
///
/// If the encryption key is lost (e.g., user clears app data from system
/// settings), the encrypted database becomes unreadable. In that case, the
/// corrupted file is deleted and a fresh encrypted database is created.
///
/// On iOS, the database file is marked with `NSURLIsExcludedFromBackupKey`
/// via a platform channel to prevent iCloud backup of user data.
/// On Android, backup exclusion is handled by `backup_rules.xml` /
/// `data_extraction_rules.xml` in the Android manifest.
///
/// Cross-ref:
///   - Encryption key management: lib/services/encryption_key_service.dart
///   - sqlite3mc configured in pubspec.yaml hooks section
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));

    // Recovery: if a previous version moved the database to Application
    // Support, move it back to Documents where it belongs.
    if (Platform.isIOS && !file.existsSync()) {
      final supportFolder = await getApplicationSupportDirectory();
      final movedFile = File(p.join(supportFolder.path, 'db.sqlite'));
      if (movedFile.existsSync()) {
        await movedFile.copy(file.path);
        await movedFile.delete();
        for (final suffix in ['-wal', '-shm', '-journal']) {
          final movedSuffix =
              File(p.join(supportFolder.path, 'db.sqlite$suffix'));
          if (movedSuffix.existsSync()) {
            await movedSuffix.copy(p.join(dbFolder.path, 'db.sqlite$suffix'));
            await movedSuffix.delete();
          }
        }
      }
    }

    // Check if a previous migration attempt failed. If so, skip encryption
    // and open unencrypted until the user resolves it via the recovery flow.
    // Only applies when the DB is actually plaintext — if the DB is already
    // encrypted (e.g., flag was set in an inconsistent state), clear the
    // stale flag and proceed normally with encryption.
    final prefs = await SharedPreferences.getInstance();
    final migrationFailed =
        prefs.getBool(defaults.prefKeyEncryptionMigrationFailed) ??
            defaults.defaultEncryptionMigrationFailed;

    if (migrationFailed) {
      if (_isPlaintextDatabase(file) || !file.existsSync()) {
        if (Platform.isIOS) await _excludeFromICloudBackup(file);
        return NativeDatabase(file);
      }
      // DB is already encrypted — flag is stale, clear it.
      await prefs.setBool(defaults.prefKeyEncryptionMigrationFailed, false);
      PreferencesService.encryptionMigrationFailedNotifier.value = false;
    }

    // Retrieve (or generate) the encryption key from platform-secure storage.
    final encryptionKey = await EncryptionKeyService.getOrCreateKey();

    // Migrate existing plaintext database to encrypted in-place.
    if (_isPlaintextDatabase(file)) {
      final migrated = await _migrateToEncrypted(file, encryptionKey);
      if (!migrated) {
        // Migration failed — flag it for the recovery UI and fall back to
        // opening the database unencrypted so the app remains usable.
        await prefs.setBool(defaults.prefKeyEncryptionMigrationFailed, true);
        if (Platform.isIOS) await _excludeFromICloudBackup(file);
        return NativeDatabase(file);
      }
    }

    // Open the database with the encryption key. The setup callback runs
    // before Drift reads user_version or runs migrations, so the key is
    // set before any other SQL executes.
    QueryExecutor db;
    try {
      db = NativeDatabase(file, setup: (rawDb) {
        rawDb.execute("PRAGMA key = '$encryptionKey'");
      });
    } catch (error) {
      // If the key doesn't match (e.g., user cleared app data via system
      // settings, deleting the Keystore/Keychain entry but not the file),
      // the database is unreadable. Delete and start fresh.
      debugPrint('Database open failed (key mismatch?): $error');
      await _deleteDatabaseFiles(file);
      await EncryptionKeyService.deleteKey();
      final newKey = await EncryptionKeyService.getOrCreateKey();
      db = NativeDatabase(file, setup: (rawDb) {
        rawDb.execute("PRAGMA key = '$newKey'");
      });
    }

    if (Platform.isIOS) {
      await _excludeFromICloudBackup(file);
    }

    return db;
  });
}

/// Checks whether [file] is an unencrypted SQLite database by reading the
/// standard 16-byte file header ("SQLite format 3\0").
///
/// Returns false for encrypted databases (scrambled header), non-existent
/// files, and empty files (fresh installs where no DB exists yet).
bool _isPlaintextDatabase(File file) {
  if (!file.existsSync() || file.lengthSync() == 0) return false;
  final raf = file.openSync(mode: FileMode.read);
  try {
    final bytes = raf.readSync(16);
    if (bytes.length < 16) return false;
    // "SQLite format 3\0" in ASCII
    const header = <int>[
      0x53,
      0x51,
      0x4C,
      0x69,
      0x74,
      0x65,
      0x20,
      0x66,
      0x6F,
      0x72,
      0x6D,
      0x61,
      0x74,
      0x20,
      0x33,
      0x00,
    ];
    for (var index = 0; index < 16; index++) {
      if (bytes[index] != header[index]) return false;
    }
    return true;
  } finally {
    raf.closeSync();
  }
}

/// Encrypts an existing plaintext database file in-place using
/// SQLite3MultipleCiphers' PRAGMA rekey.
///
/// Before encrypting, flushes any WAL data into the main file to ensure
/// no plaintext remains in sidecar files. After encryption, deletes the
/// WAL/SHM/journal files since they may contain plaintext data.
///
/// A backup copy is made before encryption. If the migration fails, the
/// backup is restored so the user doesn't lose data.
///
/// Returns `true` on success. On failure, restores the backup and returns
/// `false` so the caller can fall back to the unencrypted database.
///
/// Cross-ref: pattern confirmed from sqlite3 v3.2.0 test suite
///   (test/wasm/encryption_test.dart:103)
Future<bool> _migrateToEncrypted(File dbFile, String key) async {
  final backupFile = File('${dbFile.path}.bak');

  // Back up the plaintext database in case encryption fails mid-way.
  await dbFile.copy(backupFile.path);

  try {
    final rawDb = raw_sqlite.sqlite3.open(dbFile.path);
    try {
      // Flush WAL data into the main database file before encrypting.
      rawDb.execute('PRAGMA wal_checkpoint(TRUNCATE)');
      // Encrypt the database in-place.
      rawDb.execute("PRAGMA rekey = '$key'");
    } finally {
      rawDb.close();
    }

    // Delete sidecar files that may contain plaintext data.
    await _deleteSidecarFiles(dbFile);

    // Migration succeeded — remove the backup.
    if (backupFile.existsSync()) {
      await backupFile.delete();
    }

    debugPrint('Database encrypted successfully');
    return true;
  } catch (error) {
    // Restore the backup so the user's data isn't lost.
    debugPrint('Database encryption failed, restoring backup: $error');
    if (backupFile.existsSync()) {
      await backupFile.copy(dbFile.path);
      await backupFile.delete();
    }
    return false;
  }
}

/// Deletes the database file and all its sidecar files (WAL, SHM, journal).
Future<void> _deleteDatabaseFiles(File dbFile) async {
  if (dbFile.existsSync()) {
    await dbFile.delete();
  }
  await _deleteSidecarFiles(dbFile);
}

/// Deletes WAL, SHM, and journal sidecar files for a database.
Future<void> _deleteSidecarFiles(File dbFile) async {
  for (final suffix in ['-wal', '-shm', '-journal']) {
    final sidecar = File('${dbFile.path}$suffix');
    if (sidecar.existsSync()) {
      await sidecar.delete();
    }
  }
}

/// Asks the native iOS side to set NSURLIsExcludedFromBackupKey on the
/// database file, preventing it from being backed up to iCloud.
///
/// Creates the file first if it doesn't exist, because NativeDatabase
/// is lazy and won't create the SQLite file until the first query.
/// An empty file is fine — sqlite3 initializes it on first open.
Future<void> _excludeFromICloudBackup(File file) async {
  try {
    if (!file.existsSync()) {
      await file.create(recursive: true);
    }
    const channel = MethodChannel('com.symptom_tracker_app/platform');
    await channel.invokeMethod('excludeFromBackup', {'path': file.path});
  } catch (e) {
    // Non-fatal: backup exclusion is a privacy improvement, not a
    // requirement for the app to function.
    debugPrint('Failed to exclude database from iCloud backup: $e');
  }
}
