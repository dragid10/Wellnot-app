// onboarding_screen_test.dart: Widget tests for the onboarding walkthrough.
//
// Verifies layout, page navigation (buttons and swipe), dot indicators,
// Skip/Next/Get Started button behavior, and onComplete callbacks.
//
// Cross-ref:
//   - Screen under test: lib/screens/onboarding_screen.dart
//   - Onboarding data: lib/constants/onboarding.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:symptom_tracker_app/constants/onboarding.dart';
import 'package:symptom_tracker_app/screens/onboarding_screen.dart';

/// Pumps the onboarding screen into a testable widget tree.
Future<void> pumpOnboarding(
  WidgetTester tester, {
  required VoidCallback onComplete,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
      ),
      home: OnboardingScreen(onComplete: onComplete),
    ),
  );
  await tester.pumpAndSettle();
}

/// Navigates to the last onboarding page by tapping Next repeatedly.
Future<void> navigateToLastPage(WidgetTester tester) async {
  for (int i = 0; i < onboardingPages.length - 1; i++) {
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
  }
}

void main() {
  // ---------------------------------------------------------------------------
  // Layout — first page
  // ---------------------------------------------------------------------------
  group('Layout', () {
    testWidgets(
        'As a user, I expect to see the welcome title on the first onboarding page',
        (tester) async {
      await pumpOnboarding(tester, onComplete: () {});

      expect(find.text(onboardingPages[0].title), findsOneWidget);
    });

    testWidgets(
        'As a user, I expect to see the welcome description on the first onboarding page',
        (tester) async {
      await pumpOnboarding(tester, onComplete: () {});

      expect(find.text(onboardingPages[0].description), findsOneWidget);
    });

    testWidgets(
        'As a user, I expect to see an icon on the first onboarding page',
        (tester) async {
      await pumpOnboarding(tester, onComplete: () {});

      expect(find.byIcon(onboardingPages[0].icon), findsOneWidget);
    });

    testWidgets(
        'As a user, I expect to see a Skip button on the first onboarding page',
        (tester) async {
      await pumpOnboarding(tester, onComplete: () {});

      expect(find.text('Skip'), findsOneWidget);
    });

    testWidgets(
        'As a user, I expect to see a Next button on the first onboarding page',
        (tester) async {
      await pumpOnboarding(tester, onComplete: () {});

      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets(
        'As a user, I expect to see dot indicators for all onboarding pages',
        (tester) async {
      await pumpOnboarding(tester, onComplete: () {});

      // Each dot is an AnimatedContainer inside a Row. Find the dot
      // indicator row by looking for AnimatedContainers — there should be
      // one per page.
      final dots = find.byType(AnimatedContainer);
      expect(dots, findsNWidgets(onboardingPages.length));
    });
  });

  // ---------------------------------------------------------------------------
  // Navigation
  // ---------------------------------------------------------------------------
  group('Navigation', () {
    testWidgets(
        'As a user, I expect tapping Next to advance to the second onboarding page',
        (tester) async {
      await pumpOnboarding(tester, onComplete: () {});

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text(onboardingPages[1].title), findsOneWidget);
    });

    testWidgets(
        'As a user, I expect each page to show its correct title after navigating',
        (tester) async {
      await pumpOnboarding(tester, onComplete: () {});

      for (int i = 1; i < onboardingPages.length; i++) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
        expect(find.text(onboardingPages[i].title), findsOneWidget);
      }
    });

    testWidgets(
        'As a user, I expect the Skip button to be hidden on the last page',
        (tester) async {
      await pumpOnboarding(tester, onComplete: () {});

      await navigateToLastPage(tester);

      expect(find.text('Skip'), findsNothing);
    });

    testWidgets(
        'As a user, I expect to see Get Started instead of Next on the last page',
        (tester) async {
      await pumpOnboarding(tester, onComplete: () {});

      await navigateToLastPage(tester);

      expect(find.text('Get Started'), findsOneWidget);
      expect(find.text('Next'), findsNothing);
    });
  });

  // ---------------------------------------------------------------------------
  // Completion
  // ---------------------------------------------------------------------------
  group('Completion', () {
    testWidgets(
        'As a user, I expect tapping Get Started on the last page to call onComplete',
        (tester) async {
      bool completed = false;
      await pumpOnboarding(tester, onComplete: () => completed = true);

      await navigateToLastPage(tester);

      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      expect(completed, true);
    });

    testWidgets('As a user, I expect tapping Skip to call onComplete',
        (tester) async {
      bool completed = false;
      await pumpOnboarding(tester, onComplete: () => completed = true);

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(completed, true);
    });
  });

  // ---------------------------------------------------------------------------
  // Swipe navigation
  // ---------------------------------------------------------------------------
  group('Swipe navigation', () {
    testWidgets('As a user, I expect swiping left to advance to the next page',
        (tester) async {
      await pumpOnboarding(tester, onComplete: () {});

      // Swipe left on the PageView to go to the next page.
      await tester.fling(
        find.byType(PageView),
        const Offset(-300, 0),
        1000,
      );
      await tester.pumpAndSettle();

      expect(find.text(onboardingPages[1].title), findsOneWidget);
    });
  });
}
