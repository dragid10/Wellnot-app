// constants/home_widget.dart: Widget name and key constants for home screen widgets
//
// Centralizes all identifiers used by the home_widget package to share data
// between the Flutter app and native widget code (Jetpack Glance on Android,
// WidgetKit on iOS).
//
// Cross-ref:
//   - Data bridge: services/home_widget_service.dart
//   - Android widgets: android/app/src/main/kotlin/.../glance/
//   - iOS widgets: ios/WellnotWidgets/

/// iOS App Group ID — must match the App Group configured in Xcode for both
/// the Runner target and the WellnotWidgets extension target.
const String appGroupId = 'group.dev.alexo.Wellnot';

/// Android widget receiver qualified class name.
/// Must match the receiver class registered in AndroidManifest.xml.
const String androidTodayMoodsReceiver =
    'dev.alexo.symptom_tracker_app.glance.TodayMoodsReceiver';

/// iOS widget kind identifier.
/// Must match the `kind` string in the SwiftUI Widget struct.
const String iosTodayMoodsWidgetKind = 'TodayMoodsWidget';

// ---------------------------------------------------------------------------
// SharedPreferences / UserDefaults keys for widget data
// ---------------------------------------------------------------------------

/// JSON array of today's entries. Each element:
/// {"time":"2:30 PM","mood":"😊","symptoms":"Headache, Nausea"}
const String widgetKeyTodayEntries = 'widget_today_entries';

/// ISO date string (yyyy-MM-dd) indicating which day the entries belong to.
/// Native widgets compare this against today to detect stale data.
const String widgetKeyTodayDate = 'widget_today_date';

/// Widget theme preference. Values: 'light', 'dark', 'system'.
/// Independent from the app's theme mode and the system theme.
const String widgetKeyTheme = 'widget_theme';

/// Default widget theme — follows the system setting.
const String widgetThemeDefault = 'system';
