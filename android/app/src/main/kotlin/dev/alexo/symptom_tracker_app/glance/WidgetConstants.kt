package dev.alexo.symptom_tracker_app.glance

import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

// ---------------------------------------------------------------------------
// Colors — matching the Flutter app's teal color scheme
// ---------------------------------------------------------------------------

/// Primary teal color (Material Design "teal 500").
val WidgetTealPrimary = Color(0xFF009688)

/// Muted gray for secondary text (empty states, subtitles).
val WidgetSubtleGray = Color(0xFF9E9E9E)

// Light theme colors
val WidgetLightBackground = Color(0xFFFFFFFF)
val WidgetLightOnSurface = Color(0xFF212121)

// Dark theme colors
val WidgetDarkBackground = Color(0xFF1C1B1F)
val WidgetDarkOnSurface = Color(0xFFE0E0E0)

/// SharedPreferences key for the widget theme preference.
const val WidgetThemeKey = "widget_theme"

/// Possible theme values.
const val WidgetThemeLight = "light"
const val WidgetThemeDark = "dark"
const val WidgetThemeSystem = "system"

// ---------------------------------------------------------------------------
// Layout dimensions — mirrors lib/constants/layout.dart values
// ---------------------------------------------------------------------------

/// Corner radius for the widget container.
val WidgetCornerRadius = 16.dp

/// Overall padding inside the widget container.
val WidgetPadding = 12.dp

/// Spacing between the header and the entry list.
val WidgetHeaderBottomSpacing = 8.dp

/// Vertical padding for each entry row.
val WidgetEntryVerticalPadding = 4.dp

/// Horizontal spacing between time and mood-symptoms text.
val WidgetEntryHorizontalSpacing = 8.dp

/// Size of the circular "+" add-entry button.
val WidgetAddButtonSize = 28.dp

// ---------------------------------------------------------------------------
// Typography — font sizes for widget text elements
// ---------------------------------------------------------------------------

/// Font size for the widget header title ("Today").
val WidgetHeaderFontSize = 14.sp

/// Font size for entry time text (e.g., "9:30 AM").
val WidgetTimeFontSize = 13.sp

/// Font size for entry content text (e.g., "😊 - Headache, Fatigue").
val WidgetContentFontSize = 14.sp

/// Font size for the "+" text inside the add button.
val WidgetAddButtonFontSize = 18.sp

// ---------------------------------------------------------------------------
// Config screen dimensions
// ---------------------------------------------------------------------------

/// Horizontal padding for the config screen content.
val ConfigHorizontalPadding = 24.dp

/// Vertical padding for the config screen content.
val ConfigVerticalPadding = 16.dp

/// Spacing between the preview card and the description text.
val ConfigDescriptionSpacing = 24.dp

/// Spacing between sample entry rows in the config preview.
val ConfigSampleEntrySpacing = 8.dp

/// Spacing between the header row and entries in the config preview.
val ConfigPreviewHeaderSpacing = 12.dp

/// Elevation for the config preview card.
val ConfigCardElevation = 4.dp

/// Size of the "+" icon inside the config preview add button.
val ConfigAddIconSize = 18.dp
