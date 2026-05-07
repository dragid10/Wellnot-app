// manage_list_screen.dart: Sub-page for managing custom symptoms or tags.
//
// Navigated to from the main settings screen via "Manage Symptoms" or
// "Manage Tags" links. Displays a text field to add new items, a list of
// user-created custom items (deletable), and a read-only section showing
// default items.
//
// Cross-ref:
//   - Parent screen: screens/manage_items_screen.dart (settings)
//   - Default lists: constants/defaults.dart (defaultSymptoms/defaultTags)
//   - DB helpers: services/database.dart (addSymptom, addTag, deleteSymptom,
//     deleteTag, getCustomSymptoms, getCustomTags)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app.dart';
import '../constants/defaults.dart';
import '../constants/layout.dart';
import '../services/achievement_service.dart';
import '../services/item_preferences_service.dart';
import '../services/preferences_service.dart';
import '../widgets/info_tooltip.dart';
import '../services/database.dart';

/// A reusable screen for managing either symptoms or tags.
///
/// [title] is displayed in the app bar (e.g., "Manage Symptoms").
/// [itemType] is either 'symptom' or 'tag' — drives which DB methods to call.
/// Maximum width for a chip in the manage list to prevent overflow
/// from very long symptom/tag names.
const double _chipMaxWidth = 200.0;

/// Maximum character length for symptom and tag names.
const int _itemNameMaxLength = 120;

class ManageListScreen extends StatefulWidget {
  final String title;
  final String itemType;

  const ManageListScreen({
    super.key,
    required this.title,
    required this.itemType,
  });

  @override
  State<ManageListScreen> createState() => _ManageListScreenState();
}

class _ManageListScreenState extends State<ManageListScreen> {
  final _controller = TextEditingController();

  /// User-created items stored as (id, name) records for type-safe access.
  /// Populated from either getCustomSymptoms() or getCustomTags().
  List<({int id, String name})> _customItems = [];

  /// The name of the item that was flagged as a duplicate (for highlight).
  /// Auto-clears after 2 seconds.
  String? _duplicateName;

  late AppDatabase _database;
  bool _initialized = false;

  /// Whether this screen is managing symptoms (true) or tags (false).
  bool get _isSymptom => widget.itemType == 'symptom';

  /// Names of hidden default items — shown greyed out with a tap to toggle.
  List<String> _hiddenItems = [];

  /// Names of pinned items — shown with a pin icon.
  List<String> _pinnedItems = [];

