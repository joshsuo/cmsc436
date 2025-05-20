import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:terpiez/screens/tab_finder.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class Notifications {
  final FlutterLocalNotificationsPlugin notiPlugin = FlutterLocalNotificationsPlugin();

  bool _isInit = false;

  bool get isInit => _isInit;

  Future<void> initNoti() async {
    if(_isInit) return;

    const AndroidInitializationSettings initSetAndroid = 
      AndroidInitializationSettings('@mipmap/launcher_icon');

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


    await notiPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('after noti tap');
        print('response: $response');
        if (response.payload == 'open_finder') {
          NotificationRouter.goToFinderTab();
        }
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackgroundHandler
      // onDidReceiveBackgroundNotificationResponse: (NotificationResponse response) {
      //   print('after back noti tap');
      //   print('response: $response');
      //   if (response.payload == 'open_finder') {
      //     NotificationRouter.goToFinderTab();
      //   }
      // },
    );

    _isInit = true;
  }

  NotificationDetails notiDetails() {
    print('in noti details');
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'terpiez_channel',
        'Terpiez Alerts',
        channelDescription: 'Alerts when Terpiez are nearby',
        importance: Importance.max,
        priority: Priority.high
      ),
      iOS: DarwinNotificationDetails()
    );
  }

  Future<void> terpNoti(double m) {
  //Future<void> terpNoti() {
    print('terp noti, m: $m');
      return notiPlugin.show(0, 'Terpiez Near By!!!', 
        'It\'s ${m}m away! Catch it before it escapes!', 
        notiDetails(), 
        payload: 'open_finder'
    );

    // return notiPlugin.show(0, 'Terpiez Near By!!!', 
    //     'It\'s less than 20m away! Catch it before it escapes!', 
    //     notiDetails(), 
    //     payload: 'open_finder'
    // );
  }

  Future<void> cancelAllNoti() async {
    await notiPlugin.cancelAll();
  }

}

@pragma('vm:entry-point')
void notificationTapBackgroundHandler(NotificationResponse response) {
  print('Tapped while app was terminated, payload: ${response.payload}');
  if (response.payload == 'open_finder') {
    // Store this to act on after launch
    //NotificationRouter.goToFinderTab();
    NotificationRouter.lastPayload = 'open_finder';
  }
}

class NotificationRouter {
  static void Function()? _goToFinder;
  static String? lastPayload;

  static void register(void Function() callback) {
    _goToFinder = callback;

    if (lastPayload == 'open_finder') {
      print('Running payload action');
      lastPayload = null;
      _goToFinder?.call();
    }
  }

  static void goToFinderTab() {
    _goToFinder?.call();
  }
}