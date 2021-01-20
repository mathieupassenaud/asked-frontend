import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'Conversations.dart';
import 'Profile.dart';
import 'globals.dart' as globals;
import 'package:http/http.dart' as http;

class Question extends StatefulWidget {
  @override
  _QuestionState createState() => _QuestionState();
}

class _QuestionState extends State<Question> {
  String idQuestion = "";
  String firstName = "";
  String picture = "";
  String age = "";
  String question = "";
  String distance = "";
  String answerText = "";
  Timer timerResponses;
  Timer timerAccepted;
  var responseField = TextEditingController();

  _QuestionState() {
    init();
  }

  init() async {
    timerResponses = Timer.periodic(
        Duration(seconds: 15), (Timer t) => checkForNewResponses());
    timerAccepted = Timer.periodic(
        Duration(seconds: 15), (Timer t) => checkForNewAcceptedAnswers());
    responseField.text = "";
    globals.userId;
    final responseRandomQuestion = await http.get(
        "https://api.asked.live/random_question",
        headers: <String, String>{
          "Authorization": "Bearer " + globals.access_token,
          "Content-Type": "application/json"
        });
    final List questions = jsonDecode(responseRandomQuestion.body);
    if (questions.length == 0) {
      _showNoProfileDialog();
      idQuestion = "";
      firstName = "";
      picture = "";
      age = "";
      question = "";
      distance = "";
    } else {
      idQuestion =
          jsonDecode(responseRandomQuestion.body)[0]["question_id"].toString();
      firstName =
          jsonDecode(responseRandomQuestion.body)[0]["first_name"].trimRight();
      picture = jsonDecode(responseRandomQuestion.body)[0]["picture"];
      age = jsonDecode(responseRandomQuestion.body)[0]["age"].toString();
      question = jsonDecode(responseRandomQuestion.body)[0]["question"];
      if (jsonDecode(responseRandomQuestion.body)[0]["distance"] == null) {
        distance = "unknown";
      } else {
        distance = jsonDecode(responseRandomQuestion.body)[0]["distance"]
            .round()
            .toString();
      }
    }
    setState(() {});
  }

  checkForNewAcceptedAnswers() async {
    final responseMatch = await http.get(
        "https://api.asked.live/accepted_responses",
        headers: <String, String>{
          "Authorization": "Bearer " + globals.access_token,
          "Content-Type": "application/json"
        });
    final List match = jsonDecode(responseMatch.body);
    if (match.length > 0) {
      String distance;
      if (jsonDecode(responseMatch.body)[0]["distance"] == null) {
        distance = "unknown";
      } else {
        distance = jsonDecode(responseMatch.body)[0]["distance"]
            .round()
            .toString();
      }
      _showAcceptedDialog(
          jsonDecode(responseMatch.body)[0]["first_name"].trimRight(),
          jsonDecode(responseMatch.body)[0]["picture"].trimRight(),
          jsonDecode(responseMatch.body)[0]["age"].toString(),
          distance,
          jsonDecode(responseMatch.body)[0]["question"],
          jsonDecode(responseMatch.body)[0]["response"]);

      final responseViewed = await http.patch(
          "https://api.asked.live/accept_response?id=eq." +
              jsonDecode(responseMatch.body)[0]["id"].toString(),
          headers: <String, String>{
            "Authorization": "Bearer " + globals.access_token,
            "Content-Type": "application/json"
          },
          body: jsonEncode(<String, String>{"viewed": "true"}));
    }
  }

  checkForNewResponses() async {
    final responseMatch = await http
        .get("https://api.asked.live/new_responses", headers: <String, String>{
      "Authorization": "Bearer " + globals.access_token,
      "Content-Type": "application/json"
    });
    final List match = jsonDecode(responseMatch.body);
    String distance;
    if (match.length > 0) {
      if (jsonDecode(responseMatch.body)[0]["distance"] == null) {
        distance = "unknown";
      } else {
        distance = jsonDecode(responseMatch.body)[0]["distance"]
            .round()
            .toString();
      }
      _showMatchDialog(
          jsonDecode(responseMatch.body)[0]["id"].toString(),
          jsonDecode(responseMatch.body)[0]["first_name"].trimRight(),
          jsonDecode(responseMatch.body)[0]["age"].toString(),
          distance,
          jsonDecode(responseMatch.body)[0]["picture"],
          jsonDecode(responseMatch.body)[0]["question"],
          jsonDecode(responseMatch.body)[0]["response"]);
    }
  }

  accept(String id) async {
    final responseAccept = await http.patch(
        "https://api.asked.live/accept_response?id=eq." + id,
        headers: <String, String>{
          "Authorization": "Bearer " + globals.access_token,
          "Content-Type": "application/json"
        },
        body:
            jsonEncode(<String, String>{"accepted": "true", "viewed": "false"}));
    init();
  }

  refuse(String id) async {
    final responseRefuse = await http.patch(
        "https://api.asked.live/accept_response?id=eq." + id,
        headers: <String, String>{
          "Authorization": "Bearer " + globals.access_token,
          "Content-Type": "application/json"
        },
        body:
            jsonEncode(<String, String>{"accepted": "false", "view": "true"}));
    init();
  }