  /// The sorted list of default (built-in) item names for display.
  List<String> get _defaults {
    if (_isSymptom) {
      return List<String>.from(defaultSymptoms)..sort();
    }
    return List<String>.from(defaultTags)..sort();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _database = context.read<AppDatabase>();
      _initialized = true;
      _loadItems();
      _loadHiddenItems();
      _loadPinnedItems();
    }
  }

  /// Loads custom (non-default) items from the database and sorts
  /// alphabetically for display.
  void _loadItems() async {
    try {
      final List<({int id, String name})> items;
      if (_isSymptom) {
        final symptoms = await _database.getCustomSymptoms();
        items = symptoms.map((s) => (id: s.id, name: s.name)).toList();
      } else {
        final tags = await _database.getCustomTags();
        items = tags.map((t) => (id: t.id, name: t.name)).toList();
      }
      items
          .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      if (mounted) {
        setState(() {
          _customItems = items;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load items: $e')),
        );
      }
    }
  }

  /// Loads the list of hidden default items from SharedPreferences.
  Future<void> _loadHiddenItems() async {
    final hidden = _isSymptom
        ? await ItemPreferencesService.loadHiddenSymptoms()
        : await ItemPreferencesService.loadHiddenTags();
    if (mounted) {
      setState(() {
        _hiddenItems = hidden;
      });
    }
  }

  /// Toggles the hidden state of a default item.
  Future<void> _toggleHideItem(String name) async {
    final wasHidden = _hiddenItems.contains(name);
    final updated = _isSymptom
        ? await ItemPreferencesService.toggleHideSymptom(name)
        : await ItemPreferencesService.toggleHideTag(name);
    if (mounted) {
      setState(() {
        _hiddenItems = updated;
      });
      if (!wasHidden) {
        _checkHideAchievement();
      }
    }
  }

  /// Loads the list of pinned items from SharedPreferences.
  Future<void> _loadPinnedItems() async {
    final pinned = _isSymptom
        ? await ItemPreferencesService.loadPinnedSymptoms()
        : await ItemPreferencesService.loadPinnedTags();
    if (mounted) {
      setState(() {
        _pinnedItems = pinned;
      });
    }
  }

  /// Toggles the pinned state of an item.
  Future<void> _togglePinItem(String name) async {
    final wasPinned = _pinnedItems.contains(name);
    final updated = _isSymptom
        ? await ItemPreferencesService.togglePinSymptom(name)
        : await ItemPreferencesService.togglePinTag(name);
    if (mounted) {
      setState(() {
        _pinnedItems = updated;
      });
      if (!wasPinned) {
        _checkPinAchievement();
      }
    }
  }

  Future<void> _checkHideAchievement() async {
    if (!PreferencesService.achievementsEnabledNotifier.value) return;
    final database = context.read<AppDatabase>();
    final unlocked = await AchievementService.checkAfterHide(database);
    if (unlocked.isNotEmpty) {
      notifyAchievementsUnlocked(unlocked);
    }
  }

  Future<void> _checkPinAchievement() async {
    if (!PreferencesService.achievementsEnabledNotifier.value) return;
    final database = context.read<AppDatabase>();
    final unlocked = await AchievementService.checkAfterPin(database);
    if (unlocked.isNotEmpty) {
      notifyAchievementsUnlocked(unlocked);
    }
  }

  /// Adds a new custom item to the database.
  ///
  /// Checks both the default list and user list for duplicates
  /// (case-insensitive). If a duplicate is found, the existing chip is
  /// briefly highlighted in red via [_duplicateName].
  void _addItem(String name) async {
    if (name.trim().isEmpty) return;
    final lowerName = name.trim().toLowerCase();
    final typeLabel = _isSymptom ? 'Symptom' : 'Tag';

    // Check both defaults and custom items for duplicates.
    final existsInDefaults = _defaults.any((d) => d.toLowerCase() == lowerName);
    final existsInCustom =
        _customItems.any((item) => item.name.toLowerCase() == lowerName);

    if (existsInDefaults || existsInCustom) {
      setState(() {
        _duplicateName = name.trim();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$typeLabel "$name" already exists!')),
      );
      // Clear the highlight after 2 seconds.
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _duplicateName = null;
          });
        }
      });
      return;
    }

    try {
      final result = _isSymptom
          ? await _database.addSymptom(name.trim())
          : await _database.addTag(name.trim());
      if (result == -1 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$typeLabel "$name" already exists!')),
        );
      }
      _controller.clear();
      _loadItems();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add $typeLabel: $e')),
        );
      }
    }
  }

  /// Deletes a custom item by [id] and its join-table links.
  void _deleteItem(int id) async {
    try {
      if (_isSymptom) {
        await _database.deleteSymptom(id);
      } else {
        await _database.deleteTag(id);
      }
      _loadItems();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete item: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (!_isSymptom) InfoTooltip(message: tagTooltipText),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(spacingLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section header: "My Symptoms" or "My Tags"
                Text(
                  _isSymptom ? 'My Symptoms' : 'My Tags',
                  style: Theme.of(context).textTheme.titleMedium,
                ),

                // Text field + add button for creating new custom items.
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        maxLength: _itemNameMaxLength,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: _isSymptom
                              ? 'Enter symptom name'
                              : 'Enter tag name',
                        ),
                        onSubmitted: _addItem,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => _addItem(_controller.text),
                    ),
                  ],
                ),

                // User-created custom items — deletable chips.
                // Long-press to pin/unpin. Tap the eye to hide/unhide.
                // Chips turn red briefly when a duplicate is detected.
                Wrap(
                  spacing: chipSpacing,
                  runSpacing: chipRunSpacing,
                  children: _customItems.map((item) {
                    final isHidden = _hiddenItems.contains(item.name);
                    final isPinned = _pinnedItems.contains(item.name);
                    // Determine avatar icon: pinned > hidden > none.
                    Widget? avatar;
                    if (isPinned) {
                      avatar = Icon(Icons.push_pin,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary);
                    } else if (isHidden) {
                      avatar = Icon(Icons.visibility_off,
                          size: 16,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.38));
                    }
                    return ConstrainedBox(
                      constraints:
                          const BoxConstraints(maxWidth: _chipMaxWidth),
                      child: GestureDetector(
                        // Long-press to toggle pin state.
                        // No Tooltip wrapper here — it would intercept the
                        // long-press gesture and show a text preview instead.
                        onLongPress: () => _togglePinItem(item.name),
                        child: Chip(
                          avatar: avatar,
                          label: Text(
                            item.name,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isHidden
                                  ? Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.38)
                                  : null,
                              decoration:
                                  isHidden ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          // Delete button removes the item from the DB.
                          onDeleted: () => _deleteItem(item.id),
                          backgroundColor: (_duplicateName == item.name)
                              ? Colors.red.shade100
                              : isHidden
                                  ? Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest
                                      .withValues(alpha: 0.5)
                                  : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: spacingLg),

                // Section header: "Default Symptoms" or "Default Tags"
                Text(
                  _isSymptom ? 'Default Symptoms' : 'Default Tags',
                  style: Theme.of(context).textTheme.titleMedium,
                ),

                // Built-in default items — tap to toggle visibility,
                // long-press to toggle pin state.
                // Pinned items show a pin icon. Hidden items appear
                // greyed out with strikethrough text.
                Wrap(
                  spacing: chipSpacing,
                  runSpacing: chipRunSpacing,
                  children: _defaults.map((name) {
                    final isHidden = _hiddenItems.contains(name);
                    final isPinned = _pinnedItems.contains(name);
                    // Icon priority: pinned > hidden > visible.
                    IconData avatarIcon;
                    if (isPinned) {
                      avatarIcon = Icons.push_pin;
                    } else if (isHidden) {
                      avatarIcon = Icons.visibility_off;
                    } else {
                      avatarIcon = Icons.visibility;
                    }
                    return GestureDetector(
                      // Tap to toggle the hidden state.
                      onTap: () => _toggleHideItem(name),
                      // Long-press to toggle the pin state.
                      onLongPress: () => _togglePinItem(name),
                      child: Chip(
                        label: Text(
                          name,
                          style: TextStyle(
                            // Greyed out text for hidden items.
                            color: isHidden
                                ? Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.38)
                                : null,
                            // Strikethrough for hidden items.
                            decoration:
                                isHidden ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        // Hidden items have a more transparent background.
                        backgroundColor: isHidden
                            ? Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.5)
                            : Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                        avatar: Icon(
                          avatarIcon,
                          size: 16,
                          color: isPinned
                              ? Theme.of(context).colorScheme.primary
                              : isHidden
                                  ? Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.38)
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
