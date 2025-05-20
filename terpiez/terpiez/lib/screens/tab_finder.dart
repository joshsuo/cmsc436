import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:terpiez/models/my_state.dart';
//import 'package:provider/provider.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import 'package:redis/redis.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:terpiez/constants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
//import 'package:terpiez/constants.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import 'package:terpiez/notifications.dart';
import 'package:terpiez/calc_close_terp.dart';

import 'package:audioplayers/audioplayers.dart';

class FinderTabView extends StatefulWidget {
  final bool isConn;
  
  const FinderTabView({super.key, required this.listenable, required this.isConn});
  final MyState listenable;

  @override
  _FinderTabViewState createState() => _FinderTabViewState();
}

class _FinderTabViewState extends State<FinderTabView> {

  SharedPreferences? _prefs;

  final storage = FlutterSecureStorage();
  int _counter = 0;
  // hard coded so don't use nullable, update position later in code
  //LatLng _currentLocation = LatLng(39.15198, -76.90709); // home addr
  LatLng _currentLocation = LatLng(38.9894, -76.9365); // gpx file start pos

  //LatLng _currentLocation = LatLng(38.989787, -76.935923);

  List<LatLng> _terpiezLocations = [];
  List<String> _terpiezId = [];
    // Example locations - hard coded
    // LatLng(39.15176, -76.91318), // home
    // LatLng(39.15198, -76.90710), // home
    // LatLng(39.15195, -76.90711), // home
    // LatLng(38.988219500, -76.938858600), // gpx file route
    // LatLng(38.989695000, -76.936563300), // gpx file route
    // LatLng(38.989837900, -76.935816000), // gpx file route
    // LatLng(38.990053900, -76.935644200), // gpx file route
    // LatLng(38.989364300, -76.936336800), // gpx file route
    // LatLng(38.990409800, -76.935458200)  // gpx file route
  //];
  
  double _closestDistance = double.infinity;
  int _closestIndex = 0;
  // final Distance _distance = Distance();

  late StreamSubscription<AccelerometerEvent> _accelerometerSubscription;
  bool catching = false;

  final _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((value) {
      setState(() {
        _prefs = value;
      });
    });

    determinePosition();
    

    // var (terpLocs, terpsId) = await getTerpLocations();
    // setState(() {
    //   _terpiezLocations = terpLocs;
    //   _terpiezId = terpsId;
    // });
    _getLocs();

