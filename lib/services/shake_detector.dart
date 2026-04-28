// shake_detector.dart: Detects device shake gestures via accelerometer.
//
// Uses sensors_plus to listen to accelerometer events and fires a callback
// when the device is shaken above a threshold. Used to open the feedback
// screen from anywhere in the app.
//
// Cross-ref:
//   - Consumed by app.dart (wraps the widget tree with shake detection)
//   - Opens: screens/feedback_screen.dart

import 'dart:async';
import 'dart:math';

import 'package:sensors_plus/sensors_plus.dart';

/// Minimum net acceleration (m/s²) required to register as a shake.
const double defaultShakeThreshold = 12.0;

/// Cooldown between shake events (ms) to prevent rapid firing.
const int defaultShakeCooldownMs = 2000;

/// Detects shake gestures using the device accelerometer.
///
/// Calls [onShake] when the device acceleration exceeds [shakeThreshold]
/// with a cooldown of [cooldownMs] between shakes to prevent rapid firing.
class ShakeDetector {
  final void Function() onShake;
  final double shakeThreshold;
  final int cooldownMs;

  StreamSubscription<AccelerometerEvent>? _subscription;
  int _lastShakeTime = 0;

  ShakeDetector({
    required this.onShake,
    this.shakeThreshold = defaultShakeThreshold,
    this.cooldownMs = defaultShakeCooldownMs,
  });

  /// Starts listening to accelerometer events.
  void start() {
    _subscription = accelerometerEventStream().listen((event) {
      final acceleration =
          sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

      // Subtract gravity (~9.8) to get net acceleration.
      final netAcceleration = (acceleration - 9.8).abs();

      if (netAcceleration > shakeThreshold) {
        final now = DateTime.now().millisecondsSinceEpoch;
        if (now - _lastShakeTime > cooldownMs) {
          _lastShakeTime = now;
          onShake();
        }
      }
    });
  }

  /// Stops listening to accelerometer events.
  void stop() {
    _subscription?.cancel();
    _subscription = null;
  }
}
