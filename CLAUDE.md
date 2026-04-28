# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Wellnot** - Flutter mobile app (Android + iOS) for tracking daily symptoms, moods, and tags. Local-first with no backend - all data is stored on-device via SQLite (Drift ORM). Fully offline - no internet access required, no network calls.

## Common Commands

```bash
flutter pub get                                           # Install dependencies
flutter run                                               # Run on connected device/emulator
flutter analyze                                           # Run linter (uses flutter_lints)
flutter test                                              # Run unit + widget tests
flutter test test/unit/                                   # Run unit tests only
flutter test test/widget/                                 # Run widget tests only
flutter test integration_test/                            # Run integration tests (requires emulator)
dart run build_runner build --delete-conflicting-outputs   # Regenerate Drift database code
dart run build_runner clean                               # Clean generated files before rebuild
flutter build apk                                         # Build Android APK
flutter build appbundle                                    # Build Android AAB (required for Play Store)
flutter build ipa                                          # Build iOS release (requires macOS + Xcode)
```

### When to regenerate `database.g.dart`

You **must** run `dart run build_runner build --delete-conflicting-outputs` after any of these changes:
- Adding, removing, or renaming a column in any Drift table class
- Adding or removing a table class
- Changing the `@DriftDatabase(tables: [...])` annotation
- Modifying column constraints (e.g., `.nullable()`, `.unique()`, `.withDefault()`)
- Changing foreign key references (`.references()`)

You do **not** need to regenerate for changes to:
- Helper methods on `AppDatabase` (e.g., `saveEntry()`, `getAllEntriesWithDetails()`)
- Import statements or non-table code in `database.dart`
- Any file other than `database.dart`

## Code Style

- **No ternary operators** - use `if`/`else` blocks for readability
- **No hardcoded values or magic numbers** - use named constants. Layout values go in `lib/constants/layout.dart`, other values use `static const` on the class or named constants in `lib/constants/`
- **Use platform-adaptive widgets** - prefer `.adaptive` variants and platform-specific widgets wherever native theming differs between iOS and Android. Use `AlertDialog.adaptive()`, `SwitchListTile.adaptive()`, `AdaptiveSegmentedControl`, `AdaptivePickers`, etc. When building new UI, check if a Cupertino equivalent exists and use it on iOS. Existing adaptive widgets live in `lib/widgets/` (`adaptive_pickers.dart`, `adaptive_segmented_control.dart`).
- **Use Theme text styles** (`Theme.of(context).textTheme.bodyLarge`, etc.) instead of hardcoded `fontSize` values
- **Use theme-aware colors** (`Theme.of(context).colorScheme.*`) instead of hardcoded `Colors.grey.shade200` or similar
- **New constants** go in `lib/constants/` - not inline in screens
- Run `dart format .` before committing

## Architecture

**Layer structure:** Screens -> Services -> Database (Drift/SQLite)

- **Constants** (`lib/constants/`): Default symptom, tag, and mood lists (`defaults.dart`). All SharedPreferences keys and their defaults are centralized here. Also `changelog.dart` (structured changelog data for the in-app "What's New" dialog) and `build_info.dart` (build timestamp, updated only during releases).
- **Models** (`lib/models/`): Plain Dart classes (`SymptomEntryModel`, `UserSymptomModel`, `UserTagModel`) - not Drift-generated. `SymptomEntryModel` is named to avoid collision with Drift's generated `SymptomEntry` class.
- **Services** (`lib/services/`): `AppDatabase` (Drift ORM with high-level helper methods, provided via `Provider<AppDatabase>`), `EncryptionKeyService` (generates and stores the database encryption key in Android Keystore / iOS Keychain via `flutter_secure_storage`), `HomeWidgetService` (bridges app data to native home screen widgets via the `home_widget` package), `NotificationService` (scheduling + settings persistence), `ChangelogService` (version comparison for "What's New" modal via SharedPreferences), `PlatformService` (MethodChannel for OS-level settings like first day of week), `ExportService` (CSV/JSON data export), `ItemPreferencesService` (pin/hide preferences for symptoms, tags, moods), and `ShakeDetector` (accelerometer-based shake detection for feedback).
- **Screens** (`lib/screens/`): `CalendarScreen` (home/main view) -> `EntryScreen` (create/edit) -> `DetailScreen` (view/delete). `ManageItemsScreen` (settings hub: symptom/tag definitions, notification settings, appearance, data export, "What's New", "Clear All Data"). `ManageListScreen` (reusable list management with pin/hide/delete). `FeedbackScreen` (bug report / feedback submission via email).
- **Widgets** (`lib/widgets/`): Reusable components - `SeveritySelector`, `SymptomEntryWidget`, `ChangelogDialog` ("What's New" modal), `InfoTooltip`, `AdaptivePickers` (platform-native date/time pickers), `AdaptiveSegmentedControl` (platform-native segmented control).
- **App root** (`lib/app.dart`): `MyApp` widget - wraps widget tree with `Provider<AppDatabase>` and configures Material theming. Hosts app-wide `ValueNotifier`s for preferences (theme mode, shake-to-feedback, note/tag preview, calendar start day, system start day). Uses `WidgetsBindingObserver` to re-fetch system start day on app resume. Initializes `ShakeDetector` for feedback.
- **Entry point** (`lib/main.dart`): Thin bootstrap - creates `AppDatabase`, initializes notifications and home widget service, loads preferences, applies notification settings, sets up widget deep link handlers, runs `MyApp`.

