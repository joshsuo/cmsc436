import 'package:flutter/material.dart';
import 'package:terpiez/screens/second.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:terpiez/constants.dart';
import 'package:terpiez/models/my_state.dart';
import 'dart:io';

class ListTabView extends StatefulWidget {
  const ListTabView({super.key, required this.listenable});
  final MyState listenable;

  @override
  _ListTabViewState createState() => _ListTabViewState();
}

class _ListTabViewState extends State<ListTabView> {
  MyState myState = MyState();
  SharedPreferences? _prefs;
  List<String>? speciesIDItems;
  List<String>? speciesNameItems;
  List<String>? speciesTNItems;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((value) {
      setState(() {
        _prefs = value;
        speciesIDItems = _prefs?.getStringList(Constants.speciesCaughtIDKey);
        speciesNameItems = _prefs?.getStringList(Constants.speciesCaughtNameKey);
        speciesTNItems = _prefs?.getStringList(Constants.speciesCaughtTNKey);
      });
    });
  }


  @override
  Widget build(BuildContext context) {
    return (
      (speciesIDItems == null || speciesNameItems == null || speciesTNItems == null) 
      ? Center(child: Text(''))
      : LayoutBuilder(
        builder: (context, constraints) {
          return ListView.builder(
            itemCount: speciesIDItems?.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(speciesNameItems![index], style: TextStyle(fontSize: 20),),
                leading: Hero(
                  tag: 'hero-tag-${index.toString()}', 
                  child: Image(
                    image: FileImage(File(speciesTNItems![index]))
                    //speciesTNItems[index], size: 55)),
                  )),
                onTap: () => 
                  Navigator.push(context,
                    MaterialPageRoute<void>(
                      builder: (context) => 
                      SecondScreen(index: index)
                      //Container()
                      
                    )
                  ),
              );
            }
          );
        }
      )
    );
  }
}