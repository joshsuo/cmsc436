import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:redis/redis.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:terpiez/constants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';


Future<LatLng> getCurrentLoc() async {
  print('in get curr loc');
  try {
    Position pos = await Geolocator.getCurrentPosition();
    double lat = pos.latitude;
    double long = pos.longitude;

    print('after curr loc: $lat, $long');

    return LatLng(lat, long);
  } catch(e) {
    print('error: $e');
  }
  print('in get curr loc');
  return LatLng(0,0);
}


Future<(List<LatLng>, List<String>)> getTerpLocations() async {
    // if not connected to redis skip
    //if (!widget.isConn) return;
    final storage = FlutterSecureStorage();

    List<LatLng> terpLocs = [];
    List<String> terpsId = [];

    String? user = await storage.read(key: Constants.userNameKey);
    String? pass = await storage.read(key: Constants.passwordKey);

    final RedisConnection conn = RedisConnection();
    final command = await conn.connect(Constants.redisServer, Constants.portNumber);
    await command.send_object(['AUTH', user, pass])
    .then((var response) async {
      if(response == 'OK') {
        print("logged in finder");
        await command.send_object(['JSON.GET', 'locations'])
        .then((var response) async {
          print("locations:");
          final locs = jsonDecode(response);// as Map<String, dynamic>;
          print(locs.length);

          
          
          for(var element in locs) {
            //print('${element["lat"]}, ${element["lon"]}, ${element["id"]}');
            terpLocs.add(LatLng(element["lat"], element["lon"]));
            terpsId.add(element["id"]);
          }
          // if(this.mounted) {
          //   setState(() {
          //     _terpiezLocations = terpLocs;
          //     _terpiezId = terpsId;
          //   });
          // }

        }).catchError((onError) {
          print(onError);
        });
      } 
      await conn.close();
    }).catchError((onError) async {
      print("wrong user and pass");
      await conn.close();
    });

    //print('inside getLocs: $terpLocs, $terpsId');

    return (terpLocs, terpsId);
    
  }  

Future<(double, int)> calculateClosestTerpiez(List<LatLng> terpiezLocations) async {
    // if not connected to redis skip
    //if (!widget.isConn) return;
    

    final storage = FlutterSecureStorage();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final Distance distance = Distance();

    LatLng currentLocation = await getCurrentLoc();

    print('curr loc: $currentLocation');

    double minDistance = double.infinity;
    int minIndex = -1;
    //int minIndex = 2;

    String? user = await storage.read(key: Constants.userNameKey);
    String? pass = await storage.read(key: Constants.passwordKey);
    String? uid = prefs.getString(Constants.userIDKey);

    print('$user, $pass, $uid');

    final RedisConnection conn = RedisConnection();
    final command = await conn.connect(Constants.redisServer, Constants.portNumber);
    await command.send_object(['AUTH', user, pass])
    .then((var response) async {
      if(response == 'OK') {
        await command.send_object(['JSON.GET', user, uid])
        .then((var resp2) {
          print('in calc terps');
          print(resp2);
          //print(resp2.runtimeType);

          final allCaught = jsonDecode(resp2);


          List<LatLng> allLocs = [];

          allCaught.forEach((k, v) {
            print('v: $v');
            for(var loc in v) {
              print('loc: $loc, ${loc.runtimeType}');
              allLocs.add(LatLng(loc['lat'], loc['lon']));
              //print(allLocs);
            }
          });
          print('allLocs: $allLocs');

            for(var i = 0; i < terpiezLocations.length; i++) {
            //print(_terpiezLocations.elementAt(i));
              LatLng loc = terpiezLocations.elementAt(i);

              bool caught = false;

              for(var k in allLocs) {
                if(loc.latitude == k.latitude && loc.longitude == k.longitude) {
                  caught = true;
                  break;
                }
              }

              if(caught == false) {
                //print('loc: $loc');
                double d = distance.as(LengthUnit.Meter, currentLocation, loc);
                if (d < minDistance) {
                  minDistance = d;
                  minIndex = i;
                }
              } 

              
            }
            print('min index and dist: $minIndex, $minDistance');
            print('terp length: ${terpiezLocations.length}');

            // if(this.mounted) {
            //   setState(() {
            //     _closestDistance = minDistance;
            //     _closestIndex = minIndex;
            //   });
            // }
          // for(var caught in allCaught) {
          //   print(caught);
          // }
        });
      }
      await conn.close();
    });
    await conn.close();

    // setState(() {
    //   _closestDistance = minDistance;
    //   _closestIndex = minIndex;
    // });

    // print('closest index in calc: $_closestIndex');
    // print('closest terp in clac: ${_terpiezLocations.elementAt(_closestIndex)}');


    // notifications
    // if(_closestDistance > 10 && _closestDistance <= 20) {
    //   Notifications().terpNoti(_closestDistance);
    // }

    print('inside calc terps dist: $minDistance, index: $minIndex');
    
    return (minDistance, minIndex);
  }

  Future<void> determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    permission = await Geolocator.requestPermission();

    // loc perm denied
    if (permission == LocationPermission.denied) {
      return Future.error("Location Permission Denied!");
    }
    // loc perm denied forever
    if (permission == LocationPermission.deniedForever) {
      return Future.error("Location Permission Permanently Denied!");
    }
  }