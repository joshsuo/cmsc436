import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:terpiez/calc_close_terp.dart';
import 'package:terpiez/constants.dart';
import 'package:terpiez/notifications.dart';
//import 'package:shared_preferences/shared_preferences.dart';
import 'package:terpiez/screens/home.dart';
//import 'package:terpiez/shared_pref.dart';
import 'package:provider/provider.dart';
import 'package:terpiez/models/my_state.dart';

import 'dart:async';
import 'dart:ui';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:terpiez/bg_test.dart';




// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Permission.notification.isDenied
//   .then((value) {
//     if(value) {
//       Permission.notification.request();
//     }
//   });

//   await initializeService();
//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'demo',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//       ),
//       home: Home()
//     );
//   }
// }

// class Home extends StatefulWidget {
//   const Home({super.key});

//   @override
//   State<Home> createState() => _MyHomeState();
// }

// class _MyHomeState extends State<Home> {
//   String text = 'stop service';
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       //appBar: AppBar(title: Text('Flutter Background Service')),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             ElevatedButton(
//               onPressed: () {
//                 FlutterBackgroundService().invoke('setAsForeground');
//               },
//               child: Text('Set as Foreground Service'),
//             ),
//             ElevatedButton(
//               onPressed: () {
//                 FlutterBackgroundService().invoke('setAsBackground');
//               },
//               child: Text('Set as Background Service'),
//             ),
//             ElevatedButton(
//               onPressed: () async {
//                 final service = FlutterBackgroundService();
//                 bool isRunning = await service.isRunning();
//                 if(isRunning) {
//                   service.invoke('stopService');
//                 } else {
//                   service.startService();
//                 }

//                 if(!isRunning) {
//                   text = 'stop service';
//                 } else {
//                   text = 'start service';
//                 }

//                 setState(() {});
                
//               },
//               child: Text('$text'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

/////////////////////////////////////
void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  final notiPlugin = FlutterLocalNotificationsPlugin();
  final launchDetails = await notiPlugin.getNotificationAppLaunchDetails();
  if (launchDetails?.didNotificationLaunchApp ?? false) {
    NotificationRouter.lastPayload = 'open_finder';
  }


  await Notifications().initNoti();

  await Permission.notification.isDenied
  .then((value) {
    if(value) {
      Permission.notification.request();
    }
  });

  //determinePosition();

  await Future.delayed(Duration(milliseconds: 200));
  await initializeService();
    

  runApp(
    ChangeNotifierProvider(
      //create: (context) => MyState(prefs),
      create: (context) => MyState(),
      child: Home()
      
      // test for after noti tap
      //child: Home(initialPayload: payload,)
    )
  );
}
