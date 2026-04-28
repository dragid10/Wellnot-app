// constants/onboarding.dart: Onboarding walkthrough page definitions.
//
// Defines the data model and content for the first-launch onboarding screens.
// Uses Flutter's built-in Icons for illustrations — no image assets needed,
// so pages never go stale when the UI changes.
//
// Cross-ref:
//   - Consumed by: screens/onboarding_screen.dart
//   - Layout constants shared with: constants/layout.dart

import 'package:flutter/material.dart';

/// Data model for a single onboarding page.
class OnboardingPage {
  /// The Material icon displayed as the page illustration.
  final IconData icon;

  /// The page title displayed below the icon.
  final String title;

  /// A short description explaining the feature.
  final String description;

  const OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
  });
}

/// Onboarding pages displayed on first launch.
///
/// Order matters — these are shown as a PageView in sequence.
const List<OnboardingPage> onboardingPages = [
  OnboardingPage(
    icon: Icons.favorite_outline,
    title: 'Welcome to Wellnot',
    description: 'Your personal symptom and mood tracker. Everything is stored '
        'locally on your device \u2014 private and offline.',
  ),
  OnboardingPage(
    icon: Icons.edit_note,
    title: 'Log Symptoms',
    description: 'Track what you\u2019re feeling with quick symptom entries. '
        'Add severity levels to capture how intense each symptom is.',
  ),
  OnboardingPage(
    icon: Icons.mood,
    title: 'Track Your Mood',
    description: 'Record your mood with each entry using emoji. See patterns '
        'in how you feel over time.',
  ),
  OnboardingPage(
    icon: Icons.label_outline,
    title: 'Tag for Context',
    description:
        'Add tags like \u201CAfter Meal\u201D or \u201CPoor Sleep\u201D to capture what '
        'was happening when symptoms occurred.',
  ),
  OnboardingPage(
    icon: Icons.insights,
    title: 'Review Your History',
    description: 'Browse your calendar to see entries by day, or check the '
        'summary for trends across any date range.',
  ),
];

// ---------------------------------------------------------------------------
// Onboarding layout constants
// ---------------------------------------------------------------------------

/// Size of the icon illustration on each onboarding page.
const double onboardingIconSize = 96.0;

/// Diameter of inactive dot indicators.
const double onboardingDotSize = 8.0;

/// Width of the active dot indicator (pill shape).
const double onboardingActiveDotWidth = 24.0;

/// Horizontal padding for the description text on onboarding pages.
const double onboardingDescriptionPadding = 40.0;

/// Duration of the dot indicator animation in milliseconds.
const int onboardingDotAnimationMs = 300;

/// Duration of the page transition animation in milliseconds.
const int onboardingPageAnimationMs = 400;
