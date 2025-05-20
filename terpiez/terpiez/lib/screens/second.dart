import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:terpiez/models/shaders.dart';
//import 'package:flutter_shaders/flutter_shaders.dart';
//import 'dart:ui' as ui;
//import 'package:terpiez/models/my_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:terpiez/constants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:redis/redis.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';



class SecondScreen extends StatefulWidget {
  var index;
  SecondScreen({Key? myKey, this.index}) : super(key: myKey);


  @override
  _SecondScreenState createState() => _SecondScreenState();
}

class _SecondScreenState extends State<SecondScreen> {

  SharedPreferences? _prefs;
  final storage = FlutterSecureStorage();

  // String title = 'hello';
  // IconData icon = Icons.abc;
  //int index = 0;

  // terpiez info
  String? name;
  String? description;
  Map<String, dynamic>? stats;
  String? imageID;
  String? filename;
  List<LatLng>? locs = [];
  List<String>? speciesIMGItems;
  var caughtObj;
  


  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((value) {
      setState(() {
        _prefs = value;
        speciesIMGItems = _prefs?.getStringList(Constants.speciesCaughtIMGKey);

        String locJson = _prefs!.getStringList(Constants.locsKey)![widget.index];
        var locsObj = jsonDecode(locJson);

        print(locsObj);

        for(var loc in locsObj) {
          locs!.add(LatLng(loc['lat'], loc['lon']));
          
        }
        print('locs: $locs, ${locs.runtimeType}');
        
        String caught = _prefs!.getStringList(Constants.allCaughtKey)![widget.index];
        caughtObj = jsonDecode(caught);


        print(caughtObj['name']);
        print(caughtObj['stats']);
        print(caughtObj['description']);
        print(locs);
        print('all caught: $caught');
        print('index: ${widget.index}');

        stats = caughtObj['stats'];

      });
    });
    
  }

  LatLng _calcAverage() {

    print('in calc avg: $locs, ${locs!.length}');

    double lat = 0;
    double lon = 0;
    int len = locs!.length;


    locs?.forEach((entry) {
      lat += entry.latitude;
      lon += entry.longitude;
    });

    print('before - lat: $lat, lon: $lon');

    lat = lat/len;
    lon = lon/len;

    print('after div - lat: $lat, lon: $lon');

    return(LatLng(lat, lon));
  }

 @override
  Widget build(BuildContext context) {
    print('locs before return: $locs');
    return (
    (widget.index == null || caughtObj == null || locs == null || stats == null) 
    ? Center(child: Text(''))
    : 
    OrientationBuilder(
      builder: (context, orientation) {

        var specName = 
          Text(caughtObj['name'], style: TextStyle(fontSize: 35));
          // landscape:
          // Text(caughtObj['name'], style: TextStyle(fontSize: 38, height: .5))

        var specStats = 
          Expanded (
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: stats!.entries.map((entry) {
                return Text(
                  '${entry.key}: ${entry.value}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600));
              }).toList(),
            )
          );
        
        var mapOptions = 
          MapOptions(
            initialCenter: _calcAverage(),
            initialZoom: 15
          );
        
        var map = 
          TileLayer(
            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: ['a', 'b', 'c'],
          );

        var marker = 
          MarkerLayer(
            markers: locs!.map((entry) {
              return Marker(
                point: entry, 
                child: Icon(Icons.location_on, size: 30, color: Colors.red),
              );
            }).toList(),
          );
      
      return  
      Scaffold(
        appBar: AppBar(
          title: Text(caughtObj['name']),
        ),
        body: ShaderWidget (
          child: LayoutBuilder(
            builder: (context, constraints) {
              return 
                orientation == Orientation.portrait
              ?
              Column(
                children: [
                  Container(
                    alignment: Alignment.center,
                    child: Hero(
                      tag: 'hero-tag-${widget.index.toString()}', 
                      child: 
                      Center(
                      heightFactor: 1.1,
                      child: Image(
                        image: FileImage(File(speciesIMGItems![widget.index])),
                        width: 650,
                        height: 300,
                      ),
                      
                      )
                    )
                  ),
                  
                  specName,
                  
                  Row(
                    children: [
                    Padding (
                      padding: EdgeInsets.only(left: 20, bottom: 15),
                      child: Container(
                        constraints: BoxConstraints(
                          maxHeight: 180,
                          maxWidth: 250,
                        ),
                          child: FlutterMap(
                            options: mapOptions,
                            children: [map, marker]
                          )
                      )
                      ),
                      specStats,
                    ],
                  ),
                  Center(
                    child: Padding( 
                      padding: EdgeInsets.only(left: 15, right: 15),
                      child: Text(
                        caughtObj['description'],
                        style: TextStyle(fontSize: 15)
                      )
                    )
                  )
                ],
              )
              : 
              Row (
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 0,
                    child: Column(
                      children: [ 
                        Hero(
                          tag: 'hero-tag-${widget.index.toString()}', 
                          child: 
                          Center(
                            heightFactor: 1.1,
                            widthFactor: 0.8,
                            child: Image(
                              image: FileImage(File(speciesIMGItems![widget.index])),
                              width: 500,
                              height: 250,
                            ),
                          )
                        ),
                      specName,
                      ]
                    ),
                  ),

                  Expanded (
                    flex: 0,
                    child: Column(
                      children: [
                      Padding (
                        padding: EdgeInsets.only(top: 13, right: 15),
                        child: Container(
                          constraints: BoxConstraints(
                            maxHeight: 210,
                            maxWidth: 150,
                          ),
                            child: FlutterMap(
                              options: mapOptions,
                              children: [map, marker,]
                            )
                        )
                      ),
                      specStats
                      ],
                    ),
                  ),

                  Expanded(
                    flex: 2,
                    child: Text(
                      overflow: TextOverflow.clip,
                      softWrap: true,
                      caughtObj['description'],
                      style: TextStyle(fontSize: 15)
                    )              
                  )
                ],
              );
            }
          )
        )
      );
      }
    )
    );

  }
}


