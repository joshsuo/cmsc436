import 'dart:async';

import 'package:flutter/material.dart';
//import 'package:provider/provider.dart';
import 'package:terpiez/models/my_state.dart';
import 'package:terpiez/notifications.dart';
//import 'package:terpiez/screens/second.dart';
import 'package:terpiez/screens/tab_finder.dart';
import 'package:terpiez/screens/tab_list.dart';
import 'package:terpiez/screens/tab_stats.dart';
//import 'package:provider/provider.dart';
//import 'package:terpiez/models/my_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:redis/redis.dart';
import 'package:uuid/uuid.dart';
import 'package:terpiez/constants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  // test for after noti tap
  // final String? initialPayload;
  // const Home({super.key, this.initialPayload});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Tabs Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Terpiez',),
      //home: MyHomePage(title: 'Terpiez', initialPayload: initialPayload),
    );
  }
}

class MyHomePage extends StatefulWidget {
  // final String? initialPayload;
  // const MyHomePage({super.key, required this.title, this.initialPayload});

  const MyHomePage({super.key, required this.title});
  final String title;
  

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin {
  MyState myState = MyState();
  //SharedPreferences? _prefs;
  final storage = FlutterSecureStorage();
  String? userID;

  // after noti tap
  bool _handledNotification = false;

  Timer? timer;
  bool? prev_conn = false;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();

    timer = Timer.periodic(Duration(seconds: 10), (Timer t) => _checkConn());

    _tabController = TabController(length: 3, vsync: this);
    NotificationRouter.register(() {
      _tabController.animateTo(1);
    });

    print('init state');

    
  }

  @override
  void dispose() {
    super.dispose();
    _tabController.dispose();
  }

 

  // after noti tap
  // @override
  // void didChangeDependencies() {
  //   print('in change dep');
  //   super.didChangeDependencies();

  //   if (!_handledNotification) {
  //     _handledNotification = true;

  //     WidgetsBinding.instance.addPostFrameCallback((_) {
  //       if (widget.initialPayload == 'open_finder') {
  //         final controller = DefaultTabController.of(context);
  //         controller.animateTo(1); // go to Finder tab
  //       }
  //     });
  //   }
  // }

