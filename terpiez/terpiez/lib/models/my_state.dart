// import 'package:flutter/material.dart';
// import 'package:terpiez/shared_pref.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// import 'package:uuid/uuid.dart';

// class MyState extends ChangeNotifier {
//   static const String _userIDKey = 'userID';
//   static const String _startDate = 'firstDate';
//   String? userID;
//   String? startDate;
//   SharedPreferences? _prefs;
  
//   //final prefs = SharedPreferences.getInstance();

//   //MyState.empty();
//   MyState.fromEmpty();

//   MyState(SharedPreferences prefs) {
//     _prefs = prefs;

//     userID = prefs.getString(_userIDKey);
//     startDate = prefs.getString(_startDate);

//     // set userID
//     if (userID == null) {
//       userID = Uuid().v1();
//       prefs.setString(_userIDKey, userID.toString());
//     }

//     // set first date played
//     if (userID == null) {
//       startDate = DateTime.now().toIso8601String();
//       prefs.setString(_startDate, startDate.toString());
//     }
//   }

//   int terpsFound = 0;
//   //final DateTime startDate = ;
//   int daysPlayed = 0;//DateTime.now().difference(DateTime.parse(firstDate.toString())).inDays; // use DateTime and Duration
//   // int daysPlayed = startDate.difference(DateTime.now()).inDays;
//   //var userId = sessionManager.userId; 
//   //_prefs.setString(_userIDKey, Uuid().v1()); //Uuid().v1();
  
//   void calcDaysPlayed() {
//     daysPlayed = DateTime.now().difference(DateTime.parse(startDate.toString())).inDays.abs();
//     //print("$daysPlayed");
//     notifyListeners();
//   }

//   void increment() {
//     terpsFound++;
//     //print("inside & $terpsFound");
//     notifyListeners();
//   }
// }



import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class MyState extends ChangeNotifier {
  
  //List<String> tabs = [];
  int terpsFound = 0;
  final DateTime startDate = DateTime.now();
  int daysPlayed = 0; // use DateTime and Duration
  // int daysPlayed = startDate.difference(DateTime.now()).inDays;
  var uuid = Uuid(); 

  
  

  void increment() {
    terpsFound++;
    print("inside & $terpsFound");
    notifyListeners();
  }
}
