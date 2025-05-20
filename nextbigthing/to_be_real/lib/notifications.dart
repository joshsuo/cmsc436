import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class Notifications {
  final notiPlugin = FlutterLocalNotificationsPlugin();

  bool _isInit = false;

  bool get isInit => _isInit;

  

  Future<void> initNoti() async {
    if(_isInit) return;

    tz.initializeTimeZones();
    final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(currentTimeZone));

    const AndroidInitializationSettings initSetAndroid = 
      AndroidInitializationSettings("@mipmap/ic_launcher");

    const DarwinInitializationSettings initSetIOS = 
      DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true
    );

    const InitializationSettings initSettings = 
      InitializationSettings(
      android: initSetAndroid,
      iOS: initSetIOS
    );

    await notiPlugin.initialize(initSettings);

    _isInit = true;
  }

  NotificationDetails notiDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_channel_id',
        'Daily Notification',
        channelDescription: 'Daily Notification Channel',
        importance: Importance.max,
        priority: Priority.high
      ),
      iOS: DarwinNotificationDetails()
    );
  }

  Future<void> showNoti({
    int id = 0,
    String? title,
    String? body,
    String? payload,
  }) async {
    print('inside show noti');
    return notiPlugin.show(id, title, body, notiDetails(),);
  }

  // Future<void> scheduleNoti({
  //   int id = 1,
  //   required String title,
  //   required String body,
  //   required int day,
  //   required int hour,
  //   required int min,
  //   //required bool recurr,
  // }) async {
  //   final now = tz.TZDateTime.now(tz.local);

  //   var scheduledDate = tz.TZDateTime(
  //     tz.local,
  //     now.year,
  //     now.month,
  //     day,
  //     hour,
  //     min
  //   );

  //   print('inside schedule noti');

  //   await notiPlugin.zonedSchedule(
  //     id, title, body, scheduledDate, notiDetails(), 
  //     androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle
  //     //matchDateTimeComponents: DateTimeComponents.time,
  //   );

  // }

  Future<void> scheduleNoti(String title, String body, DateTime dt) async {

    await notiPlugin.zonedSchedule(
      0, title, body, tz.TZDateTime.from(dt, tz.local), notiDetails(), 
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle
      //matchDateTimeComponents: DateTimeComponents.time,
    );

  }

  Future<void> cancelAllNoti() async {
    await notiPlugin.cancelAll();
  }

}