  void _checkConn() async {
    print('check conn');
    var command;

    try {
      final RedisConnection conn = RedisConnection();
      command = await conn.connect(Constants.redisServer, Constants.portNumber)
      .timeout(Duration(seconds: 1));

      if(prev_conn == false) {
        const snackBar = 
        SnackBar(
          content: Text('Connected!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        );
        //prev_conn =  false;

        ScaffoldMessenger.of(context).showSnackBar(snackBar);

        prev_conn = true;
      }
    } catch(e) {
      if(prev_conn == true) {
        const snackBar = 
        SnackBar(
          content: Text('Disconnected!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        );
        //prev_conn =  false;

        ScaffoldMessenger.of(context).showSnackBar(snackBar);

        prev_conn = false;
      }
    } finally {
      //command.dispose();
    }
  }

  // Future<void> _handleNotificationLaunch() async {
  //   final notiPlugin = FlutterLocalNotificationsPlugin();

  //   final launchDetails = await notiPlugin.getNotificationAppLaunchDetails();

  //   if (launchDetails?.didNotificationLaunchApp ?? false) {
  //     final payload = launchDetails?.notificationResponse?.payload;

  //     if (payload == 'open_finder') {
  //       final tabController = DefaultTabController.of(context);
  //       if (tabController != null) {
  //         tabController.animateTo(1); // Switch to Finder tab (index 1)
  //       }
  //     }
  //   }
  // }



  Future<File> _createJSONFile() async {
    final directory = await getApplicationDocumentsDirectory();
    String path = '${directory.path}/${Constants.infoJsonFileName}';

    final jsonFile = File(path);

    await jsonFile.writeAsString('[]');

    return File(path);
  }

  Future<void> _checkLoginStatus() async {
    //SharedPreferences prefs = await SharedPreferences.getInstance();
    SharedPreferences.getInstance().then((pref) async {
      setState(() {
        userID = pref.getString(Constants.userIDKey);
      });

      //print(userID);
      if((userID != null && userID.toString().isEmpty) || userID == null) {
        Future.delayed(Duration(seconds: 2), () async {
          var userInfo = await _showLoginAlert(context);
          print(userInfo[0]);
          print(userInfo[1]);
          print(userInfo[2]);

          //pref.setString(Constants.userNameKey, userInfo[0]).then((value) {setState(() {});});
          //pref.setString(Constants.passwordKey, userInfo[1]).then((value) {setState(() {});});
          await storage.write(key: Constants.userNameKey, value: userInfo[0]);
          await storage.write(key: Constants.passwordKey, value: userInfo[1]);
          pref.setString(Constants.userIDKey, userInfo[2]).then((value) {setState(() {});});
          pref.setInt(Constants.terpsCaughtKey, 0).then((value) {setState(() {});});
          pref.setStringList(Constants.speciesCaughtIDKey, []).then((value) {setState(() {});});
          pref.setStringList(Constants.speciesCaughtNameKey, []).then((value) {setState(() {});});
          pref.setStringList(Constants.speciesCaughtTNKey, []).then((value) {setState(() {});});

          pref.setStringList(Constants.allCaughtKey, []).then((value) {setState(() {});});
          pref.setStringList(Constants.locsKey, []).then((value) {setState(() {});});

          pref.setBool(Constants.soundPrefKey, true).then((value) {setState(() {});});
          print('init sound val: ${pref.getBool(Constants.soundPrefKey)}');

          pref.setStringList(Constants.allLocsKey, []).then((value) {setState(() {});});

          //create json file of all terpiez
          _createJSONFile();
        });
      } else {
        String? user = await storage.read(key: Constants.userNameKey);
        String? pass = await storage.read(key: Constants.passwordKey);

        final RedisConnection conn = RedisConnection();
        final command = await conn.connect(Constants.redisServer, Constants.portNumber);
        await command.send_object(['AUTH', user, pass])
        .then((var response) async {
          if(response == 'OK') {
            print("logged in");
          } 
          await conn.close();
        }).catchError((onError) async {
          print("wrong user and pass");
          await conn.close();
        });
        
      }
    });
    
  }

  @override
  Widget build(BuildContext context) {

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Terpiez'),
          backgroundColor: const Color.fromARGB(255, 129, 40, 34),
          foregroundColor: Colors.white,
          bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white,
            tabs: [
              Tab(text: 'Statistics', icon: Icon(Icons.numbers, color: Colors.white)),
              Tab(text: 'Finder', icon: Icon(Icons.search, color: Colors.white)),
              Tab(text: 'List', icon: Icon(Icons.list, color: Colors.white)),
            ],
          ),
        ),
        drawer: Drawer(
          child: ListView(
            children: [
              DrawerHeader(child: Text(
                'Options',
                style: Theme.of(context).textTheme.headlineMedium,
              )),
              ListTile(
                leading:const Icon(Icons.settings),
                title: const Text('Preferences'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                      const PrefPage()
                    )
                  );
                },
              ) 
            ] 
          )
        ),
        body: SafeArea(
          child: TabBarView(
            controller: _tabController,
            children: [

              // Tab 1: Statistics
              StatsTabView(listenable: myState),

              // Tab 2: Finder
              FinderTabView(
                listenable: myState,
                isConn: prev_conn ?? true,
              ),
              
              // Tab 3: List
              ListTabView(listenable: myState)

            ],
          ),
        ),
      ),
    );
  }
}

Future<List<String>> _showLoginAlert(BuildContext context) async {
  
  TextEditingController userController = TextEditingController();
  TextEditingController passController = TextEditingController();
  print('show loging alert code');
  return await showDialog(
    context: context, 
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog(
        title: Text('Enter Credentials for Redis', style: TextStyle(fontSize: 23),),
        content: Column (
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: userController,
              decoration: InputDecoration(hintText: 'Username'),
            ),
            TextFormField(
              controller: passController,
              decoration: InputDecoration(hintText: 'Password'),
              obscureText: true,
            )
          ]
        ),
        actions: [
          TextButton(onPressed: () async {
            final RedisConnection conn = RedisConnection();
            final command = await conn.connect(Constants.redisServer, Constants.portNumber);

            //testing
            // userController.text = 'joshsuo';
            // passController.text = '901354e20b0049b1836717ed650e8649';

            await command.send_object(['AUTH', userController.text, passController.text])
            .then(
              (var response) async {
                //print("resp: $response");
                if(response == 'OK') {
                  var uid = Uuid().v4();
                  await command.send_object(['json.set', 'joshsuo', uid, '{}']);
                  
                  Navigator.pop(context, [userController.text, passController.text, uid]);
                } 
                await conn.close();
              }).catchError((onError) async {
                print("wrong user and pass");
                userController.text = 'Try Again';
                passController.text = '';

                await conn.close();
              });
              
          },
          child: 
            Text('Submit')
          
          )
        ],
      );
    }
  );
}

