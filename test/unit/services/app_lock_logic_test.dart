// app_lock_logic_test.dart: Tests for shouldLockOnResume() logic.
//
// Verifies the static method that determines whether the app should re-lock
// after resuming from the background, based on the enabled flag, last paused
// timestamp, and grace period.
//
// Cross-ref:
//   - Method under test: PreferencesService.shouldLockOnResume()
//   - Consumed by: app.dart (WidgetsBindingObserver.didChangeAppLifecycleState)

import 'package:flutter_test/flutter_test.dart';
import 'package:symptom_tracker_app/services/preferences_service.dart';

void main() {
  group('PreferencesService.shouldLockOnResume', () {
    // Returns false when app lock is disabled, regardless of other parameters.
    test(
        'As a user, I expect the app to not lock on resume when app lock is disabled',
        () {
      final result = PreferencesService.shouldLockOnResume(
        appLockEnabled: false,
        lastPausedAt: null,
        gracePeriodSeconds: 0,
      );
      expect(result, false);
    });

    // Returns false when app lock is disabled even with expired grace period.
    test(
        'As a user, I expect the app to not lock on resume when app lock is disabled even if grace period has expired',
        () {
      final result = PreferencesService.shouldLockOnResume(
        appLockEnabled: false,
        lastPausedAt: DateTime.now().subtract(const Duration(minutes: 10)),
        gracePeriodSeconds: 30,
      );
      expect(result, false);
    });

    // Returns false when the app has not been backgrounded yet — cold start
    // locking is handled separately by initState.
    test(
        'As a user, I expect the app to not re-lock after authenticating if I have not left the app',
        () {
      final result = PreferencesService.shouldLockOnResume(
        appLockEnabled: true,
        lastPausedAt: null,
        gracePeriodSeconds: 30,
      );
      expect(result, false);
    });

    // Same behavior regardless of grace period value.
    test(
        'As a user, I expect the app to not re-lock after authenticating if I have not left the app regardless of grace period',
        () {
      final result = PreferencesService.shouldLockOnResume(
        appLockEnabled: true,
        lastPausedAt: null,
        gracePeriodSeconds: 60,
      );
      expect(result, false);
    });

    // Returns true when elapsed time exceeds grace period.
    test(
        'As a user, I expect the app to lock when the time away exceeds the grace period',
        () {
      final result = PreferencesService.shouldLockOnResume(
        appLockEnabled: true,
        lastPausedAt: DateTime.now().subtract(const Duration(seconds: 45)),
        gracePeriodSeconds: 30,
      );
      expect(result, true);
    });

    // Returns false when elapsed time is within grace period.
    test(
        'As a user, I expect the app to not lock when the time away is within the grace period',
        () {
      final result = PreferencesService.shouldLockOnResume(
        appLockEnabled: true,
        lastPausedAt: DateTime.now().subtract(const Duration(seconds: 10)),
        gracePeriodSeconds: 30,
      );
      expect(result, false);
    });

    // Returns true at the exact grace period boundary (>= comparison).
    test(
        'As a user, I expect the app to lock when the time away equals the grace period exactly',
        () {
      final result = PreferencesService.shouldLockOnResume(
        appLockEnabled: true,
        lastPausedAt: DateTime.now().subtract(const Duration(seconds: 30)),
        gracePeriodSeconds: 30,
      );
      expect(result, true);
    });

    // Returns true when grace period is 0 (immediately) and any time has passed.
    test(
        'As a user, I expect the app to lock immediately when grace period is 0 and any time has passed',
        () {
      final result = PreferencesService.shouldLockOnResume(
        appLockEnabled: true,
        lastPausedAt: DateTime.now().subtract(const Duration(seconds: 1)),
        gracePeriodSeconds: 0,
      );
      expect(result, true);
    });

    // Returns true when grace period is 0 even if lastPausedAt is right now,
    // because 0 elapsed seconds >= 0 grace period.
    test(
        'As a user, I expect the app to lock when grace period is 0 even if paused just now',
        () {
      final result = PreferencesService.shouldLockOnResume(
        appLockEnabled: true,
        lastPausedAt: DateTime.now(),
        gracePeriodSeconds: 0,
      );
      expect(result, true);
    });

    // Returns true with a large elapsed time and 1-minute grace period.
    test(
        'As a user, I expect the app to lock when away for several minutes with a 1-minute grace period',
        () {
      final result = PreferencesService.shouldLockOnResume(
        appLockEnabled: true,
        lastPausedAt: DateTime.now().subtract(const Duration(minutes: 5)),
        gracePeriodSeconds: 60,
      );
      expect(result, true);
    });

    // Returns false with a short elapsed time and 1-minute grace period.
    test(
        'As a user, I expect the app to not lock when away for only 20 seconds with a 1-minute grace period',
        () {
      final result = PreferencesService.shouldLockOnResume(
        appLockEnabled: true,
        lastPausedAt: DateTime.now().subtract(const Duration(seconds: 20)),
        gracePeriodSeconds: 60,
      );
      expect(result, false);
    });
  });
}
