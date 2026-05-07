// calendar_screen.dart: Main calendar view for symptom tracking
//
// This is the home screen. It displays a calendar with symptom entry markers,
// and a list of entries for the selected day.
//
// Cross-ref:
//   - Navigates to: entry_screen.dart (create), detail_screen.dart (view)
//   - Settings gear navigates to: manage_items_screen.dart
//   - Uses AppDatabase.getAllEntriesWithDetails() from services/database.dart
//   - Entry model: models/symptom_models.dart (SymptomEntryModel)
//   - Database obtained via Provider (see main.dart)
//   - Coach marks: showcaseview package, preferences_service.dart
//     (hasSeenCoachMarksNotifier), constants/defaults.dart
//     (prefKeyHasSeenCoachMarks)

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:table_calendar/table_calendar.dart';
import '../app.dart';
import '../constants/achievements.dart';
import '../constants/encryption_recovery.dart';
import '../constants/layout.dart';
import '../services/encryption_recovery_service.dart';
import '../services/preferences_service.dart';
import '../models/symptom_models.dart';
import '../services/changelog_service.dart';
import '../services/database.dart';
import '../widgets/changelog_dialog.dart';
import 'achievements_screen.dart';
import 'entry_screen.dart';
import 'detail_screen.dart';
import 'manage_items_screen.dart';
import 'summary_screen.dart';

