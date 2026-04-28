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

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../app.dart';
import '../constants/encryption_recovery.dart';
import '../constants/layout.dart';
import '../services/encryption_recovery_service.dart';
import '../services/preferences_service.dart';
import '../models/symptom_models.dart';
import '../services/changelog_service.dart';
import '../services/database.dart';
import '../widgets/changelog_dialog.dart';
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

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
    // Listen for entry changes from any source (e.g., persistent notification).
    entriesChangedNotifier.addListener(_loadEvents);

    // Show the "What's New" or welcome dialog after the first frame renders,
    // and check for encryption migration issues.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkEncryptionMigrationFlag();
      _checkChangelog();
    });
  }

  @override
  void dispose() {
    entriesChangedNotifier.removeListener(_loadEvents);
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
          IconButton(
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
          // Add entry button in AppBar — iOS only (iOS doesn't use FABs).
          // Android uses a FloatingActionButton instead (see below).
          if (Theme.of(context).platform == TargetPlatform.iOS &&
              _selectedDay != null &&
              !_selectedDay!.isAfter(DateTime.now()))
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _navigateToNewEntry(),
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
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManageItemsScreen(),
                ),
              );
              // Reload events and update widgets in case entries were modified
              // (e.g., Clear All Data).
              notifyEntriesChanged();
            },
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Calendar widget — rebuilds when the start day preference or
            // system start day changes. Uses Listenable.merge to listen to
            // both notifiers in a single builder instead of nesting.
            ListenableBuilder(
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
      floatingActionButton: (Theme.of(context).platform != TargetPlatform.iOS &&
              _selectedDay != null &&
              !_selectedDay!.isAfter(DateTime.now()))
          ? FloatingActionButton(
              child: const Icon(Icons.add),
              onPressed: () => _navigateToNewEntry(),
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
    // covers this screen. Persist the current version so the changelog
    // doesn't show on the next launch either.
    if (!PreferencesService.hasSeenOnboardingNotifier.value) {
      await ChangelogService.saveLastSeenVersion(currentVersion);
      return;
    }

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
