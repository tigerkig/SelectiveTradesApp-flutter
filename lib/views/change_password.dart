import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:selective_chat/models/app_user.dart';
import 'package:selective_chat/utils/constants.dart';
import 'package:selective_chat/utils/db_helper.dart';
import 'package:selective_chat/utils/methods.dart';
import 'package:selective_chat/utils/widgets.dart';
import 'package:http/http.dart' as http;

class ChangePasswordScreen extends StatefulWidget {

  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {

  bool is_loading = false;
  TextEditingController new_password_controller = new TextEditingController();
  TextEditingController old_password_controller = new TextEditingController();
  TextEditingController confirm_password_controller = new TextEditingController();

  final form_key = GlobalKey<FormState>();
  DbHelper db_helper = new DbHelper();

  AppUser user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          title: Container(
              alignment: Alignment.centerLeft,
              width: MediaQuery.of(context).size.width,
              child: Text("Change password")
          )
      ),
      resizeToAvoidBottomInset: false,
      body: is_loading ? loadingPage() : mainPage(),
    );
  }

  Future<void> init() async {
    user = await db_helper.getAppUserSQLite();
    setState(() {

    });
  }

  @override
  void initState(){
    init();
    super.initState();
  }

  Widget mainPage(){
    return Form(
      key: form_key,
      child: Container(
        margin: EdgeInsets.all(8),
        padding: EdgeInsets.all(10),
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: Column(
          children: [
            Container(
              alignment: Alignment.centerLeft,
              child: Text(
                "Change your SelectiveTrades password using the form below",
                style: primaryTextstyle(),
              ),
            ),
            Container(height: 10,),
            TextFormField(
              validator: (val){
                return val.toString() == user.user_password ? null : "Incorrect password";
              },
              decoration: InputDecoration(
                  labelStyle: secondaryTextStyle(),
                  labelText: "Old password",
                  border: OutlineInputBorder()
              ),
              style: primaryTextstyle(),
              controller: old_password_controller,
              obscureText: true,
              enableSuggestions: false,
              autocorrect: false,
            ),
            Container(height: 10,),
            TextFormField(
              validator: (val){
                return val.length > 6 ? null : "Password must contain at least six characters";
              },
              decoration: InputDecoration(
                  labelStyle: secondaryTextStyle(),
                  labelText: "New password",
                  border: OutlineInputBorder()
              ),
              style: primaryTextstyle(),
              controller: new_password_controller,
              obscureText: true,
              enableSuggestions: false,
              autocorrect: false,
            ),
            Container(height: 8,),
            TextFormField(
              validator: (val){
                if(val != new_password_controller.text){
                  return "Passwords don't match";
                }
                else{
                  return null;
                }
              },
              decoration: InputDecoration(
                  labelStyle: secondaryTextStyle(),
                  labelText: "Retype new password",
                  border: OutlineInputBorder()
              ),
              style: primaryTextstyle(),
              controller: confirm_password_controller,
              obscureText: true,
              enableSuggestions: false,
              autocorrect: false,
            ),
            Container(height: 8,),
            Container(
              width: MediaQuery.of(context).size.width,
              alignment: Alignment.center,
              child: MaterialButton(
                height: 50.0,
                minWidth: 150.0,
                color: Colors.white,
                textColor: Colors.green,
                child: new Text("Update password", style: TextStyle(fontSize: 16, fontFamily: 'aventa_regular'),),
                onPressed: () => {
                  updatePassword()
                },
                splashColor: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> updatePassword() async {
    if(form_key.currentState.validate()){
      setState(() {
        is_loading = true;
      });

      String password = new_password_controller.text.toString();
      final params = {
        "email":user.email,
        "password":password
      };

      try{
        var url = Uri.parse("${Constants.server_url}/selective_app/SelectiveTradesApp/updatePassword.php");
        var response = await http.post(url, body: params);
        if(response.body.isNotEmpty){
          if(response.body == "success"){
            UserCredential c = await FirebaseAuth.instance.signInWithEmailAndPassword(email: user.email, password: user.user_password);
            User u = await FirebaseAuth.instance.currentUser;
            await u.updatePassword(password);
            user.user_password = password;
            await db_helper.updateAppUserSQLite(user);
            showToast("Password updated");
            Navigator.pop(context);
          }
          else{
            showToast("An error occurred ${response.body}");
            print("change_password.updatePassword response ${response.body}");
            setState(() {
              is_loading = false;
            });
          }
        }
        else{
          setState(() {
            is_loading = false;
          });
        }
      }
      catch(e){
        setState(() {
          is_loading = false;
        });
        print("change_password.updatePassword exception ${e.toString()}");
      }
    }
  }
}
