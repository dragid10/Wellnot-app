// onboarding_screen.dart: First-launch onboarding walkthrough.
//
// Displays a full-screen PageView with dot indicators, Skip button, and
// Next/Get Started navigation. Shown once on first launch, then never again.
// Uses icons (not screenshots) for zero asset maintenance.
//
// Cross-ref:
//   - Onboarding data: constants/onboarding.dart (page definitions + layout)
//   - Layout constants: constants/layout.dart
//   - Controlled by: app.dart (Stack overlay, same pattern as lock screen)
//   - Persisted by: services/preferences_service.dart (hasSeenOnboarding)

import 'package:flutter/material.dart';
import '../constants/layout.dart';
import '../constants/onboarding.dart';

/// Full-screen onboarding walkthrough shown on first launch.
///
/// Contains a [PageView] with [onboardingPages] and navigation controls.
/// Calls [onComplete] when the user finishes or skips the walkthrough.
class OnboardingScreen extends StatefulWidget {
  /// Called when the user completes or skips the walkthrough.
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  bool get _isLastPage => _currentPage == onboardingPages.length - 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Animates to the next page.
  void _nextPage() {
    _pageController.nextPage(
      duration: Duration(milliseconds: onboardingPageAnimationMs),
      curve: Curves.easeInOut,
    );
  }

  /// Completes the onboarding — called by both Skip and Get Started.
  void _complete() {
    widget.onComplete();
  }

  /// Builds a single onboarding page with icon, title, and description.
  Widget _buildPage(OnboardingPage page) {
    final theme = Theme.of(context);

    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: onboardingDescriptionPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            page.icon,
            size: onboardingIconSize,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: spacingXl + spacingLg),
          Text(
            page.title,
            style: theme.textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: spacingMd),
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the animated dot indicators.
  Widget _buildDotIndicators() {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(onboardingPages.length, (index) {
        final isActive = index == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: onboardingDotAnimationMs),
          margin: const EdgeInsets.symmetric(horizontal: spacingXs),
          height: onboardingDotSize,
          width: isActive ? onboardingActiveDotWidth : onboardingDotSize,
          decoration: BoxDecoration(
            color: isActive
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(onboardingDotSize / 2),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // Skip button — hidden on the last page.
              Align(
                alignment: Alignment.centerRight,
                child: _buildSkipButton(),
              ),

              // Page content.
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: onboardingPages.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return _buildPage(onboardingPages[index]);
                  },
                ),
              ),

              // Dot indicators.
              _buildDotIndicators(),
              const SizedBox(height: spacingXl),

              // Bottom button — Next or Get Started.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: spacingXl),
                child: SizedBox(
                  width: double.infinity,
                  child: _buildBottomButton(),
                ),
              ),
              const SizedBox(height: spacingXl),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the Skip button, or an empty SizedBox on the last page
  /// to preserve layout height.
  Widget _buildSkipButton() {
    if (_isLastPage) {
      return const SizedBox(height: 48);
    }
    return TextButton(
      onPressed: _complete,
      child: const Text('Skip'),
    );
  }

  /// Builds the bottom action button — Next on pages 0..n-2,
  /// Get Started on the last page.
  Widget _buildBottomButton() {
    if (_isLastPage) {
      return FilledButton(
        onPressed: _complete,
        child: const Text('Get Started'),
      );
    }
    return FilledButton(
      onPressed: _nextPage,
      child: const Text('Next'),
    );
  }
}
