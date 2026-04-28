import 'package:mocktail/mocktail.dart';
import 'package:symptom_tracker_app/services/notification_service.dart';

/// Mock [NotificationService] for tests that don't need real notifications.
class MockNotificationService extends Mock implements NotificationService {}