**SharedPreferences usage:** Many app settings are stored in SharedPreferences (not Drift) - notifications, theme mode, calendar start day, note/tag preview, shake-to-feedback, pinned/hidden items, and last-seen changelog version. All keys and defaults are centralized in `constants/defaults.dart`. `NotificationService.applySettings()` reads prefs and calls `zonedSchedule()` or `cancelAll()`. Settings UI is in ManageItemsScreen.

**Changelog modal:** `constants/changelog.dart` defines structured entries per version -> `ChangelogService` compares last-seen version (SharedPreferences) against current version -> `ChangelogDialog` shows on first launch or after updates. Accessible manually via Settings > What's New.

**State management:** StatefulWidgets + `setState()` + `ValueNotifier` - no external state management package (Provider is only used for DI, not state).

**Dependency injection:** `provider` package. Screens access the database via `context.read<AppDatabase>()` in `didChangeDependencies()` with an `_initialized` guard to prevent re-initialization.

**Widget `build()` methods:** Keep business logic out of `build()` - precompute in state or helper methods.

### Home screen widgets

Both platforms have a "Today's Moods" home screen widget that mirrors the calendar entry list for today. Data flows from the Flutter app to native widgets via the `home_widget` package.

**Data flow:** Entry save/delete/clear -> `notifyEntriesChanged()` (in `app.dart`) -> `HomeWidgetService.updateWidgetData()` -> serializes today's entries to JSON in SharedPreferences (Android) / UserDefaults via App Group (iOS) -> native widget reads and renders.

**Deep links:** Widget taps use `wellnot://` URL scheme. The "+" button links to `wellnot://newentry`, entry rows link to `wellnot://entry/{id}`. Handlers in `main.dart` use `addPostFrameCallback` to schedule navigation after the widget tree is built (critical for cold starts). On iOS, all widget URLs must include `?homeWidget=true` query parameter - the `home_widget` plugin's `isWidgetUrl()` checks for this.

**Android (Jetpack Glance):**
- Widget: `android/.../glance/TodayMoodsWidget.kt` - Glance `GlanceAppWidget` reading from `HomeWidgetGlanceStateDefinition`
- Config: `android/.../glance/WidgetConfigActivity.kt` - Jetpack Compose activity with theme picker (light/dark/system), shown on widget placement. Writes theme to `HomeWidgetPreferences` SharedPreferences
- Constants: `android/.../glance/WidgetConstants.kt` - colors, dimensions, theme keys shared between widget and config
- Resources: `res/xml/today_moods_widget_info.xml` (widget metadata), `res/layout/today_moods_widget_preview.xml` (picker preview - must use only RemoteViews-compatible views: no `Space`, no `?android:attr/` theme references), `res/values/dimens.xml` (widget dimensions), `res/values/strings.xml` (widget strings), `res/drawable/widget_add_button_bg.xml` (teal circle), `res/values-night/colors.xml` (dark mode color overrides)
- Dependencies: `glance-appwidget`, `glance-material3` (widget rendering), `compose-bom` + `material3` + `activity-compose` (config activity)
- Receiver registered in `AndroidManifest.xml` with `APPWIDGET_CONFIGURE` pointing to `WidgetConfigActivity`

