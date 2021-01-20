import 'dart:convert';
import 'dart:ui';

import 'package:asked/Login.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Question.dart';
import 'globals.dart' as globals;
import 'package:http/http.dart' as http;

class Profile extends StatefulWidget {
  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  RangeValues _currentRangeValues = RangeValues(20, 40);
  bool woman = false;
  bool man = false;
  String question = "";
  String firstName = "";
  String picture = "";
  String age = "";
  String gender;
  bool questionChanged = false;
  LocationData _locationData;

  var questionField = TextEditingController();
  var ageField = TextEditingController();

  _ProfileState() {
    _determinePosition();
    init();
  }

  _determinePosition() async {
    Location location = new Location();

    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }
    _locationData = await location.getLocation();
  }

  init() async {
    final responseMe = await http.get("https://api.asked.live/me",
        headers: <String, String>{
          "Authorization": "Bearer " + globals.access_token
        });
    globals.userId = jsonDecode(responseMe.body)[0]["id"];
    firstName = jsonDecode(responseMe.body)[0]["first_name"].trimRight();
    picture = jsonDecode(responseMe.body)[0]["picture"];
    age = jsonDecode(responseMe.body)[0]["age"].toString();
    if(age == "null")
      age = "";
    ageField.text = age;
    gender = jsonDecode(responseMe.body)[0]["gender"];
    double from = 18.0;
    double to = 100;
    if(jsonDecode(responseMe.body)[0]["age_from"] != null)
      from = jsonDecode(responseMe.body)[0]["age_from"].toDouble();
    if(jsonDecode(responseMe.body)[0]["age_to"] != null)
      to = jsonDecode(responseMe.body)[0]["age_to"].toDouble();
    _currentRangeValues = RangeValues(from, to);
    List interestedFor = jsonDecode(responseMe.body)[0]["interested_for"];
    if (interestedFor != null && interestedFor.contains("m")) man = true;
    if (interestedFor != null && interestedFor.contains("f")) woman = true;

    final responseQuestion = await http
        .get("https://api.asked.live/user_question", headers: <String, String>{
      "Authorization": "Bearer " + globals.access_token
    });
    if(jsonDecode(responseQuestion.body).length > 0)
      question = jsonDecode(responseQuestion.body)[0]["question"];
    questionField.text = question;
    setState(() {});
  }

  deleteAccount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final responseDeleteUser =
    await http.delete("https://api.asked.live/me?id=eq." + globals.userId,
        headers: <String, String>{
          "Authorization": "Bearer " + globals.access_token,
          "Content-Type": "application/json"
        }
        );
    globals.refresh_token = "";
    globals.isLoggedIn = false;
    globals.userId = "";
    globals.access_token = "";
    prefs.remove("refresh_token");
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => Login()),
        ModalRoute.withName("/Login"));
  }
  save() async {
    String interested = "{";
    List<String> list = [];
    if (man) list.add("m");
    if (woman) list.add("f");
    interested = "{" + list.join(",") + "}";
    String point = null;
    if(_locationData != null){
      point = "POINT(" +
          _locationData.latitude.toString() +
          " " +
          _locationData.longitude.toString() +
          ")";
    }
    final responseCreateUser =
        await http.patch("https://api.asked.live/me?id=eq." + globals.userId,
            headers: <String, String>{
              "Authorization": "Bearer " + globals.access_token,
              "Content-Type": "application/json"
            },
            body: jsonEncode(<String, String>{
              "interested_for": interested,
              "age": age.toString(),
              "gender": gender,
              "age_from": _currentRangeValues.start.toInt().toString(),
              "age_to": _currentRangeValues.end.toInt().toString(),
              "geog": point
            }));
    if (questionChanged) {
      final responseCreateQuestion =
          await http.post("https://api.asked.live/user_question",
              headers: <String, String>{
                "Authorization": "Bearer " + globals.access_token,
                "Content-Type": "application/json"
              },
              body: jsonEncode(<String, String>{"question": question}));
    }
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => Question()),
        ModalRoute.withName("/Question"));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("ASKED", textAlign: TextAlign.center),
        ),
        body: (SingleChildScrollView(
          padding: new EdgeInsets.all(20.0),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Align(
                  alignment: Alignment.topRight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      primary: Colors.red,
                    ),
                    onPressed: () {
                      //Navigator.pop(context);
                      deleteAccount();
                    },
                    child: Text('Delete account'),
                  ),
                ),
                Row(children: <Widget>[
                  Image.network(
                    picture,
                    width: 50,
                  ),
                  Text('Welcome ' + firstName.trimRight(),
                      style: TextStyle(fontSize: 25),
                      textAlign: TextAlign.left),
                ]),
                //Row(children: <Widget>[
                  ListTile(
                    title: const Text('Man'),
                    leading: Radio(
                      value: "m",
                      groupValue: gender,
                      onChanged: (String value) {
                        setState(() {
                          gender = value;
                        });
                      },
                    ),
                  ),
                  ListTile(
                      title: const Text('Woman'),
                      leading: Radio(
                        value: "f",
                        groupValue: gender,
                        onChanged: (String value) {
                          setState(() {
                            gender = value;
                          });
                        },
                      )
                  ),
                //]),
                TextField(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Your age",
                  ),
                  keyboardType: TextInputType.number,
                  controller: ageField,
                  onChanged: (value) {
                    setState(() {
                      age = value;
                    });
                  },
                ),
                Text("I'm searching for : ",
                    style: TextStyle(fontSize: 15), textAlign: TextAlign.left),
                CheckboxListTile(
                  title: Text("A Man"),
                  value: man,
                  onChanged: (checked) {
                    setState(() {
                      man = checked;
                    });
                  },
                  controlAffinity:
                      ListTileControlAffinity.leading, //  <-- leading Checkbox
                ),
                CheckboxListTile(
                  title: Text("A Woman"),
                  value: woman,
                  onChanged: (checked) {
                    setState(() {
                      woman = checked;
                    });
                  },
                  controlAffinity:
                      ListTileControlAffinity.leading, //  <-- leading Checkbox
                ),
                Text("Between : ",
                    style: TextStyle(fontSize: 15), textAlign: TextAlign.left),
                RangeSlider(
                    values: _currentRangeValues,
                    min: 18,
                    max: 100,
                    divisions: 82,
                    labels: RangeLabels(
                      _currentRangeValues.start.round().toString(),
                      _currentRangeValues.end.round().toString(),
                    ),
                    onChanged: (values) {
                      print("START: ${values.start}, End: ${values.end}");
                      setState(() {
                        _currentRangeValues = values;
                      });
                    }),
                Text("Who can answer to : ",
                    style: TextStyle(fontSize: 15), textAlign: TextAlign.left),
                TextField(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  controller: questionField,
                  onChanged: (value) {
                    questionChanged = true;
                    setState(() {
                      question = value;
                    });
                  },
                ),
                ElevatedButton(
                  onPressed: () {
                    //Navigator.pop(context);
                    save();
                  },
                  child: Text('Save'),
                ),
              ]),
        )));
  }
}
