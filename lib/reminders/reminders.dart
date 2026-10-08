import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../data/asset.dart';
import 'due_dates.dart';

/// Keeps phone notifications in step with the saved assets.
abstract class Reminders {
  Future<void> reschedule(List<Asset> assets);
}

/// Schedules local notifications a week before and on the morning of each
/// due date. Everything stays on the device.
class LocalNotificationReminders implements Reminders {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  /// iOS keeps at most 64 pending notifications per app.
  static const _maxScheduled = 60;
  static const _hour = 9;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'reminders',
      'Reminders',
      channelDescription: 'Premiums, renewals and maturities',
      // Hides the text on a locked screen.
      visibility: NotificationVisibility.private,
    ),
    iOS: DarwinNotificationDetails(),
  );

  Future<void> _init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    final zone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(zone.identifier));
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    _ready = true;
  }

  @override
  Future<void> reschedule(List<Asset> assets) async {
    try {
      await _init();
      await _plugin.cancelAll();
      final now = tz.TZDateTime.now(tz.local);
      final plans = reminderPlan(
        dueEvents(
          assets,
          today: now,
          until: now.add(const Duration(days: 400)),
        ),
        now: now,
      );
      var id = 0;
      for (final plan in plans.take(_maxScheduled)) {
        await _plugin.zonedSchedule(
          id: id++,
          scheduledDate: tz.TZDateTime(
            tz.local,
            plan.at.year,
            plan.at.month,
            plan.at.day,
            _hour,
          ),
          notificationDetails: _details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          title: plan.title,
          body: plan.body,
        );
      }
    } catch (e, stack) {
      // Reminders are a convenience; never let them break the app.
      debugPrint('Could not schedule reminders: $e\n$stack');
    }
  }
}

class ReminderPlan {
  const ReminderPlan(this.at, this.title, this.body);

  /// The day to notify; the time of day is applied when scheduling.
  final DateTime at;
  final String title;
  final String body;
}

/// Turns due events into notifications: one a week before and one on the
/// day, skipping any whose 9am has already passed.
List<ReminderPlan> reminderPlan(
  List<DueEvent> events, {
  required DateTime now,
}) {
  final shown = DateFormat('d MMM yyyy');
  final plans = <ReminderPlan>[];
  for (final e in events) {
    final weekBefore = e.date.subtract(const Duration(days: 7));
    for (final (day, title) in [
      (weekBefore, '${e.label} in 7 days'),
      (e.date, '${e.label} today'),
    ]) {
      final fireAt = DateTime(
        day.year,
        day.month,
        day.day,
        LocalNotificationReminders._hour,
      );
      if (fireAt.isAfter(now)) {
        plans.add(
          ReminderPlan(day, title, '${e.asset.name}, ${shown.format(e.date)}'),
        );
      }
    }
  }
  plans.sort((a, b) => a.at.compareTo(b.at));
  return plans;
}
