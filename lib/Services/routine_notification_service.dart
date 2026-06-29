import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skincare/Utils/AppColors.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Service for managing daily morning and evening skincare routine reminder notifications.
class RoutineNotificationService {
  RoutineNotificationService._();
  static final RoutineNotificationService instance =
      RoutineNotificationService._();

  static const int morningNotificationId = 101;
  static const int eveningNotificationId = 102;
  static const int testNotificationId = 103;

  static const String channelId = 'daily_routine_channel';
  static const String channelName = 'تذكيرات الروتين اليومي';
  static const String channelDescription =
      'تنبيهات يومية للروتين الصباحي والمسائي للعناية بالبشرة والشعر';

  // Preference keys
  static const String prefNotificationsEnabled =
      'routine_notifications_enabled';
  static const String prefMorningHour = 'routine_morning_hour';
  static const String prefMorningMinute = 'routine_morning_minute';
  static const String prefEveningHour = 'routine_evening_hour';
  static const String prefEveningMinute = 'routine_evening_minute';
  static const String prefMorningSummary = 'routine_morning_summary';
  static const String prefEveningSummary = 'routine_evening_summary';

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Initialize notifications and configure local timezone
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      // Graceful fallback to default local timezone in tests/unsupported platforms
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    try {
      await _notifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
      _isInitialized = true;
    } catch (_) {
      // In test or non-mobile environments
      _isInitialized = true;
    }

    // Schedule if previously enabled
    final enabled = await isEnabled();
    if (enabled) {
      await scheduleDailyRoutines();
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    // When notification is tapped, app opens
  }

