import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:flutter_facebook_login/flutter_facebook_login.dart';

import 'Profile.dart';
import 'package:http/http.dart' as http;
import 'Question.dart';
import 'globals.dart' as globals;

class Login extends StatelessWidget {
  Timer timer;
  BuildContext context;
  SharedPreferences prefs;

  Future<void> refreshToken() async {
    prefs = await SharedPreferences.getInstance();

    if(globals.isLoggedIn || (prefs.getString("refresh_token") ?? "") != "" ) {
      globals.refresh_token = prefs.getString("refresh_token");
      final responseRefreshToken = await http.post(
          "https://app.please-open.it/auth/realms/dfd9de82-07a2-4ca1-875e-07db53d185f6/protocol/openid-connect/token",
          headers: <String, String>{
            "Content-Type": "application/x-www-form-urlencoded"
          },
          body: {
            "client_id": "mobile",
            "grant_type": "refresh_token",
            "refresh_token": globals.refresh_token
          }
      );
      if(responseRefreshToken.statusCode == 200) {
        globals.access_token =
        jsonDecode(responseRefreshToken.body)["access_token"];
        globals.refresh_token =
        jsonDecode(responseRefreshToken.body)["refresh_token"];
        prefs.setString('refresh_token', globals.refresh_token);
        globals.isLoggedIn = true;
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => Question()),
            ModalRoute.withName("/Question"));
      }else{
        globals.access_token = "";
        globals.refresh_token = "";
        globals.isLoggedIn = false;
        prefs.remove("refresh_token");
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => Login()),
            ModalRoute.withName("/Login"));
      }
    }
  }
  @override
  Widget build(BuildContext context) {

    this.context = context;
    refreshToken();

    timer = Timer.periodic(Duration(minutes: 3), (Timer t) => refreshToken());
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Image(image: AssetImage('images/logo.png')),
            Text('ASKED', style: TextStyle(fontSize: 80)),
            Text('Can we meet with one question ?',
                style: TextStyle(fontSize: 20)),
            LoginButton()
          ],
        ),
      ),
    );
  }

}
class LoginButton extends StatefulWidget {
  @override
  _LoginButton createState() => _LoginButton();
}

class _LoginButton extends State<LoginButton> {
  String _message = 'Log in/out by pressing the buttons below.';
  SharedPreferences prefs;
  Future<void> _login() async {
    prefs = await SharedPreferences.getInstance();
    try {
      // by default the login method has the next permissions ['email','public_profile']
      AccessToken accessToken = await FacebookAuth.instance.login(permissions: ['email']);
      String facebookToken = accessToken.token;
      final facebookResponse = await http.get('https://graph.facebook.com/v2.12/me?fields=first_name,picture.width(200).height(200)&access_token=${facebookToken}');
      // get the user data
      final userData = await FacebookAuth.instance.getUserData();
      print(userData);
      // token exchange
      final responseTokenExchange = await http.post(
          "https://app.please-open.it/auth/realms/dfd9de82-07a2-4ca1-875e-07db53d185f6/protocol/openid-connect/token",
          headers: <String, String>{
            "Content-Type": "application/x-www-form-urlencoded"
          },
          body: {
            "client_id": "mobile",
            "grant_type": "urn:ietf:params:oauth:grant-type:token-exchange",
            "subject_issuer": "facebook",
            "subject_token_type": "urn:ietf:params:oauth:token-type:access_token",
            "audiance": "mobile",
            "subject_token": facebookToken
          }
      );

      globals.access_token = jsonDecode(responseTokenExchange.body)["access_token"];
      globals.refresh_token = jsonDecode(responseTokenExchange.body)["refresh_token"];
      prefs.setString('refresh_token', globals.refresh_token);
      globals.isLoggedIn = true;

      // new we get the user, if the result is empty it is a new user
      final responseMe = await http.get(
          "https://api.asked.live/me",
          headers: <String, String>{
            "Authorization": "Bearer "+globals.access_token
          }
      );

      final List me = jsonDecode(responseMe.body);
      if(me.length == 0){
        // first of all, create the user
        final responseCreateUser = await http.post(
            "https://api.asked.live/me",
            headers: <String, String>{
              "Authorization": "Bearer "+globals.access_token,
              "Content-Type": "application/json"
            },
            body: jsonEncode(<String, String> {
              //"gender": jsonDecode(facebookResponse.body)["gender"][0],
              "first_name": jsonDecode(facebookResponse.body)["first_name"],
              //"birth": jsonDecode(facebookResponse.body)["birthday"],
              "picture": jsonDecode(facebookResponse.body)["picture"]["data"]["url"]
            })
        );
        // if there is no profile, redirect to the profile screen

        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => Profile()),
            ModalRoute.withName("/Profile"));
      }else{
        // or go directly to questions
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => Question()),
            ModalRoute.withName("/Question"));
      }
    } on FacebookAuthException catch (e) {
      switch (e.errorCode) {
        case FacebookAuthErrorCode.OPERATION_IN_PROGRESS:
          print("You have a previous login operation in progress");
          break;
        case FacebookAuthErrorCode.CANCELLED:
          print("login cancelled");
          break;
        case FacebookAuthErrorCode.FAILED:
          print("login failed");
          break;
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return RaisedButton(
                child: Text('Login with Facebook'),
                onPressed: _login,
                color: Color(0xFF42A5F5));
  }
}