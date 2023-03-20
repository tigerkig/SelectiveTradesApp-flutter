import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:selective_chat/models/app_user.dart';
import 'package:selective_chat/utils/constants.dart';
import 'package:selective_chat/utils/methods.dart';
import 'package:selective_chat/utils/push_notification_service.dart';
import 'package:selective_chat/utils/widgets.dart';
import 'package:selective_chat/views/sign_in.dart';

class ResetPasswordScreen extends StatefulWidget {

  String email;

  ResetPasswordScreen({this.email});

  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {

  bool is_loading = false;
  bool password_visible = false;
  bool confirm_password_visible = false;
  TextEditingController password_controller = new TextEditingController();
  TextEditingController confirm_password_controller = new TextEditingController();

  final form_key = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          title: Container(
            alignment: Alignment.centerLeft,
            width: MediaQuery.of(context).size.width,
            child: Text("Create new password")
          )
      ),
      resizeToAvoidBottomInset: false,
      body: is_loading ? loadingPage() : mainPage(),
    );
  }

  Widget mainPage(){
    return Container(
      margin: EdgeInsets.all(10),
      padding: EdgeInsets.all(10),
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: Form(
        key: form_key,
        child: Column(
          children: [
            TextFormField(
              validator: (val){
                return val.length > 6 ? null : "Password must contain at least six characters";
              },
              style: primaryTextstyle(),
              controller: password_controller,
              obscureText: !password_visible,
              enableSuggestions: false,
              autocorrect: false,
              decoration: InputDecoration(
                  suffixIcon: IconButton(
                    icon: Icon(
                      password_visible ? Icons.visibility : Icons.visibility_off,
                      color: Theme.of(context).primaryColorDark,
                    ),
                    onPressed: (){
                      setState(() {
                        password_visible = !password_visible;
                      });
                    },
                  ),
                  labelStyle: secondaryTextStyle(),
                  labelText: "Password",
                  border: OutlineInputBorder()
              ),
            ),
            Container(height: 10,),
            TextFormField(
              validator: (val){
                if(val != password_controller.text){
                  return "Passwords don't match";
                }
                else{
                  return null;
                }
              },
              style: primaryTextstyle(),
              controller: confirm_password_controller,
              obscureText: !confirm_password_visible,
              enableSuggestions: false,
              autocorrect: false,
              decoration: InputDecoration(
                  suffixIcon: IconButton(
                    icon: Icon(
                      confirm_password_visible ? Icons.visibility : Icons.visibility_off,
                      color: Theme.of(context).primaryColorDark,
                    ),
                    onPressed: (){
                      setState(() {
                        confirm_password_visible = !confirm_password_visible;
                      });
                    },
                  ),
                  labelStyle: secondaryTextStyle(),
                  labelText: "Confirm password",
                  border: OutlineInputBorder()
              ),
            ),
            Container(height: 8,),
            Container(
                child: Center(
                  child: MaterialButton(
                    height: 50.0,
                    minWidth: 100.0,
                    color: Colors.white,
                    textColor: Colors.green,
                    child: new Text("Update password", style: TextStyle(fontSize: 14, fontFamily: 'aventa_regular'),),
                    onPressed: () => {
                      updatePassword(password_controller.text.toString())
                    },
                    splashColor: Theme.of(context).primaryColor,
                  )
                )
            ),
          ],
        ),
      ),
    );
  }

  Future<void> updatePassword(String password) async {
    if(form_key.currentState.validate()){
      bool is_connected = await checkConnection();
      if(is_connected){
        setState(() {
          is_loading = true;
        });
        AppUser user = await db_helper.getUserByEmail(widget.email);
        final params = {
          "password": "$password",
          "email": "${widget.email}"
        };
        var url = Uri.parse("${Constants.server_url}/selective_app/SelectiveTradesApp/updatePassword.php");
        var response = await http.post(url,body: params);
        if(response.statusCode == 200){
          if(response.body == "success"){

            UserCredential c = await FirebaseAuth.instance.signInWithEmailAndPassword(email: user.email, password: user.user_password);
            User u = await FirebaseAuth.instance.currentUser;
            await u.updatePassword(password);
            showToast("Password changed");
            Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) =>
                SignIn()), (Route<dynamic> route) => false);
          }
          else{
            setState(() {
              is_loading = false;
            });
            print("reset_password.updatePassword error: ${response.body}");
            showToast("An error occurred");
          }
        }
        else{
          setState(() {
            is_loading = false;
          });
          showToast("Unable to reset password");
        }
      }
      else{
        showToast("No internet connection");
      }
    }
  }
}
