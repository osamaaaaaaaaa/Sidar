import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skincare/Services/routine_notification_service.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('RoutineNotificationService tests', () {
    test('Default values and constants', () async {
      final service = RoutineNotificationService.instance;
      expect(RoutineNotificationService.morningNotificationId, 101);
      expect(RoutineNotificationService.eveningNotificationId, 102);
      expect(RoutineNotificationService.testNotificationId, 103);
      expect(RoutineNotificationService.channelId, 'daily_routine_channel');

      final isEnabled = await service.isEnabled();
      expect(isEnabled, isFalse);

      final morningTime = await service.getMorningTime();
      expect(morningTime.hour, 8);
      expect(morningTime.minute, 30);

      final eveningTime = await service.getEveningTime();
      expect(eveningTime.hour, 21);
      expect(eveningTime.minute, 0);
    });

    test(
      'Updating morning and evening times persists to SharedPreferences',
      () async {
        final service = RoutineNotificationService.instance;

        await service.updateMorningTime(const TimeOfDay(hour: 7, minute: 15));
        final updatedMorning = await service.getMorningTime();
        expect(updatedMorning.hour, 7);
        expect(updatedMorning.minute, 15);

        await service.updateEveningTime(const TimeOfDay(hour: 22, minute: 45));
        final updatedEvening = await service.getEveningTime();
        expect(updatedEvening.hour, 22);
        expect(updatedEvening.minute, 45);
      },
    );

    test('Toggling enabled state persists to SharedPreferences', () async {
      final service = RoutineNotificationService.instance;

      await service.setEnabled(false);
      expect(await service.isEnabled(), isFalse);

      await service.setEnabled(true);
      expect(await service.isEnabled(), isTrue);
    });

    test('updateFromAnalysis saves summarized routine steps', () async {
      final service = RoutineNotificationService.instance;

      await service.updateFromAnalysis(
        morningSteps: ['غسول لطيف', 'سيروم فيتامين C', 'واقي شمس واسع'],
        eveningSteps: ['تنظيف رغوي', 'سيروم ريتينول', 'مرطب حاجز البشرة'],
      );

      final prefs = await SharedPreferences.getInstance();
      final morningSummary = prefs.getString(
        RoutineNotificationService.prefMorningSummary,
      );
      final eveningSummary = prefs.getString(
        RoutineNotificationService.prefEveningSummary,
      );

      expect(morningSummary, contains('غسول لطيف'));
      expect(morningSummary, contains('واقي شمس واسع'));
      expect(eveningSummary, contains('تنظيف رغوي'));
      expect(eveningSummary, contains('مرطب حاجز البشرة'));
    });

    test('Timezone and scheduled date math calculations', () {
      tz.initializeTimeZones();
      final now = tz.TZDateTime.now(tz.local);

      // Verify TZDateTime creation
      final target = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        8,
        30,
      );
      expect(target.hour, 8);
      expect(target.minute, 30);
    });
  });
}
