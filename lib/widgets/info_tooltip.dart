// info_tooltip.dart: A tappable info icon that shows a tooltip.
//
// Uses GlobalKey<TooltipState> to programmatically trigger the tooltip,
// which works reliably on both Android and iOS — including when nested
// inside other tappable widgets like ListTile.
//
// Cross-ref:
//   - Used by: screens/entry_screen.dart, screens/manage_items_screen.dart,
//     screens/manage_list_screen.dart

import 'package:flutter/material.dart';

/// A small info icon that shows a [Tooltip] when tapped.
///
/// Unlike using `Tooltip(triggerMode: TooltipTriggerMode.tap)` directly,
/// this widget programmatically triggers the tooltip via an [IconButton],
/// ensuring it works inside gesture-absorbing parents (e.g., [ListTile]).
class InfoTooltip extends StatelessWidget {
  final String message;
  final double iconSize;

  /// Key used to programmatically show the tooltip overlay.
  final GlobalKey<TooltipState> _tooltipKey = GlobalKey<TooltipState>();

  InfoTooltip({
    super.key,
    required this.message,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      key: _tooltipKey,
      message: message,
      showDuration: const Duration(seconds: 5),
      child: IconButton(
        icon: Icon(
          Icons.info_outline,
          size: iconSize,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        constraints: BoxConstraints(
          minWidth: iconSize + 16,
          minHeight: iconSize + 16,
        ),
        padding: EdgeInsets.zero,
        onPressed: () => _tooltipKey.currentState?.ensureTooltipVisible(),
      ),
    );
  }
}
