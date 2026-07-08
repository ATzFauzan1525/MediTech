import 'package:flutter_test/flutter_test.dart';
import 'package:medisync/services/notification_service.dart';

void main() {
  group('NotificationService daily reminder scheduling', () {
    test('uses the same day at 22:00 when the current time is before 22:00', () {
      final now = DateTime(2026, 7, 9, 20, 30);

      final scheduled = NotificationService.computeNextReminderTime(now);

      expect(scheduled, DateTime(2026, 7, 9, 22, 0));
    });

    test('uses the next day at 22:00 when the current time is after 22:00', () {
      final now = DateTime(2026, 7, 9, 23, 15);

      final scheduled = NotificationService.computeNextReminderTime(now);

      expect(scheduled, DateTime(2026, 7, 10, 22, 0));
    });
  });
}
