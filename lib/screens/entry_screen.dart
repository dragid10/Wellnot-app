// entry_screen.dart: Create or edit a symptom entry
//
// This screen provides a form for users to log symptoms (with severity),
// mood, tags, notes, and date/time. It validates required fields and prevents
// future dates.
//
// Cross-ref:
//   - Default symptoms/tags/moods: constants/defaults.dart
//   - Severity editing: widgets/symptom_entry_widget.dart → widgets/severity_selector.dart
//   - Saving: services/database.dart AppDatabase.saveEntry()
//     — **this fixes the severity data-loss bug** by passing severity to saveEntry()
//   - Layout constants: constants/layout.dart
//   - Database obtained via Provider (see main.dart)

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../constants/defaults.dart';
import '../constants/layout.dart';
import '../models/symptom_models.dart';
import '../services/database.dart';
import '../services/item_preferences_service.dart';
import '../widgets/adaptive_pickers.dart';
import '../widgets/info_tooltip.dart';
import '../widgets/symptom_entry_widget.dart';

/// Quick-pick time-of-day options for the entry form.
/// Each option maps to a default hour so users don't need the
/// full time picker for approximate logging.
enum TimeOfDayPick {
  /// 8:00 AM — early part of the day.
  morning('Morning', 8),

  /// 12:00 PM — midday.
  afternoon('Afternoon', 12),

  /// 6:00 PM — end of the day.
  evening('Evening', 18),

  /// 10:00 PM — late night.
  night('Night', 22),

  /// User picks a specific time via the time picker dialog.
  specific('Specific', -1);

  /// Display label shown on the chip.
  final String label;

  /// The hour (0–23) this pick maps to. -1 for 'specific' (uses picker).
  final int hour;
  const TimeOfDayPick(this.label, this.hour);

  /// Returns the [TimeOfDayPick] whose hour range contains [h],
  /// or [specific] if the hour doesn't match a quick pick exactly.
  static TimeOfDayPick fromHour(int h) {
    for (final pick in TimeOfDayPick.values) {
      if (pick.hour == h) return pick;
    }
    return TimeOfDayPick.specific;
  }
}

/// Form screen for creating a new symptom entry or editing an existing one.
///
/// Pass [entry] to pre-fill the form for editing; omit it for a new entry.
/// Pass [initialDate] to set the date for a new entry (e.g., from the
/// calendar's selected day). Defaults to [DateTime.now] if omitted.
/// Returns `true` via `Navigator.pop` when a save succeeds, so the calling
/// screen knows to reload.
class SymptomEntryScreen extends StatefulWidget {
  /// If non-null, the form is in "edit" mode with fields pre-filled.
  final SymptomEntryModel? entry;

  /// The initial date for a new entry. Ignored when [entry] is provided
  /// (edit mode uses the entry's existing dateTime instead).
  final DateTime? initialDate;

  /// When true, the form is pre-filled from [entry] but saves as a NEW
  /// entry (ignores the original entry's ID). Used by the "Log Similar"
  /// feature on the detail screen. Date/time defaults to now.
  final bool duplicate;

  const SymptomEntryScreen({
    super.key,
    this.entry,
    this.initialDate,
    this.duplicate = false,
  });

  @override
  State<SymptomEntryScreen> createState() => _SymptomEntryScreenState();
}

class _SymptomEntryScreenState extends State<SymptomEntryScreen> {
  late DateTime _selectedDateTime;
  final List<UserSymptomModel> _selectedSymptoms = [];
  String? _selectedMood;
  final List<UserTagModel> _selectedTags = [];
  final TextEditingController _notesController = TextEditingController();

  /// User-defined symptoms loaded from the database (not defaults).
  List<UserSymptomModel> _userSymptoms = [];

  /// User-defined tags loaded from the database (not defaults).
  List<UserTagModel> _userTags = [];

  /// Merged + deduplicated symptom list, recomputed only when _userSymptoms
  /// changes (not on every build).
  List<UserSymptomModel> _allSymptoms = [];

  /// Merged + deduplicated tag list, recomputed only when _userTags changes.
  List<UserTagModel> _allTags = [];

  /// Tracks which symptom's severity bar is currently expanded in the UI.
  String? _expandedSymptomName;

  /// The currently selected time-of-day quick pick. Determines which
  /// chip is highlighted and whether the time picker is shown.
  TimeOfDayPick _selectedTimePick = TimeOfDayPick.specific;