    // slider movement thing
    // ignore: deprecated_member_use
    _accelerometerSubscription = accelerometerEvents.listen((AccelerometerEvent event) async {
      final double magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      if (magnitude > 10.0 && _closestDistance <= 10 && !catching) {
        print('inside accelerometer');
        catching = true;

        try {
          _catchTerpSaveInJSON();
          // if (mounted) {
          //   await _terpCaughtAlert('test');
          // }
        } catch (e) {
          print('Error during catch: $e');
        } finally {
          await Future.delayed(Duration(seconds: 2)); // Optional cooldown
          catching = false;
        }
      }
    });
    // end of slider movement thing

  }

  void _getLocs() async {
    var (terpLocs, terpsId) = await getTerpLocations();
    setState(() {
      _terpiezLocations = terpLocs;
      _terpiezId = terpsId;
    });
    print('inside getLocs: $_terpiezLocations, $_terpiezId');
  }

  @override
  void dispose() {
    // Cancel the accelerometer event subscription to prevent memory leaks
    _accelerometerSubscription.cancel();
    super.dispose();
  }

  // Future<void> _determinePosition() async {
  //   bool serviceEnabled;
  //   LocationPermission permission;

  //   serviceEnabled = await Geolocator.isLocationServiceEnabled();
  //   if (!serviceEnabled) return;

  //   permission = await Geolocator.checkPermission();
  //   permission = await Geolocator.requestPermission();

  //   // loc perm denied
  //   if (permission == LocationPermission.denied) {
  //     return Future.error("Location Permission Denied!");
  //   }
  //   // loc perm denied forever
  //   if (permission == LocationPermission.deniedForever) {
  //     return Future.error("Location Permission Permanently Denied!");
  //   }
  // }

  // Future<void> _getTerpLocations() async {
  //   // if not connected to redis skip
  //   //if (!widget.isConn) return;

  //   String? user = await storage.read(key: Constants.userNameKey);
  //   String? pass = await storage.read(key: Constants.passwordKey);

  //   final RedisConnection conn = RedisConnection();
  //   final command = await conn.connect(Constants.redisServer, Constants.portNumber);
  //   await command.send_object(['AUTH', user, pass])
  //   .then((var response) async {
  //     if(response == 'OK') {
  //       print("logged in finder");
  //       await command.send_object(['JSON.GET', 'locations'])
  //       .then((var response) async {
  //         print("locations:");
  //         final locs = jsonDecode(response);// as Map<String, dynamic>;
  //         print(locs.length);

  //         List<LatLng> terpLocs = [];
  //         List<String> terpsId = [];
          
  //         for(var element in locs) {
  //           //print('${element["lat"]}, ${element["lon"]}, ${element["id"]}');
  //           terpLocs.add(LatLng(element["lat"], element["lon"]));
  //           terpsId.add(element["id"]);
  //         }
  //         if(this.mounted) {
  //           setState(() {
  //             _terpiezLocations = terpLocs;
  //             _terpiezId = terpsId;
  //           });
  //         }

  //       }).catchError((onError) {
  //         print(onError);
  //       });
  //     } 
  //     await conn.close();
  //   }).catchError((onError) async {
  //     print("wrong user and pass");
  //     await conn.close();
  //   });
    
  // }  

  // void _calculateClosestTerpiez() async {
  //   // if not connected to redis skip
  //   //if (!widget.isConn) return;

  //   double minDistance = double.infinity;
  //   int minIndex = -1;
  //   //int minIndex = 2;

  //   String? user = await storage.read(key: Constants.userNameKey);
  //   String? pass = await storage.read(key: Constants.passwordKey);
  //   String? uid = _prefs?.getString(Constants.userIDKey);

  //   final RedisConnection conn = RedisConnection();
  //   final command = await conn.connect(Constants.redisServer, Constants.portNumber);
  //   await command.send_object(['AUTH', user, pass])
  //   .then((var response) async {
  //     if(response == 'OK') {
  //       await command.send_object(['JSON.GET', user, uid])
  //       .then((var resp2) {
  //         print('in calc terps');
  //         print(resp2);
  //         //print(resp2.runtimeType);

  //         final allCaught = jsonDecode(resp2);


  //         List<LatLng> allLocs = [];

  //         allCaught.forEach((k, v) {
  //           print('v: $v');
  //           for(var loc in v) {
  //             print('loc: $loc, ${loc.runtimeType}');
  //             allLocs.add(LatLng(loc['lat'], loc['lon']));
  //             //print(allLocs);
  //           }
  //         });
  //         print('allLocs: $allLocs');

  //           for(var i = 0; i < _terpiezLocations.length; i++) {
  //           //print(_terpiezLocations.elementAt(i));
  //             LatLng loc = _terpiezLocations.elementAt(i);

  //             bool caught = false;

  //             for(var k in allLocs) {
  //               if(loc.latitude == k.latitude && loc.longitude == k.longitude) {
  //                 caught = true;
  //                 break;
  //               }
  //             }

  //             if(caught == false) {
  //               //print('loc: $loc');
  //               double d = _distance.as(LengthUnit.Meter, _currentLocation, loc);
  //               if (d < minDistance) {
  //                 minDistance = d;
  //                 minIndex = i;
  //               }
  //             } 

              
  //           }
  //           print('min index and dist: $minIndex, $minDistance');
  //           print('terp length: ${_terpiezLocations.length}');

  //           if(this.mounted) {
  //             setState(() {
  //               _closestDistance = minDistance;
  //               _closestIndex = minIndex;
  //             });
  //           }
  //         // for(var caught in allCaught) {
  //         //   print(caught);
  //         // }
  //       });
  //     }
  //     await conn.close();
  //   });
  //   await conn.close();

  //   // setState(() {
  //   //   _closestDistance = minDistance;
  //   //   _closestIndex = minIndex;
  //   // });
  //   print('closest index in calc: $_closestIndex');
  //   print('closest terp in clac: ${_terpiezLocations.elementAt(_closestIndex)}');


  //   // notifications
  //   // if(_closestDistance > 10 && _closestDistance <= 20) {
  //   //   Notifications().terpNoti(_closestDistance);
  //   // }
    
    
  // }

  Future<void> playCatchSound() async {

    try {
      var prefs = await SharedPreferences.getInstance();
      bool sound = prefs.getBool(Constants.soundPrefKey) ?? false;

      if(sound == true) {
        _audioPlayer.setVolume(1);
        await _audioPlayer.play(AssetSource('sounds/catch_sound.mp3'));
      }
    } catch (e) {
      print('Error playing sound: $e');
    }
  }

  void _incrementCounter() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _counter = (prefs.getInt(Constants.terpsCaughtKey) ?? 0) + 1;
      prefs.setInt(Constants.terpsCaughtKey, _counter);
    });
  }

  Future<void> _addTerpInJson(String terps) async {
    //var decoded = jsonDecode(terps);
    try {
      final directory = await getApplicationDocumentsDirectory();
      String path = '${directory.path}/${Constants.infoJsonFileName}';
      
      var file = File(path);

      final contents = await file.readAsString();

      var decoded = jsonDecode(contents);
      var decodedTerps = jsonDecode(terps);

      //show alert on finder tab
      // var content = response.replaceAll("\"", "");
      // var filename = await decodeB64(decodedTerps['image'], content);
      // _terpCaughtAlert(decodedTerps['name'], filename);

      decoded.add(decodedTerps);

      var encoded = jsonEncode(decoded);

      await file.writeAsString(encoded);

      print(file);
    } catch (e) {
      print(e);
    }
  }

  Future<String> decodeB64(String id, String str) async {
    final bytes = base64Decode(str);

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$id.png');
    await file.writeAsBytes(bytes);

    // return getApplicationDocumentsDirectory()
    // .then((value) => File('${value.path}/myfile.txt'));

    return file.path;
  }

  void _catchTerpSaveInJSON() async {
    // if not connected to redis skip
    //if (!widget.isConn) return;

    String? user = await storage.read(key: Constants.userNameKey);
    String? pass = await storage.read(key: Constants.passwordKey);
    String? uid = _prefs?.getString(Constants.userIDKey);
    var closeTerpSID = _terpiezId.elementAt(_closestIndex);
    var latLon = _terpiezLocations.elementAt(_closestIndex);

    //print('length of species caught: ${speciesCaught?.length}');


    final RedisConnection conn = RedisConnection();
    final command = await conn.connect(Constants.redisServer, Constants.portNumber);
    await command.send_object(['AUTH', user, pass])
    .then((var response) async {
      if(response == 'OK') {
        print("in catch terp");
        print(uid);
        
        // add new terp locs to database
        await command.send_object(['JSON.OBJKEYS', user, uid])
        .then((var response) async {
          print('response: $response');
          //List<String>? locsTotal = _prefs?.getStringList(Constants.locsKey) ?? [];
          //List<String>? allInfo = _prefs?.getStringList(Constants.allCaughtKey) ?? [];

          List<dynamic> sids = response; //jsonDecode(response) as List<dynamic>;
          bool done = false;

          List<String>? locsValues = _prefs?.getStringList(Constants.locsKey) ?? [];

          for(int i  = 0; i < sids.length; i++) {
            var sid = sids[i];
            print(sid);

            if(sid == closeTerpSID) {
              // add loc to correct species

              // database
              await command.send_object(['JSON.ARRAPPEND', user, '$uid.$closeTerpSID', 
                '{"lat":${latLon.latitude}, "lon":${latLon.longitude}}']);

              // Shared pref
              var value = jsonDecode(locsValues[i]) as List;
              value.add({"lat":latLon.latitude, "lon":latLon.longitude});
              locsValues[i] = jsonEncode(value);
              _prefs!.setStringList(Constants.locsKey, locsValues);
              
              done = true;
              
              break;
            }
          }

          if(done == false) {
            // add new species and add loc
            await command.send_object(['JSON.SET', user, '$uid.$closeTerpSID', 
              '[{"lat":${latLon.latitude}, "lon":${latLon.longitude}}]']);

            // shared pref
            locsValues.add(jsonEncode([{"lat":latLon.latitude, "lon":latLon.longitude}]));
            _prefs!.setStringList(Constants.locsKey, locsValues);

          }
          // }

          //leave alone

          // get terp species info
          await command.send_object(['JSON.GET', 'terpiez', closeTerpSID])
          .then((var response) async{
            print('terps response: $response');

            var speciesObj = jsonDecode(response);

            print('terps info: ${speciesObj['name']}');
            List<String>? speciesCaughtID = _prefs?.getStringList(Constants.speciesCaughtIDKey) ?? [];
            List<String>? speciesCaughtName = _prefs?.getStringList(Constants.speciesCaughtNameKey) ?? [];
            List<String>? speciesCaughtTN = _prefs?.getStringList(Constants.speciesCaughtTNKey) ?? [];
            List<String>? speciesCaughtIMG = _prefs?.getStringList(Constants.speciesCaughtIMGKey) ?? [];

            // new terp species needed to add / incr
            //var filename = '';
            if(!(speciesCaughtID.contains(closeTerpSID))) {
              _incrementCounter();
              _addTerpInJson(response);

              // shared pref, all terp info as json
              List<String>? allCaughtSpecies = _prefs?.getStringList(Constants.allCaughtKey) ?? [];
              allCaughtSpecies.add(response);
              _prefs?.setStringList(Constants.allCaughtKey, allCaughtSpecies);

              print('adding in pref species caught: $closeTerpSID');
              speciesCaughtID.add(closeTerpSID);
              speciesCaughtName.add(speciesObj['name']);

              _prefs?.setStringList(Constants.speciesCaughtIDKey, speciesCaughtID);
              _prefs?.setStringList(Constants.speciesCaughtNameKey, speciesCaughtName);

              print('specices caught: ${_prefs!.getStringList(Constants.speciesCaughtIDKey)}');
              print('specices name: ${_prefs!.getStringList(Constants.speciesCaughtNameKey)}');
              
              print('thumbnail: ${speciesObj['thumbnail']}');

              // gets the thumbnail to local
              await command.send_object(['JSON.GET', 'images', speciesObj['thumbnail']])
              .then((var response) async {
                print('getting thumbnail: $response');
                var content = response.replaceAll("\"", "");
                var filename = await decodeB64(speciesObj['thumbnail'], content);

                print(filename);

                speciesCaughtTN.add(filename);
                _prefs?.setStringList(Constants.speciesCaughtTNKey, speciesCaughtTN);
              });

              // gets the image to local
              await command.send_object(['JSON.GET', 'images', speciesObj['image']])
              .then((var response) async {
                print('getting iamge: $response');
                var content = response.replaceAll("\"", "");
                var filename = await decodeB64(speciesObj['image'], content);

                print(filename);

                speciesCaughtIMG.add(filename);
                _prefs?.setStringList(Constants.speciesCaughtIMGKey, speciesCaughtIMG);

                //_terpCaughtAlert(speciesObj['name'], filename);
              });
               
            }

            playCatchSound();
            _terpCaughtAlert(speciesObj['name']);
           
            
            print('species thumbnail: ${_prefs!.getStringList(Constants.speciesCaughtTNKey)}');
            print('species image: ${_prefs!.getStringList(Constants.speciesCaughtIMGKey)}');
            print('species locs: ${_prefs!.getStringList(Constants.locsKey)}');
            print('all species: ${_prefs!.getStringList(Constants.allCaughtKey)}');
            
          });
        
          
        });

        await conn.close();
        
      }
    });  
    print('caught terp: ${_terpiezId.elementAt(_closestIndex)}');
    //_calculateClosestTerpiez();

    // double minDistance = 0;
    // int minIndex = 0;

    print('before calc terps: $_terpiezLocations');

    var (minDistance, minIndex) = await calculateClosestTerpiez(_terpiezLocations);
    setState(() {
      _closestDistance = minDistance;
      _closestIndex = minIndex;
      print('after calc close terp $_closestDistance, index: $_closestIndex');
    });
  }

  //Future<void> _terpCaughtAlert(String name, String filename) {
  Future<void> _terpCaughtAlert(String name) async {
    List<String>? speciesCaughtName = _prefs?.getStringList(Constants.speciesCaughtNameKey) ?? [];
    List<String>? speciesCaughtIMG = _prefs?.getStringList(Constants.speciesCaughtIMGKey) ?? [];

    int index = speciesCaughtName.indexWhere((item) => item.contains(name));
    var filename = speciesCaughtIMG[index];

    //print('index: $index, filename: $filename');
    print('terps caught alert name: $name');
    //if (!mounted) return;
    // return OrientationBuilder(
    //   builder: (context, orientation) {
      return showDialog(
        context: context,
        useRootNavigator: true,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            
            content:  Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // orientation == Orientation.landscape
                //   ? Image(image: FileImage(File(filename)), width: 150, height: 125)
                //   : Image(image: FileImage(File(filename))),
                Image(image: FileImage(File(filename)), width: 150, height: 125),
                Text(name, style: TextStyle(fontSize: 20)),
                Text('You have caught a terpiez!'),
              ],
            
              ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK!', style: TextStyle(fontSize: 20),)
              )
            ]
          );
        }
      );
    //   }
    // );
  }

  @override
  Widget build(BuildContext context) {

    return OrientationBuilder(
      
      builder: (context, orientation) {

        var first =
          Padding(
            padding: EdgeInsets.only(top: 20.0),
            child: Text('Terpiez Finder', style: TextStyle(fontSize: 40)),
          );

        var second = FlutterMap(
          options: MapOptions(
            initialCenter: _currentLocation,
            initialZoom: 20,
            onPositionChanged:(camera, hasGesture) async {
              _currentLocation = await getCurrentLoc();
              //_calculateClosestTerpiez();
              //print('before calc terps in build: $_terpiezLocations');
              var (minDistance, minIndex) = await calculateClosestTerpiez(_terpiezLocations);
              setState(() {
                _closestDistance = minDistance;
                _closestIndex = minIndex;
              });
            },
          ),
          children: [
            TileLayer(
              urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
              subdomains: ['a', 'b', 'c'],
            ),
            CurrentLocationLayer(
              style: LocationMarkerStyle(
                marker: DefaultLocationMarker(
                ),
                //markerSize: 
                showHeadingSector: false,
                markerDirection: MarkerDirection.heading,
              ),
              alignPositionOnUpdate: AlignOnUpdate.always,
              alignPositionAnimationDuration: Duration(milliseconds: 50)
            ),
            MarkerLayer(
              markers: [
                if (_terpiezLocations.isNotEmpty && _closestIndex >= 0) 
                Marker(
                      width: 30.0,
                      height: 30.0,
                      point: _terpiezLocations.elementAt(_closestIndex),//snapshot.data!.elementAt(2),
                      
                      child: Icon(Icons.location_on, size: 30, color: Colors.red),
                    )
              ],
            ),
          ],
        );

        var third = Column(
            children: [
              Text(
                'Closest Terpiez: ',
                style: const TextStyle(fontSize: 20),
              ),
              Text (
                (_closestDistance != double.infinity 
                ? '${_closestDistance.toStringAsFixed(2)}m'
                : 'No Terpiez Found!'),
                style: (_closestDistance >= 10) 
                ? TextStyle(fontSize: 20)
                : TextStyle(fontSize: 20, color: Colors.green)
              ),
              // ElevatedButton(
              //   onPressed: (_closestDistance <= 10)
              //     ? () {
              //         _catchTerpSaveInJSON();
              //         _terpCaughtAlert('test', 'test');
              //       }
              //     : null,
              //   child: const Text('Catch Terpiez'),
              // )

            ],
          );
                      
        return
          orientation == Orientation.portrait
          ? 
          Column(
            children: [
              first,
              Expanded(
                child: Padding (
                  padding: EdgeInsets.only(left: 10, right: 10),
                  child: second,
                )
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: third,
              )
            ],
          )
          :
          Column(
            children: [
              first,
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    //child: second
                    child: Padding(
                      padding: EdgeInsets.only(left: 8, right: 8),
                      child: SizedBox(
                        height: 150,
                        child: second
                      ),
                    ),
                  ),
                  Expanded(
                    child: Align(alignment: Alignment.topCenter, child: third),
                  ),
                ],
              )
            ],
          );
      }
    );
  }
}
