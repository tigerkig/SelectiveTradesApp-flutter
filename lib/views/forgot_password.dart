import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:selective_chat/models/app_user.dart';
import 'package:selective_chat/utils/constants.dart';
import 'package:selective_chat/utils/db_helper.dart';
import 'package:selective_chat/utils/methods.dart';
import 'package:selective_chat/utils/widgets.dart';
import 'package:selective_chat/views/reset_password.dart';
import 'package:last_state/last_state.dart';
import 'package:selective_chat/views/sign_in.dart';

class ForgotPassword extends StatefulWidget {

  @override
  _ForgotPasswordState createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> with LastStateRestoration {

  TextEditingController email_controller = new TextEditingController();
  TextEditingController pin_controller = new TextEditingController();

  String password_reset_link = "${Constants.server_url}/selective_app/SelectiveTradesApp/selective_forgot_password/main/";

  bool from_last_state = false;
  bool is_loading = false;
  bool is_input_pin = false;
  String pin = "";
  DbHelper db_helper = new DbHelper();
  final form_key = GlobalKey<FormState>();

  Timer timer;
  int start = 5;

  @override
  Widget build(BuildContext context) {
    if(from_last_state){
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
            leading:GestureDetector(
              onTap: (){
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => SignIn()));
              },
              child: Icon(Icons.arrow_back)
            ),
            title: Container(
                alignment: Alignment.centerLeft,
                width: MediaQuery.of(context).size.width,
                child: Text("Recover account")
            )
        ),
        resizeToAvoidBottomInset: false,
        body: is_loading ? loadingPage() : mainPage(),
      );
    }
    else{
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
            title: Container(
                alignment: Alignment.centerLeft,
                width: MediaQuery.of(context).size.width,
                child: Text("Recover account")
            )
        ),
        resizeToAvoidBottomInset: false,
        body: is_loading ? loadingPage() : mainPage(),
      );
    }
  }

  Widget enterPin(){
    return Form(
      key: form_key,
      child: Container(
        margin: EdgeInsets.all(10),
        padding: EdgeInsets.all(10),
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: Center(
          child: Column(
            children: [
              TextFormField(
                validator: (v){
                  return isVerifyPin(pin_controller.text.toString()) ? null : "Incorrect pin";
                },
                maxLength: 4,
                style: primaryTextstyle(),
                keyboardType: TextInputType.number,
                controller: pin_controller,
                decoration: InputDecoration(
                    labelStyle: secondaryTextStyle(),
                    labelText: "Enter pin",
                    border: OutlineInputBorder()
                ),
              ),
              Container(
                  height: 30
              ),
              MaterialButton(
                height: 50.0,
                minWidth: 150.0,
                color: Colors.white,
                textColor: Colors.green,
                child: new Text("Verify pin", style: TextStyle(fontSize: 16, fontFamily: 'aventa_regular'),),
                onPressed: () => {
                  if(form_key.currentState.validate()){
                    if(isVerifyPin(pin)){
                      Navigator.push(context, MaterialPageRoute(builder: (context) => ResetPasswordScreen(email:email_controller.text)))
                    }
                    // if(isVerifyPin(pin_controller.text.toString())){
                    //   Navigator.push(context, MaterialPageRoute(builder: (context) => ResetPasswordScreen(email:email_controller.text.toString())))
                    // }
                  }
                },
                splashColor: Theme.of(context).primaryColor,
              ),
            ],
          )
        )
      ),
    );
  }

  Widget mainPage() {
    return is_input_pin ?
    enterPin() :
    Form(
      key: form_key,
      child: Container(
        margin: EdgeInsets.all(10),
        padding: EdgeInsets.all(10),
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: Column(
          children: [
            Text(
              "Enter your registered email and we will send a pin. Kindly be patient as it takes some time for servers to respond and send the pin. ",
              style: primaryTextstyle(),
            ),
            Container(
              height: 80,
            ),
            TextFormField(
              validator: (v){
                return isValidEmail(email_controller.text.toString()) ? null : "Invalid email";
              },
              style: primaryTextstyle(),
              controller: email_controller,
              decoration: InputDecoration(
                  labelStyle: secondaryTextStyle(),
                  labelText: "Email",
                  border: OutlineInputBorder()
              ),
            ),
            Container(
              height: 30
            ),
            MaterialButton(
              height: 50.0,
              minWidth: 150.0,
              color: Colors.white,
              textColor: Colors.green,
              child: new Text("Send pin", style: TextStyle(fontSize: 16, fontFamily: 'aventa_regular'),),
              onPressed: () => {
                searchEmail(email_controller.text.toString())
              },
              splashColor: Theme.of(context).primaryColor,
            ),
          ],
        )
      ),
    );
  }

  Future<void> searchEmail(String email) async{
    if(form_key.currentState.validate()){
      bool is_connected = await checkConnection();
      if(is_connected){
        setState(() {
          is_loading = true;
        });
        AppUser user = await db_helper.getUserByEmail(email);
        if(user == null){
          setState(() {
            is_loading = false;
          });
          showToast("User not found");
        }
        else{
          sendPinToEmail(email_controller.text.toString());
        }
      }
      else{
        setState(() {
          is_loading = false;
        });
        showToast("No internet connection");
      }
    }

  }

  bool isVerifyPin(String _pin){
    if(pin.length < 4)
      return false;
    else if(_pin != pin){
      return false;
    }
    else if(_pin == pin){
      return true;
    }
    return false;
  }

  @override
  initState(){
    super.initState();
  }

  void sendPinToEmail(String email) async{
    pin = generatePin();
    String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    String to_hash = email+timestamp;
    String hash = sha256.convert(utf8.encode(to_hash)).toString();
    String s = password_reset_link + "${email.trim()}/$timestamp/$hash";
    String message = "Use " + pin + " for resetting your password."
        " The pin expires after 5 minutes. "
        "Disregard this email if you did not request to reset your password";
    Map<String, String> params = {"pin": message, "email": email};
    var uri = Uri.https(Constants.server_get_url, "/selective_app/SelectiveTradesApp/sendPinToEmail.php", params);
    await http.get(uri, headers: null).then((value){
      Response response = value;
      if(response.statusCode == 200){
        showToast("A 4 digit pin has been sent to your email");
        int time = DateTime.now().millisecondsSinceEpoch;

        SavedLastStateData.instance.putInt("time", time);
        SavedLastStateData.instance.putString("pin", pin);
        SavedLastStateData.instance.putString("email", email);
        SavedLastStateData.instance.putBool("is_input_pin", true);

        if(Platform.isIOS){
          startTimer();
        }

        setState(() {
          is_input_pin = true;
          is_loading = false;
        });
      }
      else{
        showToast("An error occurred");
        setState(() {
          is_loading = false;
        });
      }
    });
  }

  void startTimer() {
    const one_min = const Duration(minutes: 1);
    timer = new Timer.periodic(
      one_min,
          (Timer timer) {
        if (start == 0) {
          showToast("Password reset action expired");
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => SignIn()));
        } else {
          setState(() {
            start--;
          });
        }
      },
    );
  }

  String generatePin(){
    final _random = new Random();
    String pin = "";
    for(int i=0; i<4; i++){
      int next(int min, int max) => min + _random.nextInt(max-min);
      pin += next(1,9).toString();
    }
    return pin;
  }

  @override
  void lastStateRestored() {
    print("forgot_password.lastStateRestored");
    int time = SavedLastStateData.instance.getInt("time") ?? 0;
    int now = DateTime.now().millisecondsSinceEpoch;
    if(time != 0){
      if(now - time > 300000){
        showToast("Password reset action expired");
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => SignIn()));
      }
    }
    setState(() {
      from_last_state = true;
      pin = SavedLastStateData.instance.getString("pin") ?? "";
      email_controller.text = SavedLastStateData.instance.getString("email") ?? "";
      is_input_pin = SavedLastStateData.instance.getBool("is_input_pin") ?? false;
    });
  }
}