  /// Request runtime notification permissions for Android 13+ and iOS
  Future<bool> requestPermissions() async {
    bool granted = false;
    try {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidPlugin != null) {
        final res = await androidPlugin.requestNotificationsPermission();
        granted = res ?? false;
      }

      final iosPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (iosPlugin != null) {
        final res = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        granted = res ?? false;
      }
    } catch (_) {
      granted = false;
    }
    return granted;
  }

  /// Check whether routine notifications are enabled
  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    // Notifications remain off until the user explicitly enables this routine.
    // This avoids scheduling or prompting at app start without a user action.
    return prefs.getBool(prefNotificationsEnabled) ?? false;
  }

  /// Get saved morning time (default: 08:30)
  Future<TimeOfDay> getMorningTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt(prefMorningHour) ?? 8;
    final minute = prefs.getInt(prefMorningMinute) ?? 30;
    return TimeOfDay(hour: hour, minute: minute);
  }

  /// Get saved evening time (default: 21:00 / 09:00 PM)
  Future<TimeOfDay> getEveningTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt(prefEveningHour) ?? 21;
    final minute = prefs.getInt(prefEveningMinute) ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  /// Save morning time and re-schedule
  Future<void> updateMorningTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(prefMorningHour, time.hour);
    await prefs.setInt(prefMorningMinute, time.minute);
    if (await isEnabled()) {
      await scheduleDailyRoutines();
    }
  }

  /// Save evening time and re-schedule
  Future<void> updateEveningTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(prefEveningHour, time.hour);
    await prefs.setInt(prefEveningMinute, time.minute);
    if (await isEnabled()) {
      await scheduleDailyRoutines();
    }
  }

  /// Toggle routine notifications on or off
  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefNotificationsEnabled, enabled);

    if (enabled) {
      await requestPermissions();
      await scheduleDailyRoutines();
    } else {
      await cancelDailyRoutines();
    }
  }

  /// Save personalized routine steps from analysis and update reminders
  Future<void> updateFromAnalysis({
    List<String>? morningSteps,
    List<String>? eveningSteps,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (morningSteps != null && morningSteps.isNotEmpty) {
      final summary = morningSteps.take(3).join(' • ');
      await prefs.setString(prefMorningSummary, summary);
    }
    if (eveningSteps != null && eveningSteps.isNotEmpty) {
      final summary = eveningSteps.take(3).join(' • ');
      await prefs.setString(prefEveningSummary, summary);
    }

    if (await isEnabled()) {
      await scheduleDailyRoutines();
    }
  }

  /// Save the tailored routine, then request the operating-system permission
  /// only after the user has explicitly chosen to activate reminders.
  Future<bool> enableFromAnalysis({
    List<String>? morningSteps,
    List<String>? eveningSteps,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (morningSteps != null && morningSteps.isNotEmpty) {
      await prefs.setString(
        prefMorningSummary,
        morningSteps.take(3).join(' • '),
      );
    }
    if (eveningSteps != null && eveningSteps.isNotEmpty) {
      await prefs.setString(
        prefEveningSummary,
        eveningSteps.take(3).join(' • '),
      );
    }

    final granted = await requestPermissions();
    if (!granted) {
      await prefs.setBool(prefNotificationsEnabled, false);
      return false;
    }
    await prefs.setBool(prefNotificationsEnabled, true);
    await scheduleDailyRoutines();
    return true;
  }

  /// Schedule both morning and evening recurring daily notifications
  Future<void> scheduleDailyRoutines() async {
    try {
      final morningTime = await getMorningTime();
      final eveningTime = await getEveningTime();

      final prefs = await SharedPreferences.getInstance();
      final morningCustom = prefs.getString(prefMorningSummary);
      final eveningCustom = prefs.getString(prefEveningSummary);

      final morningBody = (morningCustom != null && morningCustom.isNotEmpty)
          ? 'خطواتك الموصى بها: $morningCustom. حافظ على نضارة بشرتك!'
          : 'ابدأ يومك ببشرة منتعشة ومحمية. نظّف بشرتك، رطّبها، ولا تنسَ واقي الشمس!';

      final eveningBody = (eveningCustom != null && eveningCustom.isNotEmpty)
          ? 'خطواتك المسائية: $eveningCustom. جدد خلايا بشرتك قبل النوم.'
          : 'بشرتك تتجدد أثناء النوم. امنحها التنظيف العميق والترطيب المغذي الآن.';

      final morningDate = _nextInstanceOfTime(
        morningTime.hour,
        morningTime.minute,
      );
      final eveningDate = _nextInstanceOfTime(
        eveningTime.hour,
        eveningTime.minute,
      );

      final notificationDetails = _buildNotificationDetails();

      // Schedule Morning Routine Notification
      await _notifications.zonedSchedule(
        id: morningNotificationId,
        title: 'إشراق الصباح ☀️ | حان وقت روتينك الصباحي',
        body: morningBody,
        scheduledDate: morningDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'morning_routine',
      );

      // Schedule Evening Routine Notification
      await _notifications.zonedSchedule(
        id: eveningNotificationId,
        title: 'عناية المساء 🌙 | حان وقت روتينك المسائي',
        body: eveningBody,
        scheduledDate: eveningDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'evening_routine',
      );
    } catch (_) {
      // Gracefully ignore scheduling failures on unsupported platforms
    }
  }

  /// Cancel daily recurring routine notifications
  Future<void> cancelDailyRoutines() async {
    try {
      await _notifications.cancel(id: morningNotificationId);
      await _notifications.cancel(id: eveningNotificationId);
    } catch (_) {}
  }

  /// Send an immediate test notification so the user can verify notifications
  Future<void> sendTestNotification({bool isMorning = true}) async {
    try {
      await requestPermissions();

      final notificationDetails = _buildNotificationDetails();

      final title = isMorning
          ? 'إشراق الصباح ☀️ | تجربة تذكير الروتين الصباحي'
          : 'عناية المساء 🌙 | تجربة تذكير الروتين المسائي';

      final body = isMorning
          ? 'صباح النضارة! هذا نموذج لإشعار الروتين الصباحي من سدر لمساعدتك على الالتزام بالعناية اليومية.'
          : 'مساء الجمال! هذا نموذج لإشعار الروتين المسائي من سدر لمساعدتك على تجديد بشرتك قبل النوم.';

      await _notifications.show(
        id: testNotificationId,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
        payload: isMorning ? 'morning_test' : 'evening_test',
      );
    } catch (_) {}
  }

  /// Compute next occurrence of a given time (repeats daily)
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  NotificationDetails _buildNotificationDetails() {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      color: AppColors.gold,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    return NotificationDetails(android: androidDetails, iOS: iosDetails);
  }
}