**iOS (WidgetKit):**
- Widget: `ios/WellnotWidgets/TodayMoodsWidget.swift` - SwiftUI `Widget` with `StaticConfiguration`, supports `.systemSmall` and `.systemMedium` families
- Data: reads from `UserDefaults(suiteName: "group.dev.alexo.Wellnot")` - the App Group shared with the main app
- Entitlements: `ios/WellnotWidgets/WellnotWidgets.entitlements` and `ios/Runner/Runner.entitlements` - both declare `group.dev.alexo.Wellnot` App Group
- Info.plist: `ios/WellnotWidgets/Info.plist` - must include `NSExtension` with `NSExtensionPointIdentifier = com.apple.widgetkit-extension`, uses `$(MARKETING_VERSION)` / `$(CURRENT_PROJECT_VERSION)` for version (not Flutter variables)
- Build phase order: "Embed Foundation Extensions" must come BEFORE "Thin Binary" in Runner's build phases to avoid dependency cycles
- No config screen (WidgetKit static config doesn't support placement-time configuration)
- Theme follows system automatically (no independent picker)
- iOS deployment target: 14.0 (required by `home_widget` package)

**Flutter-side constants:** `lib/constants/home_widget.dart` (widget names, SharedPreferences keys, App Group ID), `lib/constants/layout.dart` (widget layout dimensions shared between Dart and native code via mirrored constants in `WidgetConstants.kt` / `dimens.xml`)

## Database Schema (Drift)

**Encryption:** The database is encrypted at rest using SQLite3MultipleCiphers (configured via `hooks:` in `pubspec.yaml`). A random 256-bit key is generated per-install and stored in Android Keystore / iOS Keychain via `flutter_secure_storage`. The key is set via `PRAGMA key` in the `NativeDatabase` setup callback before Drift reads `user_version` or runs migrations. Existing plaintext databases are migrated in-place via `PRAGMA rekey` on first launch after the update. Key management is in `lib/services/encryption_key_service.dart`.

Five tables defined in `lib/services/database.dart`:

- `SymptomEntries` - log entries (id, entryDateTime, mood, notes)
- `UserSymptoms` - user-defined symptom names (unique)
- `UserTags` - user-defined tag names (unique)
- `SymptomEntryWithSymptom` - join table (many-to-many) **with `severity` column (int, default 3)**
- `SymptomEntryWithTag` - join table (many-to-many)

Schema version is currently **2**. Migration from v1 -> v2 adds the `severity` column to `SymptomEntryWithSymptom`. The generated file `database.g.dart` should not be manually edited.

### Schema migration pattern

When bumping `schemaVersion`, add migration logic in `AppDatabase.migration`:
```dart
@override
MigrationStrategy get migration => MigrationStrategy(
  onCreate: (m) async => await m.createAll(),
  onUpgrade: (m, from, to) async {
    if (from < 2) {
      await m.addColumn(table, table.newColumn);
    }
    // Add new `if (from < N)` blocks for future migrations
  },
);
```

### Key DB helper methods

All screens use these instead of raw Drift queries:
- `getAllEntriesWithDetails()` -> `List<SymptomEntryModel>` (replaces inline joins)
- `getEntryById(int id)` -> `SymptomEntryModel?` (single entry lookup for widget deep links)
- `saveEntry(...)` -> `int` (creates/updates entry + symptoms with severity + tags in a transaction)
- `deleteEntry(int id)` (transaction-based deletion)
- `getAllSymptoms()` / `getAllTags()` -> model lists
- `addSymptom(String)` / `addTag(String)` -> returns ID or -1 for duplicates
- `deleteSymptom(int)` / `deleteTag(int)` -> removes item + join table links
- `clearAllData()` -> deletes all entries, links, symptoms, and tags

## Cross-references between modules

| Module | Depends on | Consumed by |
|--------|-----------|-------------|
| `constants/defaults.dart` | - | `models/symptom_models.dart`, `screens/*`, `services/notification_service.dart`, `services/changelog_service.dart`, `app.dart` |
| `constants/layout.dart` | - | All screens, `widgets/*` |
| `constants/changelog.dart` | - | `services/changelog_service.dart`, `widgets/changelog_dialog.dart` |
| `models/symptom_models.dart` | - | All screens, `services/database.dart`, `widgets/*` |
| `services/database.dart` | `models/symptom_models.dart`, `services/encryption_key_service.dart` | All screens (via Provider) |
| `services/encryption_key_service.dart` | - | `services/database.dart` |
| `services/notification_service.dart` | `constants/defaults.dart` | `main.dart`, `screens/manage_items_screen.dart` |
| `services/changelog_service.dart` | `constants/defaults.dart`, `constants/changelog.dart` | `screens/calendar_screen.dart` |
| `services/platform_service.dart` | - | `app.dart` |
| `services/export_service.dart` | `services/database.dart` | `screens/manage_items_screen.dart` |
| `services/item_preferences_service.dart` | `constants/defaults.dart` | `screens/entry_screen.dart`, `screens/manage_list_screen.dart` |
| `services/home_widget_service.dart` | `constants/home_widget.dart`, `services/database.dart` | `main.dart`, `app.dart` |
| `constants/home_widget.dart` | - | `services/home_widget_service.dart` |
| `services/shake_detector.dart` | - | `app.dart` |
| `widgets/severity_selector.dart` | `constants/layout.dart`, `models/symptom_models.dart` | `widgets/symptom_entry_widget.dart` |
| `widgets/symptom_entry_widget.dart` | `constants/layout.dart`, `severity_selector.dart`, `models/symptom_models.dart` | `screens/entry_screen.dart` |
| `widgets/changelog_dialog.dart` | `constants/changelog.dart`, `constants/layout.dart` | `screens/calendar_screen.dart`, `screens/manage_items_screen.dart` |
| `app.dart` | `services/database.dart`, `services/home_widget_service.dart`, `services/platform_service.dart`, `services/shake_detector.dart`, `screens/calendar_screen.dart` | `main.dart` |

## Testing

### Test structure

```
test/
├── helpers/          # test_database.dart, mock_services.dart, widget_test_helpers.dart
├── unit/models/      # Model unit tests (equality, copyWith, severityLabel, defaults)
├── unit/services/    # DB unit tests + notification service settings tests
├── widget/widgets/   # SeveritySelector, SymptomEntryWidget, ChangelogDialog tests
└── widget/screens/   # CalendarScreen, EntryScreen, DetailScreen, ManageItemsScreen tests

integration_test/     # End-to-end tests (requires emulator)
```

### Testing approach

- **Test naming convention:** All test descriptions must follow a user story format: `'As a user, I expect <outcome> when <action/condition>'`. Add extra context at the end if needed (e.g., `-- regression test for severity data-loss bug`). This applies to both `test()` and `testWidgets()`.
- **TDD is mandatory.** For every feature or bug fix: (1) write failing tests first, (2) implement the feature, (3) verify tests pass. Do not start writing production code until tests exist that demonstrate the expected behavior.
- **In-memory database:** Tests use `AppDatabase.forTesting(NativeDatabase.memory())` via `test/helpers/test_database.dart`. Works on both Linux (`libsqlite3.so.0`) and macOS (`libsqlite3.dylib`).
- **Widget tests:** Use `pumpApp()` from `test/helpers/widget_test_helpers.dart` which wraps widgets in `Provider<AppDatabase>`.
- **Screen tests:** Some screens use `pumpAndSettle()`; `CalendarScreen` uses `pump()` due to `TableCalendar` animations. ManageItemsScreen tests use `SharedPreferences.setMockInitialValues({})` in `setUp`.
- **Notification settings tests:** Use `SharedPreferences.setMockInitialValues()` to test load/save round-trips without hitting disk.
- **Integration tests:** Require a connected device/emulator. Run with `flutter test integration_test/ -d <device-id>`.

## Severity labels

Canonical labels (1-5): **Very Mild, Mild, Moderate, Severe, Very Severe**. Defined in `UserSymptomModel.severityLabel()` and consumed by `SeveritySelector`.

## Platform-Specific Notes

- **Android**: Uses MethodChannels in `MainActivity.kt`: `com.symptom_tracker_app/exact_alarm` for exact alarm permission checks, `com.symptom_tracker_app/platform` for OS-level queries (e.g., first day of week). Requires `SCHEDULE_EXACT_ALARM` permission. Java 11 / core library desugaring enabled. JDK: Flutter should be configured to use Android Studio's bundled JBR via `flutter config --jdk-dir`.
- **iOS**: Standard Flutter notifications setup. iOS builds require macOS + Xcode.
- **iOS simulators**: Use `flutter run -d <simulator-id>` (debug mode only - simulators don't support release builds). List available: `xcrun simctl list devices available | grep -i iphone`.
- **Package ID**: `dev.alexo.symptom_tracker_app`

## Key Dependencies

- `drift` / `drift_dev` - type-safe SQLite ORM with code generation
- `provider` - dependency injection for `AppDatabase`
- `table_calendar` - calendar UI widget
- `flutter_local_notifications` - daily reminder notifications (uses `zonedSchedule` for time-specific scheduling)
- `shared_preferences` - persists app settings (notifications, theme, calendar, changelog, pin/hide preferences)
- `timezone` - timezone-aware scheduling for notifications at a specific local time
- `android_intent_plus` - Android intent support for alarm settings
- `package_info_plus` - reads app version at runtime (used by changelog modal)
- `home_widget` - data bridge between Flutter and native home screen widgets (SharedPreferences on Android, UserDefaults via App Groups on iOS)
- `intl` - date formatting
- `mocktail` - mocking framework for tests
- `sqlite3` - native SQLite bundled via build hooks; configured with `source: sqlite3mc` for SQLite3MultipleCiphers encryption support
- `flutter_secure_storage` - stores the database encryption key in Android Keystore / iOS Keychain

## Theming

Material Design 3 with `Colors.teal` as the color scheme seed. Supports system light/dark mode.

## CI Pipeline

CI runs on every PR targeting `main` (`.github/workflows/ci.yml`):

1. **PR title check** - must follow conventional commit format (enforced by `amannn/action-semantic-pull-request`)
2. **Changelog fragment check** - user-facing PRs (`feat:`, `fix:`, `perf:`) must include a Changie fragment
3. **Format check** - `dart format --set-exit-if-changed .`
4. **Static analysis** - `flutter analyze`
5. **Tests** - `flutter test`

## Changelog Workflow (Changie)

[Changie](https://changie.dev/) manages changelog fragments - small YAML files created per PR that describe user-facing changes.

### Developer workflow (PR authors)

When a PR includes user-facing changes (features, fixes, improvements), create a changelog fragment:

```bash
changie new
```

This prompts for:
- **Kind**: `feature`, `fix`, or `improvement`
- **Body**: Plain-language description (user-facing, no jargon)
- **Platform**: `all` (default), `android`, or `ios`

The fragment is saved to `.changes/unreleased/<timestamp>.yaml`. Commit it with your PR.

CI enforces that `feat:`, `fix:`, and `perf:` PRs include a fragment. Add the `skip-changelog` label to bypass for non-user-facing changes.

### Non-interactive fragment creation

For CI or scripted usage:

```bash
changie new -k feature -b "Description here" -m Platform=all
```

### Installing Changie

Changie is managed via asdf and pinned in `.tool-versions` for reproducibility:

```bash
asdf plugin add changie
asdf install changie
```

## Pre-commit Hooks

The project uses [pre-commit](https://pre-commit.com/). Run `pre-commit install` after cloning. Hooks auto-run `dart format` and `flutter analyze` on every commit, plus file hygiene checks (trailing whitespace, EOF newline, merge conflict markers, YAML validation, private key detection).

## Branching & Commit Conventions

- **Branches:** New features go on `feature/<feature-name>` branches, bug fixes on `fix/<description>`. PRs target `main`.
- **Never commit directly to main** - always create a branch and PR for features and bug fixes.
- **Versioning:** Semantic versioning (`vMAJOR.MINOR.PATCH`).
- **Commits:** Follow [Conventional Commits](https://www.conventionalcommits.org/): `feat:`, `fix:`, `docs:`, `chore:`, `test:`, `refactor:`.
- **AI attribution:** All AI-assisted commits must include a `Co-Authored-By` trailer (e.g., `Co-Authored-By: Claude <noreply@anthropic.com>`). PRs must note which AI tool was used.
- **Committing workflow:** Stage and commit features individually - don't batch unrelated changes.