////////////////////////////////////////////////

// preference page

class PrefPage extends StatefulWidget {
  const PrefPage({super.key});

  @override
  State<PrefPage> createState() => _PrefPageState();
}

class _PrefPageState extends State<PrefPage> {

  SharedPreferences? _prefs;
  bool? soundVal;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((value) {
      setState(() {
        _prefs = value;
        soundVal = _prefs?.getBool(Constants.soundPrefKey);
        print('sound value: $soundVal');
      });
    });

  }

  // Future<bool?> getsoundVal() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   return prefs.getBool(Constants.soundPrefKey);
  //   // if (prefs.getString(Constants.soundPrefKey) != null) {
  //   //   setState(() {
  //   //     soundVal = prefs.getBool(Constants.soundPrefKey);
  //   //   });
  //   // }
  // }

  Future<void> setSoundVal(bool soundVal) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      prefs.setBool(Constants.soundPrefKey, soundVal);
    });
  }

  Future<void> alertResetUser() {
    return showDialog(
        context: context,
        useRootNavigator: true,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            content:  Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning, color: Colors.red, size: 50,),     
                Text('Clear User Data?', style: TextStyle(fontSize: 30),),
                SizedBox(height: 10,),
                Text(
                  'This will reset and delete all your progress. Do you want to continue?', 
                  style: TextStyle(fontSize: 15),
                  textAlign: TextAlign.center,
                ),
              ],
            
              ),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [              
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Expanded (
                      child: Text('Cancel!', style: TextStyle(fontSize: 20),)
                    )
                  ),
                  TextButton(
                    onPressed: () {
                      resetUser();
                      Navigator.of(context).pop();
                    },
                    child: Text('Reset!', style: TextStyle(fontSize: 20),)
                  )
                ]
              )              
            ]
          );
        }
      );
  }
  
  void resetUser() {
    var uid = Uuid().v4();    

    SharedPreferences.getInstance().then((pref) async {

      //setState(() {
        pref.setString(Constants.userIDKey, uid).then((value) {setState(() {});});
        pref.setInt(Constants.terpsCaughtKey, 0).then((value) {setState(() {});});
        pref.setStringList(Constants.speciesCaughtIDKey, []).then((value) {setState(() {});});
        pref.setStringList(Constants.speciesCaughtNameKey, []).then((value) {setState(() {});});
        pref.setStringList(Constants.speciesCaughtTNKey, []).then((value) {setState(() {});});
        pref.setStringList(Constants.allCaughtKey, []).then((value) {setState(() {});});
        pref.setStringList(Constants.locsKey, []).then((value) {setState(() {});});
      //});

    });
  }


  @override
  Widget build(BuildContext context) {
    return (soundVal == null) 
      ? Center(child: Text(''))
      :
    Scaffold(
      appBar: AppBar(title: Text('Preferences')),
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Expanded(
                  //   flex: 2,
                  //   child:                   
                  // ),
                  Text('Play Sounds' , style: TextStyle(fontSize: 19)),
                  SizedBox(width: 4),
                  Switch(
                    value: soundVal!,
                    activeColor: Colors.red,
                    onChanged: (bool value) {
                      setState(() {
                        soundVal = value;
                        setSoundVal(soundVal!);
                        print('soundVal: $soundVal');
                      });
                    },
                  ),
                ]
              ),
              SizedBox(height: 25),
              TextButton(
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    side: BorderSide(color: Colors.grey, width: 1),
                  ),
                ),
                onPressed: () {
                  alertResetUser();
                }, 
                child: const Text('Reset User', 
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 18
                  ),
                )
              ),
            ]
          )
        )
      )
    );
  }
}


