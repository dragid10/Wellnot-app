# Wellnot

A mobile app for tracking your daily symptoms, moods, and health patterns. All data stays on your device — no account or internet connection required.

## Table of Contents

- [Features](#features)
- [Screenshots](#screenshots)
- [How It Works](#how-it-works)
- [Getting Started](#getting-started)
- [Dev Environment Setup](#dev-environment-setup)
- [Project Structure](#project-structure)
- [Privacy Policy](#privacy-policy)
- [Contributing](#contributing)

## Features

- **Calendar view** — browse your symptom history by date
- **Symptom logging** — record symptoms with a severity scale (Very Mild → Very Severe)
- **Mood tracking** — log your mood alongside symptoms
- **Tags** — categorize entries with tags like "Before Meal", "Chronic", "Urgent", and more
- **Custom symptoms & tags** — create your own to fit your needs
- **Pin & hide** — pin your most-used symptoms and tags to the top, hide ones you don't need
- **Date range summary** — see mood, symptom, and tag patterns at a glance for any date range
- **Home screen widget** — "Today's Moods" widget shows today's entries with a quick-add button (Android + iOS)
- **Data export** — export your data to CSV or JSON
- **App lock** — protect your data with biometrics or device PIN
- **Onboarding walkthrough** — guided introduction to app features on first launch
- **"What's New" dialog** — see what changed after each update, accessible from Settings
- **Configurable reminders** — toggle daily notifications on/off and pick your preferred reminder time
- **Dark mode** — light, dark, or follow system theme
- **Shake to report** — shake your device to quickly send feedback
- **Fully offline** — everything is stored locally on your device, excluded from cloud backups

## Screenshots

_Coming soon_

## How It Works

1. **Log an entry** — tap a date on the calendar to record your symptoms, mood, tags, and any notes
2. **Review your history** — scroll through the calendar to see which days have entries and view past logs
3. **Check your trends** — select a date range to see a summary of your most frequent symptoms, moods, and tags
4. **Manage your symptoms & tags** — add, remove, pin, or hide symptoms and tags from Settings
5. **Stay on track** — the app sends a daily reminder so you never miss a day
6. **Quick access** — add the home screen widget to see today's entries at a glance

## Getting Started

Wellnot is built with [Flutter](https://flutter.dev) and runs on both Android and iOS.

```bash
flutter pub get
flutter run
```

## Dev Environment Setup

For full setup instructions including pre-commit hooks, code generation, and testing, see the [Dev Environment Setup](CONTRIBUTING.md#dev-environment-setup) section in the contributing guide.

Quick start:

```bash
flutter pub get          # Install dependencies
pre-commit install       # Set up Git hooks
flutter test             # Verify everything works
```

## Project Structure

```
lib/
├── app.dart                          # MyApp root widget (Provider, theming, overlays)
├── main.dart                         # Entry point (bootstrap + runApp)
├── constants/
│   ├── build_info.dart               # Build timestamp (updated at release time)
│   ├── changelog.dart                # In-app changelog (auto-generated — do not edit)
│   ├── defaults.dart                 # Default symptoms, tags, moods, pref keys
│   ├── home_widget.dart              # Home screen widget constants
│   ├── layout.dart                   # Spacing, sizing, and layout constants
│   ├── onboarding.dart               # Onboarding page definitions + layout constants
│   └── summary.dart                  # Date range summary constants
├── models/
│   ├── summary_models.dart           # DateRangeSummary model
│   └── symptom_models.dart           # SymptomEntryModel, UserSymptomModel, UserTagModel
├── services/
│   ├── changelog_service.dart        # Version comparison for "What's New" modal
│   ├── database.dart                 # Drift schema + AppDatabase + helper methods
│   ├── database.g.dart               # Generated Drift code (DO NOT EDIT)
│   ├── export_service.dart           # CSV/JSON data export
│   ├── home_widget_service.dart      # Data bridge to native home screen widgets
│   ├── item_preferences_service.dart # Pin/hide preferences for symptoms, tags, moods
│   ├── notification_service.dart     # Notification scheduling + settings
│   ├── platform_service.dart         # MethodChannel for OS-level queries
│   ├── preferences_service.dart      # SharedPreferences loader/saver for app settings
│   └── shake_detector.dart           # Accelerometer-based shake detection for feedback
├── screens/
│   ├── calendar_screen.dart          # Home — calendar view
│   ├── detail_screen.dart            # View entry details
│   ├── entry_screen.dart             # Create/edit symptom entry
│   ├── feedback_screen.dart          # Bug report / feedback submission
│   ├── filtered_entries_screen.dart  # Filtered entry list (e.g., by symptom/tag)
│   ├── lock_screen.dart              # App lock (biometric/PIN)
│   ├── manage_items_screen.dart      # Settings hub
│   ├── manage_list_screen.dart       # Reusable list management (pin/hide/delete)
│   ├── onboarding_screen.dart        # First-launch onboarding walkthrough
│   ├── summary_screen.dart           # Date range summary view
│   └── settings/                     # Settings sub-screens
│       ├── about_screen.dart
│       ├── calendar_settings_screen.dart
│       ├── clear_reset_screen.dart
│       ├── display_settings_screen.dart
│       ├── export_data_screen.dart
│       ├── reminders_settings_screen.dart
│       ├── security_settings_screen.dart
│       └── theme_settings_screen.dart
└── widgets/
    ├── adaptive_pickers.dart         # Platform-native date/time pickers
    ├── adaptive_segmented_control.dart # Platform-native segmented control
    ├── changelog_dialog.dart         # "What's New" modal
    ├── info_tooltip.dart             # Info icon with tooltip
    ├── severity_selector.dart        # Severity rating input
    └── symptom_entry_widget.dart     # Symptom display/edit card

test/
├── helpers/                          # Shared test utilities
│   ├── test_database.dart            # In-memory DB factory for tests
│   ├── mock_services.dart            # Mock services
│   └── widget_test_helpers.dart      # pumpApp() helper with Provider
├── unit/
│   ├── models/                       # Model unit tests
│   └── services/                     # Database, preferences, export, notification tests
└── widget/
    ├── screens/                      # Screen-level widget tests
    │   └── settings/                 # Settings sub-screen tests
    └── widgets/                      # Widget-level tests

integration_test/
└── app_test.dart                     # End-to-end integration tests
```

| Folder | Purpose |
|--------|---------|
| `constants/` | App-wide constants (defaults, layout, changelog, onboarding, home widget) |
| `models/` | Plain Dart data classes used throughout the app (not Drift-generated) |
| `services/` | Database (Drift ORM), preferences, notifications, export, platform services |
| `screens/` | Full-screen widgets corresponding to app routes |
| `screens/settings/` | Settings sub-screens (theme, reminders, export, security, etc.) |
| `widgets/` | Reusable UI components used by screens |
| `test/helpers/` | Shared utilities for setting up test databases and pumping widgets |
| `test/unit/` | Fast unit tests for models, database, and service operations |
| `test/widget/` | Widget tests that verify UI rendering and interaction |
| `integration_test/` | End-to-end tests that exercise the full app (requires emulator) |

## Privacy Policy

[Privacy Policy](PRIVACY_POLICY.md) | [Medical Disclaimer](MEDICAL_DISCLAIMER.md)

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for branching conventions, commit message format, code style guidelines, testing expectations, and pre-commit hook setup.