  /// Pinned symptom/tag names — appear at the top of their chip lists.
  List<String> _pinnedSymptoms = [];
  List<String> _pinnedTags = [];

  /// Hidden symptom/tag/mood names — filtered out of the chip lists.
  List<String> _hiddenSymptoms = [];
  List<String> _hiddenTags = [];

  /// Map of symptom name → most recent severity from previous entries.
  /// Loaded separately from main items (non-critical hint data).
  Map<String, int> _lastSeverities = {};

  late AppDatabase _database;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.entry != null && widget.duplicate) {
      // Duplicate mode — pre-fill symptoms, mood, and tags from the
      // existing entry but use current date/time and clear notes.
      // The entry will be saved as NEW (not updating the original).
      _selectedDateTime = DateTime.now();
      _selectedSymptoms.addAll(widget.entry!.symptoms);
      _selectedMood = widget.entry!.mood;
      _selectedTags.addAll(widget.entry!.tags);
    } else if (widget.entry != null) {
      // Edit mode — pre-fill form fields from the existing entry.
      _selectedDateTime = widget.entry!.dateTime;
      _selectedSymptoms.addAll(widget.entry!.symptoms);
      _selectedMood = widget.entry!.mood;
      _selectedTags.addAll(widget.entry!.tags);
      _notesController.text = widget.entry!.notes ?? '';
    } else {
      // New entry — use the calendar's selected day, or today as fallback.
      // table_calendar passes dates as UTC midnight, so we extract just the
      // date components. For today, use the current time; for past days,
      // default to noon as a neutral starting point. The user can change
      // the time via the Date & Time picker.
      final date = widget.initialDate;
      if (date != null) {
        final now = DateTime.now();
        final isToday = date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;
        _selectedDateTime = isToday
            ? DateTime(date.year, date.month, date.day, now.hour, now.minute)
            : DateTime(date.year, date.month, date.day, 12, 0);
      } else {
        _selectedDateTime = DateTime.now();
      }
    }

    // Set the initial time quick pick based on the selected hour.
    // If the hour matches a quick pick exactly, select it; otherwise
    // default to "Specific".
    _selectedTimePick = TimeOfDayPick.fromHour(_selectedDateTime.hour);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _database = context.read<AppDatabase>();
      _initialized = true;
      _loadUserItems();
    }
  }

  /// Loads user-defined (custom) symptoms and tags from the database, then
  /// rebuilds the merged lists used by the chip selectors.
  Future<void> _loadUserItems() async {
    try {
      final symptoms = await _database.getAllSymptoms();
      final tags = await _database.getAllTags();
      // Load pin/hide preferences from SharedPreferences.
      final pinnedSymptoms = await ItemPreferencesService.loadPinnedSymptoms();
      final pinnedTags = await ItemPreferencesService.loadPinnedTags();
      final hiddenSymptoms = await ItemPreferencesService.loadHiddenSymptoms();
      final hiddenTags = await ItemPreferencesService.loadHiddenTags();
      if (mounted) {
        setState(() {
          _userSymptoms = symptoms;
          _userTags = tags;
          _pinnedSymptoms = pinnedSymptoms;
          _pinnedTags = pinnedTags;
          _hiddenSymptoms = hiddenSymptoms;
          _hiddenTags = hiddenTags;
          _rebuildMergedLists();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load items: $e')),
        );
      }
    }

    // Load severity context separately — non-critical hint data.
    // If this fails, the entry form still works normally.
    try {
      final severities = await _database.getLastSeverities();
      if (mounted) {
        setState(() {
          _lastSeverities = severities;
        });
      }
    } catch (_) {
      // Silently ignore — severity hints are a nice-to-have.
    }
  }

  /// Merges user-defined items with defaults, deduplicates by lowercase
  /// name, filters out hidden items, and sorts with pinned items first.
  void _rebuildMergedLists() {
    // Symptoms: user-defined first so they take priority in the map.
    final defaultSymptomModels = defaultSymptoms
        .map((name) => UserSymptomModel(id: -1, name: name))
        .toList();
    final Map<String, UserSymptomModel> symptomMap = {};
    for (var s in [..._userSymptoms, ...defaultSymptomModels]) {
      symptomMap[s.name.toLowerCase()] = s;
    }
    // Filter out hidden symptoms, then sort with pinned first.
    final visibleSymptoms = symptomMap.values
        .where((s) => !_hiddenSymptoms.contains(s.name))
        .toList();
    _allSymptoms = ItemPreferencesService.sortWithPinnedFirst(
      visibleSymptoms,
      _pinnedSymptoms,
      (s) => s.name,
    );

    // Tags: same deduplication, filter, and sort.
    final defaultTagModels =
        defaultTags.map((name) => UserTagModel(id: -1, name: name)).toList();
    final Map<String, UserTagModel> tagMap = {};
    for (var t in [..._userTags, ...defaultTagModels]) {
      tagMap[t.name.toLowerCase()] = t;
    }
    // Filter out hidden tags, then sort with pinned first.
    final visibleTags =
        tagMap.values.where((t) => !_hiddenTags.contains(t.name)).toList();
    _allTags = ItemPreferencesService.sortWithPinnedFirst(
      visibleTags,
      _pinnedTags,
      (t) => t.name,
    );
  }

  /// Returns true if the given [pick] would result in a future time
  /// on the currently selected date. Always returns false for past dates.
  bool _isPickInFuture(TimeOfDayPick pick) {
    if (pick == TimeOfDayPick.specific) return false;
    final candidate = DateTime(
      _selectedDateTime.year,
      _selectedDateTime.month,
      _selectedDateTime.day,
      pick.hour,
      0,
    );
    return candidate.isAfter(DateTime.now());
  }

  /// Applies a time-of-day quick pick by setting the hour to the
  /// pick's mapped value and the minute to 0.
  void _applyTimePick(TimeOfDayPick pick) {
    setState(() {
      _selectedDateTime = DateTime(
        _selectedDateTime.year,
        _selectedDateTime.month,
        _selectedDateTime.day,
        pick.hour,
        0,
      );
      _selectedTimePick = pick;
    });
  }

  /// Opens the platform-adaptive time picker dialog for exact
  /// time selection. Updates [_selectedTimePick] to [specific].
  Future<void> _showTimePicker() async {
    final messenger = ScaffoldMessenger.of(context);
    final picked = await showAdaptiveTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );
    if (picked != null) {
      final candidate = DateTime(
        _selectedDateTime.year,
        _selectedDateTime.month,
        _selectedDateTime.day,
        picked.hour,
        picked.minute,
      );
      // Reject future times on today's date.
      if (candidate.isAfter(DateTime.now())) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Cannot select a future time.')),
        );
        return;
      }
      setState(() {
        _selectedDateTime = candidate;
        _selectedTimePick = TimeOfDayPick.specific;
      });
    }
  }

  /// Validates the form and saves (or updates) the entry via [AppDatabase.saveEntry].
  ///
  /// Requires at least one symptom and a mood. On success, pops the screen
  /// and returns `true` to the caller.
  void _onSave() async {
    if (_selectedSymptoms.isEmpty || _selectedMood == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one symptom and a mood.'),
        ),
      );
      return;
    }

    try {
      await _database.saveEntry(
        // In duplicate mode, don't pass the original entry's ID so a
        // new entry is created instead of updating the original.
        existingId: widget.duplicate ? null : widget.entry?.id,
        dateTime: _selectedDateTime,
        mood: _selectedMood!,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        symptoms: _selectedSymptoms,
        tags: _selectedTags,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save entry: $e')),
        );
      }
    }
  }

  /// Shows a dialog for adding a new custom symptom or tag.
  ///
  /// [type] should be `'Symptom'` or `'Tag'`. On success, the new item is
  /// persisted to the database and the chip list is refreshed. Returns -1
  /// from the DB helper if the name already exists (unique constraint).
  Future<void> _showAddItemDialog(String type) async {
    final controller = TextEditingController();
    final itemName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        title: Text('Add New $type'),
        content: Material(
          color: Colors.transparent,
          child: TextField(
            controller: controller,
            autofocus: true,
            maxLength: maxItemNameLength,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(hintText: 'Enter $type name'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                Navigator.of(context).pop(controller.text);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (!mounted || itemName == null) return;

    // Check if the name matches a default symptom/tag (case-insensitive).
    final lowerName = itemName.trim().toLowerCase();
    final existsInDefaults = type == 'Symptom'
        ? defaultSymptoms.any((s) => s.toLowerCase() == lowerName)
        : defaultTags.any((t) => t.toLowerCase() == lowerName);

    if (existsInDefaults && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$type "$itemName" already exists!')),
      );
      return;
    }

    try {
      final result = type == 'Symptom'
          ? await _database.addSymptom(itemName)
          : await _database.addTag(itemName);

      if (result == -1 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$type "$itemName" already exists!')),
        );
      }
      _loadUserItems();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add $type: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Show different titles for new, edit, and duplicate modes.
        title: Text(widget.duplicate
            ? 'Log Similar Entry'
            : (widget.entry == null ? 'New Symptom Entry' : 'Edit Entry')),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(spacingLg),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date picker — opens a date-only dialog.
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Date'),
                  trailing: Text(
                    DateFormat.yMMMd().format(_selectedDateTime),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  onTap: () async {
                    final picked = await showAdaptiveDatePicker(
                      context: context,
                      initialDate: _selectedDateTime,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        // Preserve the existing time when changing the date.
                        _selectedDateTime = DateTime(
                          picked.year,
                          picked.month,
                          picked.day,
                          _selectedDateTime.hour,
                          _selectedDateTime.minute,
                        );
                      });
                    }
                  },
                ),
                // Time-of-day quick picks — lets the user select a rough
                // time period instead of using the full time picker.
                // "Specific" opens the time picker for exact selection.
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: spacingSm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Row with clock icon, "Time" label, and current time.
                      // Tappable to open the time picker directly.
                      GestureDetector(
                        onTap: _showTimePicker,
                        child: Row(
                          children: [
                            const Icon(Icons.access_time),
                            const SizedBox(width: spacingLg),
                            Text('Time',
                                style: Theme.of(context).textTheme.bodyLarge),
                            const Spacer(),
                            // Show the currently selected time regardless of
                            // which quick pick is active.
                            Text(
                              DateFormat.jm().format(_selectedDateTime),
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: spacingSm),
                      // Quick pick chips — one for each time period plus
                      // "Specific" which opens the full time picker.
                      // Future time picks are disabled (greyed out) for today.
                      Wrap(
                        spacing: chipSpacing,
                        children: TimeOfDayPick.values.map((pick) {
                          final isSelected = _selectedTimePick == pick;
                          // Disable quick picks that would be in the future
                          // on today's date. Past dates allow all picks.
                          // "Specific" is always enabled (the picker itself
                          // handles future time validation).
                          final isEnabled = pick == TimeOfDayPick.specific ||
                              !_isPickInFuture(pick);
                          return ChoiceChip(
                            label: Text(pick.label),
                            selected: isSelected,
                            onSelected: isEnabled
                                ? (selected) {
                                    if (pick == TimeOfDayPick.specific) {
                                      // Always open the time picker, even if
                                      // already selected (user wants to change
                                      // the specific time).
                                      _showTimePicker();
                                    } else {
                                      if (!selected) return;
                                      // Apply the quick pick's mapped hour.
                                      _applyTimePick(pick);
                                    }
                                  }
                                : null,
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                // Symptoms section — chip selection + severity sliders for each.
                _buildSectionHeader('Symptoms',
                    onAdd: () => _showAddItemDialog('Symptom')),
                _buildMultiSelectChipGroup<UserSymptomModel>(
                  _allSymptoms,
                  _selectedSymptoms,
                  (item) => item.name,
                  pinnedNames: _pinnedSymptoms,
                  onChipTap: (item) {
                    setState(() {
                      _expandedSymptomName = item.name;
                    });
                  },
                  // Long-press to pin/unpin a symptom.
                  onLongPress: (item) async {
                    final updated =
                        await ItemPreferencesService.togglePinSymptom(
                            item.name);
                    setState(() {
                      _pinnedSymptoms = updated;
                      _rebuildMergedLists();
                    });
                  },
                ),
                // Render a SymptomEntryWidget (with severity slider) for each
                // selected symptom.
                ..._selectedSymptoms.map((symptom) => SymptomEntryWidget(
                      key: ValueKey(symptom.name),
                      symptom: symptom,
                      onSymptomUpdated: (updated) {
                        setState(() {
                          final idx = _selectedSymptoms.indexOf(symptom);
                          if (idx != -1) _selectedSymptoms[idx] = updated;
                        });
                      },
                      onRemove: () {
                        setState(() {
                          _selectedSymptoms.remove(symptom);
                          if (_expandedSymptomName == symptom.name) {
                            _expandedSymptomName = null;
                          }
                        });
                      },
                      showRemoveButton: true,
                      showSeveritySelector: true,
                      lastSeverity: _lastSeverities[symptom.name],
                    )),
                const Divider(),
                // Mood section — single-select emoji grid.
                _buildSectionHeader('Mood'),
                _buildMoodSelector(),
                const Divider(),
                // Tags section — multi-select chip group.
                _buildSectionHeader('Tags',
                    onAdd: () => _showAddItemDialog('Tag'),
                    tooltip: tagTooltipText),
                _buildMultiSelectChipGroup(
                  _allTags,
                  _selectedTags,
                  (item) => (item).name,
                  pinnedNames: _pinnedTags,
                  // Long-press to pin/unpin a tag.
                  onLongPress: (item) async {
                    final updated =
                        await ItemPreferencesService.togglePinTag(item.name);
                    setState(() {
                      _pinnedTags = updated;
                      _rebuildMergedLists();
                    });
                  },
                ),
                const Divider(),
                // Notes section — free-text input.
                _buildSectionHeader('Notes'),
                TextField(
                  controller: _notesController,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Any extra details...',
                  ),
                ),
                const SizedBox(height: spacingXl),
                // Save button — disabled when the selected date is in the future.
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isFutureDate ? null : _onSave,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: spacingLg),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                    child: Text(
                      _isFutureDate
                          ? 'Cannot save future entry'
                          : (widget.entry == null
                              ? 'Add Entry'
                              : 'Save Changes'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a section header row with a title, an optional info [tooltip],
  /// and an optional "+" button.
  Widget _buildSectionHeader(String title,
      {VoidCallback? onAdd, String? tooltip}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: spacingSm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              if (tooltip != null) InfoTooltip(message: tooltip),
            ],
          ),
          if (onAdd != null)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: onAdd,
            ),
        ],
      ),
    );
  }

  /// Builds a horizontal wrap of FilterChips for multi-selection.
  ///
  /// Selection state is determined by case-insensitive name matching so that
  /// "headache" and "Headache" are treated as the same item.
  Widget _buildMultiSelectChipGroup<T>(
    List<T> items,
    List<T> selectedItems,
    String Function(T) getName, {
    void Function(T)? onChipTap,
    // List of pinned names — if provided, pinned items show a pin icon.
    List<String>? pinnedNames,
    // Called when user long-presses a chip to toggle its pin state.
    void Function(T)? onLongPress,
  }) {
    return Wrap(
      spacing: chipSpacing,
      children: items.map((item) {
        final name = getName(item);
        // Case-insensitive match to handle user vs default name casing.
        bool isSelected = selectedItems.any(
          (s) => getName(s).toLowerCase() == name.toLowerCase(),
        );
        // Check if this item is pinned (for visual indicator).
        final isPinned = pinnedNames?.contains(name) ?? false;
        return GestureDetector(
          // Long-press to toggle pin state.
          onLongPress: onLongPress != null ? () => onLongPress(item) : null,
          child: FilterChip(
            // Show a small pin icon on pinned items.
            avatar: isPinned
                ? Icon(Icons.push_pin,
                    size: 16, color: Theme.of(context).colorScheme.primary)
                : null,
            label: Text(name),
            selected: isSelected,
            showCheckmark: false,
            onSelected: (selected) {
              setState(() {
                if (selected) {
                  if (!isSelected) selectedItems.add(item);
                } else {
                  selectedItems.removeWhere(
                    (s) => getName(s).toLowerCase() == name.toLowerCase(),
                  );
                }
                if (onChipTap != null) onChipTap(item);
              });
            },
          ),
        );
      }).toList(),
    );
  }

  /// Builds the mood selector — a centered wrap of emoji InkWells.
  ///
  /// Only one mood can be selected at a time (single-select).
  /// Emoji size scales with the default text size via [emojiScaleLarge].
  Widget _buildMoodSelector() {
    final defaultFontSize =
        Theme.of(context).textTheme.bodyLarge?.fontSize ?? 16;
    return Wrap(
      spacing: spacingMd,
      alignment: WrapAlignment.center,
      children: defaultMoods.map((mood) {
        final isSelected = _selectedMood == mood;
        return InkWell(
          onTap: () => setState(() => _selectedMood = mood),
          customBorder: const CircleBorder(),
          child: Container(
            padding: const EdgeInsets.all(spacingSm),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Colors.transparent,
            ),
            child: Text(mood,
                style: TextStyle(fontSize: defaultFontSize * emojiScaleLarge)),
          ),
        );
      }).toList(),
    );
  }

  /// Whether the currently selected date/time is in the future.
  bool get _isFutureDate => _selectedDateTime.isAfter(DateTime.now());
}
