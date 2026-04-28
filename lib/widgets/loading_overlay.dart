// loading_overlay.dart: Full-screen loading overlay with modal barrier.
//
// Blocks all user interaction while a long-running operation is in progress
// and shows a centered spinner with an optional message. Used by the import
// screen and encryption recovery screen.
//
// Cross-ref:
//   - Import screen: screens/settings/import_data_screen.dart
//   - Recovery screen: screens/settings/encryption_issue_screen.dart

import 'package:flutter/material.dart';
import '../constants/layout.dart';

/// Full-screen loading overlay that blocks interaction and shows a spinner.
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  final bool isLoading;
  final Widget child;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading) ...[
          ModalBarrier(
            dismissible: false,
            color: Theme.of(context).colorScheme.scrim.withAlpha(82),
          ),
          Center(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(spacingXl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator.adaptive(),
                    if (message != null) ...[
                      const SizedBox(height: spacingMd),
                      Text(
                        message!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
