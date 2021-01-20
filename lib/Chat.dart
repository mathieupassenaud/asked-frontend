import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'globals.dart' as globals;
import 'package:http/http.dart' as http;

class Chat extends StatefulWidget {
  int chatId;
  Chat(int chatId) {
    this.chatId = chatId;
  }
  @override
  _ChatState createState() => _ChatState(chatId);
}

class _ChatState extends State<Chat> {
  Timer checkMessages;
  List messages;
  List chat;
  int chatId;
  var responseField = TextEditingController();
  _ChatState(int chatId) {
    this.chatId = chatId;
    checkMessages = Timer.periodic(
        Duration(seconds: 15), (Timer t) => init());
    init();
  }

  ScrollController _controller;
  init() async {
    final responseConversation = await http.get(
        "https://api.asked.live/conversation?id_response=eq." +
            chatId.toString(),
        headers: <String, String>{
          "Authorization": "Bearer " + globals.access_token,
          "Content-Type": "application/json"
        });
    final responseChat = await http.get(
        "https://api.asked.live/chats?id=eq." +
            chatId.toString(),
        headers: <String, String>{
          "Authorization": "Bearer " + globals.access_token,
          "Content-Type": "application/json"
        });
    chat = jsonDecode(responseChat.body);
    messages = jsonDecode(responseConversation.body);
    setRead();
    setState(() {});
    _controller = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller
          .animateTo(_controller.position.maxScrollExtent,
          duration: Duration(seconds: 1), curve: Curves.ease)
          .then((value) async {}
      );
    });
  }

  setRead() async {
    final responseRead = await http.post(
        "https://api.asked.live/rpc/set_read",
        headers: <String, String>{
          "Authorization": "Bearer " + globals.access_token,
          "Content-Type": "application/json"
        },
        body: jsonEncode(<String, String>{
          "id_chat": chatId.toString()
        }));
    print("ok");
  }

  sendMessage() async {
    final responsePostMessage = await http.post(
        "https://api.asked.live/rpc/post_message",
        headers: <String, String>{
          "Authorization": "Bearer " + globals.access_token,
          "Content-Type": "application/json"
        },
        body: jsonEncode(<String, String>{
          "message": responseField.value.text,
          "id_response": chatId.toString()
        }));
    responseField.text = "";
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
        body:
        SingleChildScrollView(
          controller: _controller,
          child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                    Row(children: <Widget>[
                      Image.network(
                        chat[0]['picture'],
                        width: 50,
                      ),
                      Text(chat[0]['first_name'].trimRight() + ' - ' + chat[0]['age'].toString() + ' years')
                    ]),
                Row(children: <Widget>[
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
                      child: Text(chat[0]['question'],
                          style: TextStyle(
                              fontSize: 15, fontStyle: FontStyle.italic),
                          textAlign: TextAlign.left)),
                ]),
                Row(children: <Widget>[
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
                      child: Text(chat[0]['response'],
                          style: TextStyle(
                              fontSize: 15, fontStyle: FontStyle.italic),
                          textAlign: TextAlign.left)),
                ]),
                for (var message in messages)
                  Row(children: <Widget>[
                    Column(children: <Widget>[
                      Text(message['first_name'],
                          style: TextStyle(fontSize: 9)),
                      Text(message['message'],
                          style: TextStyle(
                              fontWeight: message['unread']
                                  ? FontWeight.bold
                                  : FontWeight.normal))
                    ])
                  ]),
                TextField(
                  controller: responseField,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
                FlatButton(
                  onPressed: () {
                    //Navigator.pop(context);
                    sendMessage();
                  },
                  child: Text('Send', style: TextStyle(fontSize: 12, color: Colors.blue ), ),
                ),
              ]),
        ));
  }
}