  _showNoProfileDialog() {
    showDialog(
        context: context,
        builder: (_) => new AlertDialog(
              title: new Text("Sorry !"),
              content: new Text(
                  "There is no profile matching to your request. Sorry"),
              actions: <Widget>[
                FlatButton(
                  child: Text('Preferences'),
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => Profile()),
                        ModalRoute.withName("/Profile"));
                  },
                )
              ],
            ));
  }

  _showAcceptedDialog(
      String firstName, String picture, String age, String distance, String question, String response) {
    timerAccepted.cancel();
    if (distance == null) distance = "unknown";

    showDialog(
        context: context,
        builder: (_) => new AlertDialog(
          content: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      flex: 2, // 20%
                      child: Image.network(picture),
                    ),
                    Expanded(
                        flex: 8, // 60%
                        child: Text(firstName +
                            ' ' +
                            age +
                            ' years - ' +
                            distance +
                            " km"))
                  ]),
                  Container(
                      margin: const EdgeInsets.all(3.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.black12,
                        border: Border.all(
                          color: Colors.black12,
                          width: 1,
                        ),
                      ),
                      child: Text(question,
                          style: TextStyle(
                              fontSize: 15, fontStyle: FontStyle.italic),
                          textAlign: TextAlign.right)),
                  Container(
                      margin: const EdgeInsets.all(3.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.green,
                        border: Border.all(
                          color: Colors.green,
                          width: 1,
                        ),
                      ),
                      child: Text(response,
                          style: TextStyle(
                              fontSize: 30, fontStyle: FontStyle.italic),
                          textAlign: TextAlign.right)),
                ],
              )),
          actions: <Widget>[
            Row(children: [
              ElevatedButton(
                child: Text("Let's chat"),
                style: ElevatedButton.styleFrom(
                  primary: Colors.green,
                ),
                onPressed: () {
                  //accept(id);
                  Navigator.of(context).pop();
                },
              )
            ])
          ],
        ));
  }

  _showMatchDialog(String id, String firstName, String age, String distance,
      String picture, String question, String response) {
    timerResponses.cancel();
      showDialog(
          context: context,
          builder: (_) => new AlertDialog(
            content: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        flex: 2, // 20%
                        child: Image.network(picture),
                      ),
                      Expanded(
                          flex: 8, // 60%
                          child: Text(firstName +
                              ' ' +
                              age +
                              ' years - ' +
                              distance +
                              " km"))
                    ]),
                    Container(
                        margin: const EdgeInsets.all(3.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.black12,
                          border: Border.all(
                            color: Colors.black12,
                            width: 1,
                          ),
                        ),
                        child: Text(response,
                            style: TextStyle(
                                fontSize: 30, fontStyle: FontStyle.italic),
                            textAlign: TextAlign.right)),
                  ],
                )),
            actions: <Widget>[
              Row(children: [
                ElevatedButton(
                  onPressed: () {
                    refuse(id);
                    Navigator.pop(context);
                  },
                  child: Text('NEXT'),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.red,
                  ),
                ),
                ElevatedButton(
                  child: Text('LOVE IT !'),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.green,
                  ),
                  onPressed: () {
                    accept(id);
                    Navigator.of(context).pop();
                  },
                )
              ])
            ],
          ));
    }

  answer() async {
    final responseCreateQuestion = await http.post(
        "https://api.asked.live/user_response",
        headers: <String, String>{
          "Authorization": "Bearer " + globals.access_token,
          "Content-Type": "application/json"
        },
        body: jsonEncode(<String, String>{
          "response": answerText,
          "id_question": idQuestion
        }));
    init();
  }

  noAnswer() async {
    final responseCreateQuestion =
        await http.post("https://api.asked.live/user_response",
            headers: <String, String>{
              "Authorization": "Bearer " + globals.access_token,
              "Content-Type": "application/json"
            },
            body: jsonEncode(<String, String>{"id_question": idQuestion}));
    init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomPadding: true,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: Text("ASKED", textAlign: TextAlign.center),
        ),
        body: SingleChildScrollView(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
              Row(children: [
                Expanded(
                  flex: 5, // 20%
                  child: ElevatedButton(
                    onPressed: () {
                      //Navigator.pop(context);
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) => Profile()));
                    },
                    child: Icon(Icons.settings),
                    style: ElevatedButton.styleFrom(
                      primary: Colors.grey,
                    ),
                  ),
                ),
                Expanded(
                    flex: 5, // 60%
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => Conversations()));
                      },
                      child: Icon(Icons.email_sharp),
                      style: ElevatedButton.styleFrom(
                        primary: Colors.blueGrey,
                      ),
                    ))
              ]),
              Column(children: <Widget>[
                Row(children: [
                  Expanded(
                    flex: 2, // 20%
                    child: Image.network(picture),
                  ),
                  Expanded(
                      flex: 8, // 60%
                      child: Text(
                          firstName + ' ' + age + ' years - ' + distance + " km"))
                ]),
                Container(
                    margin: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.black12,
                      border: Border.all(
                        color: Colors.black12,
                        width: 1,
                      ),
                    ),
                    child: Text(question,
                        style: TextStyle(
                            fontSize: 25, fontStyle: FontStyle.italic),
                        textAlign: TextAlign.left)),
                TextField(
                  controller: responseField,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Your answer",
                  ),
                  onChanged: (value) {
                    setState(() {
                      answerText = value;
                    });
                  },
                ),
                Row(children: [
                  Expanded(
                      flex: 5,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ElevatedButton(
                          onPressed: () {
                            //Navigator.pop(context);
                            noAnswer();
                          },
                          child: Text('Next'),
                          style: ElevatedButton.styleFrom(
                            primary: Colors.red,
                          ),
                        ),
                      )),
                  Expanded(
                      flex: 5, // 60%
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ElevatedButton(
                          onPressed: () {
                            //Navigator.pop(context);
                            answer();
                          },
                          child: Text('SEND !'),
                          style: ElevatedButton.styleFrom(
                            primary: Colors.green,
                          ),
                        ),
                      ))
                ])
              ]),
            ])));
  }
}
