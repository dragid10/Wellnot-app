// constants/layout.dart: Centralized spacing and sizing constants
//
// Extracts hardcoded pixel values from screens and widgets so they can be
// adjusted in one place. All values use logical pixels (density-independent).
//
// These follow the Material Design 4px/8px spacing grid.
//
// Cross-ref:
//   - Consumed by all screens under lib/screens/
//   - Consumed by all widgets under lib/widgets/

/// Extra-small spacing — tight gaps (e.g., between a title and its content).
const double spacingXs = 4.0;

/// Small spacing — standard gap between related elements.
const double spacingSm = 8.0;

/// Medium spacing — spacing between subsections or between a label and content.
const double spacingMd = 12.0;

/// Large spacing — standard page padding, section separation.
const double spacingLg = 16.0;

/// Extra-large spacing — prominent gaps (e.g., above a primary action button).
const double spacingXl = 20.0;

/// Horizontal spacing between chips in a Wrap layout.
const double chipSpacing = 8.0;

/// Vertical run-spacing between rows of chips in a Wrap layout.
const double chipRunSpacing = 8.0;

/// Vertical padding inside the primary action button (e.g., Save, Clear All Data).
const double buttonVerticalPadding = 14.0;

/// Total height of the Cupertino picker bottom sheet (toolbar + spinning wheel).
const double cupertinoPickerSheetHeight = 300.0;

/// Multiplier applied to the default body font size to compute emoji sizes.
///
/// Emojis are rendered at `defaultFontSize * emojiScaleLarge` for input
/// contexts (mood selector) and `defaultFontSize * emojiScaleSmall` for
/// display contexts (detail screen).
const double emojiScaleLarge = 2.0;
const double emojiScaleSmall = 1.7;

// ---------------------------------------------------------------------------
// Calendar layout
// ---------------------------------------------------------------------------

/// Screen height breakpoint below which the calendar uses compact sizing.
///
/// Devices under ~700dp logical height (e.g., Galaxy S9 at 5.8") get smaller
/// row heights so the entry list has more room. See #117.
const double calendarCompactHeightBreakpoint = 700.0;

/// Calendar row height for compact screens (< [calendarCompactHeightBreakpoint]).
const double calendarRowHeightCompact = 40.0;

/// Calendar row height for normal/large screens.
const double calendarRowHeightDefault = 52.0;

/// Day-of-week header height for compact screens.
///
/// The default TableCalendar value (16.0) clips labels on some devices (#71),
/// so even compact mode stays above that.
const double calendarDaysOfWeekHeightCompact = 20.0;

/// Day-of-week header height for normal/large screens. See #71.
const double calendarDaysOfWeekHeightDefault = 24.0;

// ---------------------------------------------------------------------------
// Home screen widget layout
// ---------------------------------------------------------------------------

/// Corner radius for the home screen widget container.
const double widgetCornerRadius = 16.0;

/// Size of the "+" add-entry button in the widget header.
const double widgetAddButtonSize = 28.0;

/// Font size for mood emoji text in the widget entry list.
const double widgetMoodFontSize = 24.0;

/// Font size for entry time text in the widget entry list.
const double widgetTimeFontSize = 13.0;

/// Font size for entry content text in the widget entry list.
const double widgetContentFontSize = 14.0;

/// Font size for the widget header title.
const double widgetHeaderFontSize = 14.0;

/// Font size for the "+" text inside the add button.
const double widgetAddButtonFontSize = 18.0;

// ---------------------------------------------------------------------------
// Dialog layout
// ---------------------------------------------------------------------------

/// Width threshold for wide-screen dialog layout (tablets, landscape).
///
/// CupertinoAlertDialog has a fixed narrow width (~270dp) that doesn't adapt
/// to tablets, so dialogs above this breakpoint use Material styling instead.
const double wideScreenBreakpoint = 600.0;

/// Maximum content width for dialogs on wide screens.
const double dialogMaxWidth = 500.0;

// ---------------------------------------------------------------------------
// Achievement toast
// ---------------------------------------------------------------------------

/// How long each achievement toast stays visible before auto-dismissing.
const Duration achievementToastDuration = Duration(seconds: 3);

// ---------------------------------------------------------------------------
// Chip group collapse
// ---------------------------------------------------------------------------

/// Number of non-pinned, non-selected items visible before the chip group
/// collapses behind a "Show all" toggle. Keeps the entry screen scrollable
/// on devices with hundreds of symptoms or tags.
const int chipGroupCollapsedThreshold = 20;
