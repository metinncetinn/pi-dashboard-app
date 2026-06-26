import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static Future<void> init() async {
    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'reminders',
          channelName: 'Hatırlatıcılar',
          channelDescription: 'Pi Dashboard hatırlatıcı bildirimleri',
          defaultColor: const Color(0xFFC8FF00),
          ledColor: const Color(0xFFC8FF00),
          importance: NotificationImportance.High,
          channelShowBadge: true,
          playSound: true,
          enableVibration: true,
        ),
      ],
    );
  }

  static Future<bool> requestPermission() async {
    return await AwesomeNotifications().requestPermissionToSendNotifications();
  }

  static Future<void> show({
    required int id,
    required String title,
    required String body,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'reminders',
        title: title,
        body: body,
        notificationLayout: NotificationLayout.Default,
      ),
    );
  }

  static Future<void> scheduleOnce({
    required int id,
    required String title,
    required String body,
    required DateTime fireAt,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'reminders',
        title: title,
        body: body,
      ),
      schedule: NotificationCalendar.fromDate(date: fireAt),
    );
  }

  static Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'reminders',
        title: title,
        body: body,
      ),
      schedule: NotificationCalendar(
        hour: hour,
        minute: minute,
        second: 0,
        repeats: true,
      ),
    );
  }

  static Future<void> scheduleWeekly({
    required int id,
    required String title,
    required String body,
    required int weekday,
    required int hour,
    required int minute,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'reminders',
        title: title,
        body: body,
      ),
      schedule: NotificationCalendar(
        weekday: weekday + 1,
        hour: hour,
        minute: minute,
        second: 0,
        repeats: true,
      ),
    );
  }

  static Future<void> cancel(int id) async {
    await AwesomeNotifications().cancel(id);
  }

  static Future<void> cancelAll() async {
    await AwesomeNotifications().cancelAll();
  }
}