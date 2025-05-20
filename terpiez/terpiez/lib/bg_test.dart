
import 'dart:async';
import 'dart:developer';
import 'dart:ui';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:terpiez/calc_close_terp.dart';
import 'package:terpiez/main.dart';
import 'package:terpiez/notifications.dart';

Future<void> initializeService() async {
  
  final service = FlutterBackgroundService();
  await service.configure(
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      //onBackground: onIosBackground(service)
    ),
    androidConfiguration: AndroidConfiguration(
      onStart: onStart, 
      autoStart: true,
      isForegroundMode: true,
      autoStartOnBoot: true
    )
  );
  await service.startService();
}

@pragma('vm:entry-point')
//Future<void> onStart(ServiceInstance service) async {
void onStart(ServiceInstance service) async {

  DartPluginRegistrant.ensureInitialized();

  if(service is AndroidServiceInstance) {
    await service.setAsForegroundService();
    await service.setForegroundNotificationInfo(
      title: 'Locating Terpiez...', 
      content: 'Watching for nearby Terpiez...'
    );

    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });
    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // var (terpLocs, terpsId) = await getTerpLocations();
  int closestIndex = -1;

  print('before timer');
  Timer.periodic(Duration(seconds: 5), (timer) async {
    try {
      print('inside timer');
      if(service is AndroidServiceInstance) {
        if(await service.isForegroundService()) {

          var (terpLocs, terpsId) = await getTerpLocations();
          //int closestIndex = -1;

          LatLng loc = await getCurrentLoc();
          print('loc: $loc');

          var (minDistance, minIndex) = await calculateClosestTerpiez(terpLocs);
          print('min dist: $minDistance, min index: $minIndex');

          //notifications
          if(minDistance > 10 && minDistance <= 20 && closestIndex != minIndex) {
              await Notifications().terpNoti(minDistance);
              //await Notifications().terpNoti();
          }
          closestIndex = minIndex;

          //Notifications().terpNoti(1, 'title', '${DateTime.now()}', notiDetails());
          
        } 
      }
      service.invoke('update');
    } catch (e, stack) {
      print('caught error: $e');
      print('stack: $stack');
    }
    print('back service running');
    
  });

}

// @pragma('vm:entry-point')
// void notificationTapBackground(NotificationResponse response) {
//   // ignore: avoid_print
//   print('notification(${response.id}) action tapped: '
//       '${response.actionId} with'
//       ' payload: ${response.payload}');
//   if (response.input?.isNotEmpty ?? false) {
//     // ignore: avoid_print
//     print('notification action tapped with input: ${response.input}');
//   }
// }

// gets closest terpiez
// void backgroundProximityCheck() async {
//   final prefs = await SharedPreferences.getInstance();

//   // Get stored locations
//   final List<String> encodedLocs = prefs.getStringList('terpiez_locations') ?? [];
//   final List<LatLng> terpiezLocs = encodedLocs.map((s) {
//     final parts = s.split(',');
//     return LatLng(double.parse(parts[0]), double.parse(parts[1]));
//   }).toList();

//   final pos = await Geolocator.getCurrentPosition();
//   final userLoc = LatLng(pos.latitude, pos.longitude);
//   final distCalc = Distance();

//   for (final terp in terpiezLocs) {
//     final double d = distCalc.as(LengthUnit.Meter, userLoc, terp);
//     if (d <= 20 && d > 10) {
//       Notifications().terpNoti(d);
//       break;
//     }
//   }
// }


