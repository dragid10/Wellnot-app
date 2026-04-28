// adaptive_segmented_control.dart: Platform-adaptive segmented control.
//
// On iOS, uses CupertinoSlidingSegmentedControl for native appearance.
// On Android, uses Material SegmentedButton.
//
// Cross-ref:
//   - Used by screens/manage_items_screen.dart (theme mode selector)
//   - Used by screens/feedback_screen.dart (feedback category selector)

import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// A platform-adaptive segmented control.
///
/// Shows [CupertinoSlidingSegmentedControl] on iOS and [SegmentedButton]
/// on Android. Each segment has a [value], [label], and optional [icon].
class AdaptiveSegmentedControl<T extends Object> extends StatelessWidget {
  final Map<T, String> segments;
  final Map<T, IconData>? icons;
  final T selected;
  final ValueChanged<T> onChanged;

  const AdaptiveSegmentedControl({
    super.key,
    required this.segments,
    this.icons,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return SizedBox(
        width: double.infinity,
        child: CupertinoSlidingSegmentedControl<T>(
          groupValue: selected,
          children: segments.map((key, label) {
            return MapEntry(
              key,
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(label),
                ),
              ),
            );
          }),
          onValueChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      );
    }

    return SegmentedButton<T>(
      showSelectedIcon: false,
      segments: segments.entries.map((entry) {
        final icon = icons?[entry.key];
        return ButtonSegment(
          value: entry.key,
          label: Text(entry.value),
          icon: icon != null ? Icon(icon) : null,
        );
      }).toList(),
      selected: {selected},
      onSelectionChanged: (newSelection) {
        onChanged(newSelection.first);
      },
    );
  }
}
