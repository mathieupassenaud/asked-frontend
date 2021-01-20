import 'dart:convert';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'Chat.dart';
import 'Profile.dart';
import 'globals.dart' as globals;
import 'package:http/http.dart' as http;

class Conversations extends StatefulWidget {
  @override
  _ConversationsState createState() => _ConversationsState();
}

class _ConversationsState extends State<Conversations> {
  List chats = [];
  _ConversationsState() {
    init();
  }

  init() async {
    final responseChats = await http
        .get("https://api.asked.live/chats", headers: <String, String>{
      "Authorization": "Bearer " + globals.access_token,
      "Content-Type": "application/json"
    });
    chats = jsonDecode(responseChats.body);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomPadding: true,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: Text("ASKED", textAlign: TextAlign.center),
        ),
        body: Row(
            children:<Widget>[ SingleChildScrollView(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                for (var chat in chats)
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        primary: chat['unread'] ? Colors.blue : Colors.black26,
                      ),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => Chat(chat['id'])));
                      },
                      child: Row(children: <Widget>[
                        Image.network(
                          chat['picture'],
                          width: 50,
                        ),
                        Text(chat['first_name'],
                            style: TextStyle(
                                fontWeight: chat['unread']
                                    ? FontWeight.bold
                                    : FontWeight.normal))
                      ]))
              ]),
        )]));
  }
}