/// Home screen — shows a month-view calendar with entry markers and a
/// scrollable list of entries for the currently selected day.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  /// Notifies the entry list whenever the selected day's events change.
  late final ValueNotifier<List<SymptomEntryModel>> _selectedEvents;

  /// All entries grouped by date (midnight-normalized keys).
  Map<DateTime, List<SymptomEntryModel>> _events = {};

  /// The month currently visible in the calendar.
  DateTime _focusedDay = DateTime.now();

  /// The day the user has tapped; drives the entry list below the calendar.
  DateTime? _selectedDay;

  late AppDatabase _database;
  bool _initialized = false;

  // ---------------------------------------------------------------------------
  // Coach marks (showcaseview)
  //
  // Interactive tooltips that highlight key UI elements on the calendar screen.
  // Shown once after the user completes the onboarding walkthrough (or on first
  // load for existing users who haven't seen them yet). The seen-flag is
  // persisted via PreferencesService.hasSeenCoachMarksNotifier.
  //
  // Cross-ref:
  //   - Preference keys: constants/defaults.dart (prefKeyHasSeenCoachMarks)
  //   - Preference load/save: services/preferences_service.dart
  //   - Onboarding trigger: app.dart (_completeOnboarding)
  // ---------------------------------------------------------------------------

  /// ShowcaseView controller — registered in initState, unregistered in dispose.
  late final ShowcaseView _showcaseView;

  /// GlobalKey for the calendar widget showcase step.
  final GlobalKey _calendarKey = GlobalKey();

  /// GlobalKey for the add-entry button showcase step.
  /// Shared between the Android FAB and iOS AppBar button since they
  /// are mutually exclusive (only one is in the widget tree at a time).
  final GlobalKey _addEntryKey = GlobalKey();

  /// GlobalKey for the summary/insights button showcase step.
  final GlobalKey _summaryKey = GlobalKey();

  /// GlobalKey for the achievements button showcase step.
  /// Skipped automatically when achievements are disabled (widget not in tree).
  final GlobalKey _achievementsKey = GlobalKey();

  /// GlobalKey for the settings button showcase step.
  final GlobalKey _settingsKey = GlobalKey();

  /// Timer for the coach marks startup delay. Stored so it can be cancelled
  /// in [dispose] to avoid pending-timer assertions in widget tests.
  Timer? _coachMarksTimer;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
    // Listen for entry changes from any source (e.g., persistent notification).
    entriesChangedNotifier.addListener(_loadEvents);
    achievementUnlockedNotifier.addListener(_showAchievementToast);

    // Register the showcase controller for interactive coach marks.
    // skipIfTargetNotPresent handles platform-conditional widgets (e.g., FAB
    // on Android vs AppBar button on iOS) by skipping missing targets.
    _showcaseView = ShowcaseView.register(
      onFinish: _onCoachMarksFinished,
      onDismiss: (_) => _onCoachMarksFinished(),
      skipIfTargetNotPresent: true,
    );

    // Listen for onboarding completion so the changelog and coach marks
    // trigger in sequence after the user finishes the walkthrough.
    PreferencesService.hasSeenOnboardingNotifier.addListener(
      _onOnboardingCompleted,
    );

    // Show the "What's New" or welcome dialog after the first frame renders,
    // check for encryption migration issues, and trigger coach marks for
    // existing users who haven't seen them yet.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _checkEncryptionMigrationFlag();
      await _checkChangelog();
      _maybeStartCoachMarks();
    });
  }

  @override
  void dispose() {
    entriesChangedNotifier.removeListener(_loadEvents);
    achievementUnlockedNotifier.removeListener(_showAchievementToast);
    PreferencesService.hasSeenOnboardingNotifier.removeListener(
      _onOnboardingCompleted,
    );
    _coachMarksTimer?.cancel();
    _showcaseView.unregister();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _database = context.read<AppDatabase>();
      _initialized = true;
      _loadEvents();
    }
  }

  /// Fetches entries for the currently focused month and groups them by date.
  ///
  /// Only loads entries within the visible month (plus a 1-week buffer on
  /// each side for calendar edge days that spill into adjacent months).
  /// This avoids loading the entire entry history on every refresh.
  ///
  /// Each entry's dateTime is normalized to midnight so it can be used as a
  /// map key for the calendar's `eventLoader`.
  void _loadEvents() async {
    try {
      // Buffer of 7 days on each side covers the partial weeks that
      // TableCalendar displays from the previous/next months.
      final monthStart = DateTime(_focusedDay.year, _focusedDay.month, 1);
      final monthEnd =
          DateTime(_focusedDay.year, _focusedDay.month + 1, 0, 23, 59, 59);
      final from = monthStart.subtract(const Duration(days: 7));
      final to = monthEnd.add(const Duration(days: 7));

      final allEntries = await _database.getEntriesForDateRange(from, to);

      final Map<DateTime, List<SymptomEntryModel>> eventsMap = {};
      for (final entry in allEntries) {
        // Normalize to midnight for use as a date-only map key.
        final dateKey = DateTime(
          entry.dateTime.year,
          entry.dateTime.month,
          entry.dateTime.day,
        );
        eventsMap.putIfAbsent(dateKey, () => []).add(entry);
      }

      // Sort each day's entries by time so the list displays chronologically.
      for (final entries in eventsMap.values) {
        entries.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      }

      if (mounted) {
        setState(() {
          _events = eventsMap;
          _selectedEvents.value = _getEventsForDay(_selectedDay!);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load entries: $e')),
        );
      }
    }
  }

  /// Queue of achievement IDs waiting to be shown as toasts.
  final List<String> _achievementToastQueue = [];

  /// Whether a toast is currently being displayed.
  bool _isShowingAchievementToast = false;

  /// Shows congratulatory SnackBars for each newly unlocked achievement,
  /// one at a time. Each toast auto-dismisses after [achievementToastDuration],
  /// then the next one in the queue appears.
  void _showAchievementToast() {
    final achievementIds = achievementUnlockedNotifier.value;
    if (achievementIds.isEmpty || !mounted) return;
    if (!PreferencesService.achievementNotificationsNotifier.value) return;

    _achievementToastQueue.addAll(achievementIds);
    if (!_isShowingAchievementToast) {
      _showNextAchievementToast();
    }
  }

  /// Pops the next achievement from the queue and shows its toast.
  void _showNextAchievementToast() {
    if (_achievementToastQueue.isEmpty || !mounted) {
      _isShowingAchievementToast = false;
      return;
    }

    _isShowingAchievementToast = true;
    final achievementId = _achievementToastQueue.removeAt(0);

    final definition = allAchievements.where(
      (achievement) => achievement.id == achievementId,
    );
    if (definition.isEmpty) {
      _showNextAchievementToast();
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.emoji_events,
                    color: Theme.of(context).colorScheme.inversePrimary),
                const SizedBox(width: spacingSm),
                Expanded(
                    child: Text(
                        'Achievement unlocked: ${definition.first.unlockedName ?? definition.first.name}')),
              ],
            ),
            duration: achievementToastDuration,
            persist: false,
            action: SnackBarAction(
              label: 'View',
              onPressed: () {
                _navigateToAchievement(achievementId);
              },
            ),
          ),
        )
        .closed
        .then((_) {
      _showNextAchievementToast();
    });
  }

  /// Navigates to the achievement in the achievements screen.
  /// If the screen is already open, scrolls to the achievement instead
  /// of pushing a duplicate.
  void _navigateToAchievement(String achievementId) {
    if (AchievementsScreen.isMounted) {
      achievementScrollToNotifier.value = achievementId;
    } else {
      achievementScrollToNotifier.value = achievementId;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AchievementsScreen(),
        ),
      );
    }
  }

  /// Returns the list of entries for a given [day], or an empty list if none.
  ///
  /// Used by TableCalendar's `eventLoader` to render dot markers, and by
  /// the ValueListenableBuilder to populate the entry list.
  List<SymptomEntryModel> _getEventsForDay(DateTime day) {
    final dateKey = DateTime(day.year, day.month, day.day);
    return _events[dateKey] ?? [];
  }

  /// Called when the user taps a day on the calendar. Updates the selected
  /// day and refreshes the entry list below the calendar.
  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
      _selectedEvents.value = _getEventsForDay(selectedDay);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wellnot'),
        actions: [
          // Summary button — opens the date range summary screen.
          // Wrapped in Showcase for the coach marks tour.
          Showcase(
            key: _summaryKey,
            title: 'Insights',
            description: 'View trends and patterns in your symptom data.',
            tooltipBackgroundColor:
                Theme.of(context).colorScheme.primaryContainer,
            textColor: Theme.of(context).colorScheme.onPrimaryContainer,
            child: IconButton(
              icon: const Icon(Icons.insights),
              tooltip: 'Summary',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SummaryScreen(),
                  ),
                );
              },
            ),
          ),
          // Achievements button — opens the achievements screen.
          // Hidden when achievements are disabled in settings.
          // Wrapped in Showcase for the coach marks tour.
          ValueListenableBuilder<bool>(
            valueListenable: PreferencesService.achievementsEnabledNotifier,
            builder: (context, enabled, _) {
              if (!enabled) return const SizedBox.shrink();
              return Showcase(
                key: _achievementsKey,
                title: 'Achievements',
                description:
                    'Track your milestones and unlock badges as you log entries.',
                tooltipBackgroundColor:
                    Theme.of(context).colorScheme.primaryContainer,
                textColor: Theme.of(context).colorScheme.onPrimaryContainer,
                child: IconButton(
                  icon: const Icon(Icons.emoji_events),
                  tooltip: 'Achievements',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AchievementsScreen(),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          // Add entry button in AppBar — iOS only (iOS doesn't use FABs).
          // Android uses a FloatingActionButton instead (see below).
          // Shares _addEntryKey with the Android FAB for coach marks
          // since only one is in the tree at a time.
          if (Theme.of(context).platform == TargetPlatform.iOS &&
              _selectedDay != null &&
              !_selectedDay!.isAfter(DateTime.now()))
            Showcase(
              key: _addEntryKey,
              title: 'Add Entry',
              description:
                  'Tap to log symptoms, mood, and tags for the selected day.',
              tooltipBackgroundColor:
                  Theme.of(context).colorScheme.primaryContainer,
              textColor: Theme.of(context).colorScheme.onPrimaryContainer,
              child: IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _navigateToNewEntry(),
              ),
            ),
          // "Today" button — jumps back to the current date.
          // Always visible, but greyed out when already viewing today.
          IconButton(
            icon: Icon(
              Icons.today,
              color: _isViewingToday() ? Theme.of(context).disabledColor : null,
            ),
            tooltip: 'Today',
            onPressed: _isViewingToday()
                ? null
                : () {
                    final now = DateTime.now();
                    setState(() {
                      _focusedDay = now;
                      _selectedDay = now;
                    });
                    _selectedEvents.value = _getEventsForDay(now);
                  },
          ),
          // Settings button — navigates to the settings screen.
          // Wrapped in Showcase for the coach marks tour.
          Showcase(
            key: _settingsKey,
            title: 'Settings',
            description: 'Manage symptoms, tags, reminders, appearance, '
                'and more.',
            tooltipBackgroundColor:
                Theme.of(context).colorScheme.primaryContainer,
            textColor: Theme.of(context).colorScheme.onPrimaryContainer,
            child: IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ManageItemsScreen(),
                  ),
                );
                // Reload events and update widgets in case entries were
                // modified (e.g., Clear All Data).
                notifyEntriesChanged();
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Calendar widget — wrapped in Showcase for the coach marks
            // tour, then a ListenableBuilder that rebuilds when the start
            // day preference or system start day changes.
            Showcase(
              key: _calendarKey,
              title: 'Your Calendar',
              description: 'Tap any day to see your entries. '
                  'Days with dots have logged symptoms.',
              tooltipBackgroundColor:
                  Theme.of(context).colorScheme.primaryContainer,
              textColor: Theme.of(context).colorScheme.onPrimaryContainer,
              child: ListenableBuilder(
                listenable: Listenable.merge([
                  PreferencesService.calendarStartDayNotifier,
                  PreferencesService.systemStartDayNotifier,
                ]),
                builder: (context, _) {
                  final screenHeight = MediaQuery.of(context).size.height;
                  final isCompact =
                      screenHeight < calendarCompactHeightBreakpoint;
                  return TableCalendar<SymptomEntryModel>(
                    firstDay: DateTime.utc(2000, 1, 1),
                    lastDay: DateTime.now(),
                    focusedDay: _focusedDay,
                    // Adapt row height to screen size so smaller devices
                    // (e.g., Galaxy S9) leave more room for the entry list.
                    // See #117. Day-of-week height stays above 16.0 to
                    // avoid label clipping (#71).
                    rowHeight: isCompact
                        ? calendarRowHeightCompact
                        : calendarRowHeightDefault,
                    daysOfWeekHeight: isCompact
                        ? calendarDaysOfWeekHeightCompact
                        : calendarDaysOfWeekHeightDefault,
                    startingDayOfWeek: PreferencesService.resolveStartDay(
                      PreferencesService.calendarStartDayNotifier.value,
                    ),
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: _onDaySelected,
                    eventLoader: _getEventsForDay,
                    // Lock to month view — the format toggle button ("2 weeks")
                    // is hidden since the app only uses the month view.
                    availableCalendarFormats: const {
                      CalendarFormat.month: 'Month'
                    },
                    // Disable future dates — users can only log for today or past days.
                    enabledDayPredicate: (day) {
                      final now = DateTime.now();
                      final today = DateTime(now.year, now.month, now.day);
                      final checkDay = DateTime(day.year, day.month, day.day);
                      return !checkDay.isAfter(today);
                    },
                    // Calendar styling — uses Material 3 color scheme tokens.
                    calendarStyle: CalendarStyle(
                      // Use onSurfaceVariant for marker dots — a neutral tone
                      // that's visible in both light and dark mode without
                      // blending into the primary-colored selected day bubble.
                      markerDecoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      // Weekends use the same text color as weekdays (no special styling).
                      weekendDecoration: const BoxDecoration(
                        color: Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      weekendTextStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      disabledDecoration: const BoxDecoration(
                        color: Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      disabledTextStyle: TextStyle(color: Colors.grey.shade600),
                    ),
                    onPageChanged: (focusedDay) {
                      setState(() {
                        _focusedDay = focusedDay;
                      });
                      // Reload entries for the newly visible month.
                      _loadEvents();
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1),
            // Entry list — rebuilds only when the selected day's events change.
            // Tag/note preview toggles are scoped to each ListTile's subtitle
            // via a narrower ListenableBuilder, so toggling a preview doesn't
            // rebuild the entire list.
            Expanded(
              child: ValueListenableBuilder<List<SymptomEntryModel>>(
                valueListenable: _selectedEvents,
                builder: (context, entries, _) {
                  // Empty state hint — shows when no entries exist
                  // for the selected day. Today gets a more helpful
                  // message prompting the user to log, while past
                  // days just note that nothing was recorded.
                  if (entries.isEmpty && _selectedDay != null) {
                    final hint = _isSelectedDayToday
                        ? 'No symptoms logged today.\nTap + to log a new entry.'
                        : 'No symptoms logged for this day.';
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(spacingXl),
                        child: Text(
                          hint,
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return ListTile(
                        leading: Text(DateFormat.jm().format(entry.dateTime)),
                        title: Text(
                          '${entry.mood} - ${entry.symptoms.map((s) => s.name).join(', ')}',
                        ),
                        // Subtitle rebuilds independently when tag/note
                        // preview toggles change — avoids rebuilding the
                        // entire list for a preference change.
                        subtitle: _buildEntrySubtitle(entry),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  SymptomDetailScreen(entry: entry),
                            ),
                          );
                          if (result == true) {
                            notifyEntriesChanged();
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      // FAB to create a new entry — Android only (Material Design pattern).
      // iOS uses an AppBar button instead (see above).
      // Wrapped in Showcase for coach marks; shares _addEntryKey with the
      // iOS AppBar button since they are mutually exclusive.
      floatingActionButton: (Theme.of(context).platform != TargetPlatform.iOS &&
              _selectedDay != null &&
              !_selectedDay!.isAfter(DateTime.now()))
          ? Showcase(
              key: _addEntryKey,
              title: 'Add Entry',
              description:
                  'Tap to log symptoms, mood, and tags for the selected day.',
              tooltipBackgroundColor:
                  Theme.of(context).colorScheme.primaryContainer,
              textColor: Theme.of(context).colorScheme.onPrimaryContainer,
              child: FloatingActionButton(
                child: const Icon(Icons.add),
                onPressed: () => _navigateToNewEntry(),
              ),
            )
          : null,
    );
  }

  /// Max characters for note preview when tags are also shown.
  /// Keeps the subtitle compact when both previews are active.
  static const int _notePreviewMaxCharsWithTags = 30;

  /// Builds a reactive subtitle for a calendar entry list item.
  ///
  /// Wraps the subtitle in a [ListenableBuilder] scoped to the tag/note
  /// preview toggles, so toggling a preview only rebuilds each subtitle —
  /// not the entire entry list.
  ///
  /// Shows tag preview and/or note preview based on user preferences.
  /// Tag format: "After Meal +2" (first tag + count of remaining).
  /// Note format: truncated to one line with ellipsis.
  /// If both are shown, they're separated by " · ".
  Widget _buildEntrySubtitle(SymptomEntryModel entry) {
    // Return an empty SizedBox when there's nothing to preview,
    // rather than null, since this is always wrapped in ListenableBuilder.
    final hasTagData = entry.tags.isNotEmpty;
    final hasNoteData = entry.notes != null && entry.notes!.trim().isNotEmpty;

    // If the entry has no tags or notes at all, no subtitle is possible
    // regardless of toggle state — skip the builder entirely.
    if (!hasTagData && !hasNoteData) return const SizedBox.shrink();

    return ListenableBuilder(
      listenable: Listenable.merge([
        PreferencesService.showTagPreviewNotifier,
        PreferencesService.showNotePreviewNotifier,
      ]),
      builder: (context, _) {
        final showTags =
            PreferencesService.showTagPreviewNotifier.value && hasTagData;
        final showNotes =
            PreferencesService.showNotePreviewNotifier.value && hasNoteData;

        if (!showTags && !showNotes) return const SizedBox.shrink();

        final parts = <String>[];

        if (showTags) {
          final firstTag = entry.tags.first.name;
          if (entry.tags.length > 1) {
            parts.add('$firstTag +${entry.tags.length - 1}');
          } else {
            parts.add(firstTag);
          }
        }

        if (showNotes) {
          final noteText = entry.notes!.trim();
          if (showTags && noteText.length > _notePreviewMaxCharsWithTags) {
            parts
                .add('${noteText.substring(0, _notePreviewMaxCharsWithTags)}…');
          } else {
            parts.add(noteText);
          }
        }

        return Text(
          parts.join(' · '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall,
        );
      },
    );
  }

  /// Returns true if today's date is currently selected and the
  /// calendar is showing the current month.
  bool _isViewingToday() {
    final now = DateTime.now();
    final sameMonth =
        _focusedDay.year == now.year && _focusedDay.month == now.month;
    final sameDay = _selectedDay != null && isSameDay(_selectedDay, now);
    return sameMonth && sameDay;
  }

  /// Whether the currently selected day is today.
  /// Used by the empty state hint to show a different message
  /// for today vs past days.
  bool get _isSelectedDayToday {
    if (_selectedDay == null) return false;
    return isSameDay(_selectedDay, DateTime.now());
  }

  /// Navigates to the entry creation screen for the selected day.
  /// Shared by both the AppBar button (iOS) and FAB (Android).
  Future<void> _navigateToNewEntry() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SymptomEntryScreen(initialDate: _selectedDay),
      ),
    );
    if (result == true) {
      notifyEntriesChanged();
    }
  }

  // ---------------------------------------------------------------------------
  // Onboarding completion + coach marks trigger logic
  // ---------------------------------------------------------------------------

  /// Called when the user finishes the onboarding walkthrough.
  ///
  /// Shows the "What's New" dialog first (if there are entries for this
  /// version), then starts the coach marks tour after it's dismissed.
  void _onOnboardingCompleted() async {
    await _checkChangelog();
    _maybeStartCoachMarks();
  }

  /// Starts the interactive coach marks tour if the user has completed
  /// onboarding but hasn't seen the coach marks yet.
  ///
  /// Called from two paths:
  ///   1. Post-frame callback in [initState] — covers existing users who
  ///      update to a version with coach marks (onboarding already done).
  ///   2. [_onOnboardingCompleted] — covers new users who just finished
  ///      the onboarding walkthrough on this launch.
  ///
  /// A 500ms delay lets the onboarding overlay animate away and the calendar
  /// UI settle before the showcase overlay appears.
  void _maybeStartCoachMarks() {
    if (PreferencesService.hasSeenCoachMarksNotifier.value) return;
    if (!PreferencesService.hasSeenOnboardingNotifier.value) return;

    _coachMarksTimer?.cancel();
    _coachMarksTimer = Timer(const Duration(milliseconds: 500), () {
      final isTopRoute = ModalRoute.of(context)?.isCurrent ?? false;
      if (mounted && isTopRoute && !_showcaseView.isShowcaseRunning) {
        _showcaseView.startShowCase([
          _calendarKey,
          _addEntryKey,
          _summaryKey,
          _achievementsKey,
          _settingsKey,
        ]);
      }
    });
  }

  /// Persists that the user has completed (or dismissed) the coach marks,
  /// so they won't be shown again.
  void _onCoachMarksFinished() {
    PreferencesService.saveHasSeenCoachMarks(true);
  }

  /// Shows a toast if the encryption migration has failed, prompting the user
  /// to visit Settings to resolve the issue.
  void _checkEncryptionMigrationFlag() {
    if (!EncryptionRecoveryService.hasEncryptionIssue) return;
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(encryptionRecoveryToastMessage),
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: 'Settings',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ManageItemsScreen(),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Checks whether the changelog modal should be shown and displays it.
  ///
  /// Compares the current app version against the last-seen version stored in
  /// SharedPreferences. Shows the "What's New" dialog on first launch or after
  /// an update. Persists the current version after the user dismisses the dialog.
  Future<void> _checkChangelog() async {
    final info = await PackageInfo.fromPlatform();
    final currentVersion = info.version;

    // Don't show changelog during the onboarding walkthrough — the overlay
    // covers this screen. The check will re-run via _onOnboardingCompleted
    // once the user finishes onboarding.
    if (!PreferencesService.hasSeenOnboardingNotifier.value) return;

    final shouldShow =
        await ChangelogService.shouldShowChangelog(currentVersion);

    if (!shouldShow || !mounted) return;

    final entries = ChangelogService.getEntriesForVersion(currentVersion);

    if (entries.isNotEmpty && mounted) {
      await showChangelogDialog(
        context: context,
        version: currentVersion,
        entries: entries,
      );
    }

    // Persist regardless of whether entries were shown, so the check
    // doesn't run again for this version.
    await ChangelogService.saveLastSeenVersion(currentVersion);
  }
}
