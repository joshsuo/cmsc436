import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:terpiez/models/my_state.dart';
import 'package:terpiez/constants.dart';
import 'package:terpiez/notifications.dart';



class StatsTabView extends StatefulWidget {
  const StatsTabView({super.key, required this.listenable});
  final MyState listenable;

  @override
  _StatsTabViewState createState() => _StatsTabViewState();
}

class _StatsTabViewState extends State<StatsTabView> {
  SharedPreferences? _prefs;

  @override
  void initState() {
    super.initState();
      SharedPreferences.getInstance().then((value) {
      setState(() {
        _prefs = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    

    // Future.delayed(Duration(seconds: 2), (){_showLoginAlert(context);});

    return (
      Consumer<MyState> (
        builder: (context, state, child) =>
        LayoutBuilder(
          builder: (context, constraints) {
            return 
            // Column(
            //   children: [
            Column(                    
              children: [
                Container(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: Text('Statistics',
                    style: TextStyle(fontSize: 50, fontWeight: FontWeight.bold))
                ),
                
                Padding(
                  padding: EdgeInsets.only(left: 10),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: Text('Terpiez found: ', style: TextStyle(fontSize: 20)),
                      ),
                      
                      Expanded(
                        flex: 5,
                        child: Text('${_prefs?.getInt(Constants.terpsCaughtKey) ?? 0}', style: TextStyle(fontSize: 20))
                      )
                    ],
                  ),
                ),
                
                Padding(
                  padding: EdgeInsets.only(left: 10),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: Text('Days Active: ', style: TextStyle(fontSize: 20)),
                      ),
                      Expanded(
                        flex: 5,
                        child: Text('${state.daysPlayed}', style: TextStyle(fontSize: 20))
                      )
                    ],
                  ),
                ),

                Expanded(
                  child: 
                      Center(child: Text('User: ${_prefs?.getString(Constants.userIDKey) ?? 'none'}'))
                      //Center(child: Text(_prefs?.getString('userID') ?? 'none'))
                ),
                // TextButton(onPressed: () async {
                //   //String text
                //   final service = FlutterBackgroundService();
                // bool isRunning = await service.isRunning();
                // if(isRunning) {
                //   service.invoke('stopService');
                // } else {
                //   service.startService();
                // }
                //   //Notifications().terpNoti(16);
                // },
                // // child: const Text('noti button')
                // child: const Text('service')
                // )

                // TextButton(
                //   onPressed: () {
                //     NotificationRouter.goToFinderTab();
                //   }, 
                //   child: const Text('go to finder')
                // )
              ],
            );
          }
        )
      )
    );
  }
}


