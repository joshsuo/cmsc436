// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:uuid/uuid.dart';

// class UserSessionManager {
//   static const _userIdKey = 'userId';
//   static const _firstRunKey = 'firstRunDate';

//   late SharedPreferences _prefs;
//   late String userId;
//   late DateTime firstRunDate;

//   Future<void> init() async {
//     _prefs = await SharedPreferences.getInstance();

//     userId = _prefs.getString(_userIdKey) ?? const Uuid().v1();

//     firstRunDate = _prefs.containsKey(_firstRunKey)
//         ? DateTime.parse(_prefs.getString(_firstRunKey)!)
//         : DateTime.now();

//     // sets uuid to final string
//     if (!_prefs.containsKey(_userIdKey)) {
//       await _prefs.setString(_userIdKey, userId);
//     }
//     // sets date to first run date in string
//     if (!_prefs.containsKey(_firstRunKey)) {
//       await _prefs.setString(_firstRunKey, firstRunDate.toIso8601String());
//     }
//   }

//   // sub today - first date => days active
//   int get daysActive => DateTime.now().difference(firstRunDate).inDays;
// }

// // singleton
// final sessionManager = UserSessionManager();




import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsTab extends StatefulWidget {
  const SharedPrefsTab({super.key});
  
  @override
  State<StatefulWidget> createState() => _SharedPrefsState();
}

class _SharedPrefsState extends State<SharedPrefsTab> {
  static const String _userNameKey = 'userName';
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
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Center(
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(child: Text('User Name:')),
                Expanded(
                  child: Text(
                    _prefs?.getString(_userNameKey) ?? 'not specified')),
              ],
            ),
            TextButton(
              onPressed: () {
                  _prefs?.setString(_userNameKey, 'mmarsh').then(
                    (value) { setState(() {}); });
              },
              child: const Text('Set User Name'),
            )])));
  }
}