import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:selective_chat/models/app_user.dart';
import 'package:selective_chat/models/channel.dart';
import 'package:selective_chat/utils/constants.dart';
import 'package:selective_chat/utils/db_helper.dart';
import 'package:selective_chat/utils/methods.dart';
import 'package:selective_chat/utils/widgets.dart';
import 'package:selective_chat/views/channel_screen.dart';
import 'package:selective_chat/views/forgot_password.dart';
import 'package:selective_chat/views/notification_result_screen.dart';
import 'package:selective_chat/views/sign_up.dart';
import 'package:selective_chat/views/subscriptions.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

class SignIn extends StatefulWidget {

  @override
  _SignInState createState() => _SignInState();
}

class _SignInState extends State<SignIn> {

  TextEditingController email_controller = new TextEditingController();
  TextEditingController password_controller = new TextEditingController();

  final DbHelper db_helper = new DbHelper();

  StreamSubscription connection_stream_subscription;
  bool password_visible = false;
  bool is_loading = false;
  bool is_email_verified = false;

  final form_key = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        actions: [
          is_loading ? GestureDetector(
            onTap: (){
              setState(() {
                is_loading = false;
              });
            },
            child: Padding(
              padding: EdgeInsets.all(10),
              child: Icon(Icons.arrow_back, color: Colors.white,),
            ),
          ) : Container(width: 0,),
        ],
        title: Container(
          alignment: Alignment.centerLeft,
          width: MediaQuery.of(context).size.width,
          child: Text("SelectiveTrades")
        )
      ),
      resizeToAvoidBottomInset: true,
      body: is_loading ? loadingPage() : mainPage(),
    );
  }

  static Route _buildRoute(BuildContext context, Object params) {
    return MaterialPageRoute<void>(
      builder: (BuildContext context) => ForgotPassword(),
    );
  }

  Future<String> createStripeUser() async {
    String stripe_id = "";
    Map<String, String> headers = {
      'Authorization': 'Bearer ${Constants.stripe_secret_key}',
      'Content-Type': 'application/x-www-form-urlencoded'
    };
    final String url = 'https://api.stripe.com/v1/customers';
    var response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: {
        'description': 'New customer'
      },
    );
    if (response.statusCode == 200) {
      var json = jsonDecode(response.body.toString());
      stripe_id = json["id"];
    } else {
      print("sign_in.createStripeUser: Unable to create stripe user" + json.decode(response.body));
    }
    return stripe_id;
  }

  Future<void> init() async {
    AppUser user = await db_helper.getAppUserSQLite();
    if(user != null){
      user.logged_in = "false";
      user.ip_address = await getLocationByIp();
      user.app_version_ios = Platform.isIOS ? Constants.ios_app_version : "";
      user.app_version_android = Platform.isAndroid ? Constants.android_app_version : "";
      user.device = "";
      await db_helper.updateUser(user);
    }
    await db_helper.deleteDatabase();
  }

  @override
  void initState(){
    init();
    super.initState();
  }

  Future<void> isEmailVerified() async {
    String email = email_controller.text.toString().toLowerCase().trim();
    String password = password_controller.text.toString();
    UserCredential c;
    try{
      c = await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
    }
    catch(e){
      print("sign_in.isEmailVerified user credential exception1 ${e.toString()}");
      c = null;
    }

    if(c == null){
      try{
        UserCredential result = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email.toLowerCase(), password: password);
        await result.user.sendEmailVerification();
        showAlertDialog(context, "A verification link has been sent to your email, kindly check the spam folder. Verify your email and login", onClickDialog);
        setState(() {
          is_loading = false;
          is_email_verified = false;
        });
      }
      catch(e){
        print("sign_in.isEmailVerified unable to create new firebase user ${e.toString()}");
        showToast("An error occurred try again");
        setState(() {
          is_loading = false;
          is_email_verified = false;
        });
      }
    }
    else{
      if(!c.user.emailVerified) {
        try{
          await c.user.sendEmailVerification();
          showAlertDialog(context, "A verification link has been sent to your email, kindly check the spam folder. Verify your email and login", onClickDialog);
          setState(() {
            is_loading = false;
            is_email_verified = false;
          });
        }
        catch(e){
          print("sign_up.signUp user credential exception3 ${e.toString()}");
          setState(() {
            is_loading = false;
            is_email_verified = false;
          });
        }
      }
      else{
        setState(() {
          is_loading = false;
          is_email_verified = true;
        });
      }
    }
  }

  Widget mainPage(){
    return SingleChildScrollView(
      child: Form(
        key: form_key,
        child: Container(
          padding: EdgeInsets.all(10),
          margin: EdgeInsets.fromLTRB(10, 15, 10, 10),
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: Column(
            children: [
              Container(
                width: 150,
                height: 150,
                child: Image.asset('assets/images/logo.jpeg', width:150, height:150),
              ),
              Container(
                height: 20,
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
              Container(height: 10,),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: (){
                      Navigator.pushNamed(context, "forgot_password");
                    },
                    child: Container(
                      padding: EdgeInsets.all(10),
                      child: Text(
                          "Forgot password",
                          style: secondaryTextStyle()
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: (){
                      openPrivacyPolicy();
                    },
                    child: Container(
                      padding: EdgeInsets.all(10),
                      child: Text(
                        "Privacy policy",
                        style: TextStyle(
                          fontFamily: 'aventa_bold',
                          color: Colors.blue,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Container(height: 5,),
              Container(
                width: MediaQuery.of(context).size.width,
                alignment: Alignment.center,
                child: MaterialButton(
                  height: 50.0,
                  minWidth: 150.0,
                  color: Colors.white,
                  textColor: Colors.green,
                  child: new Text("Sign in", style: TextStyle(fontSize: 16, fontFamily: 'aventa_regular'),),
                  onPressed: () => {
                    signIn()
                  },
                  splashColor: Theme.of(context).primaryColor,
                ),
              ),
              Container(height: 10,),
              GestureDetector(
                onTap: (){
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => SignUp()));
                },
                child: Container(
                  padding: EdgeInsets.all(15),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Don't have an account? ", style: TextStyle(
                            fontSize: 13,
                            color: Colors.black,
                            fontFamily: 'aventa_light'
                        )),
                        Text(
                          "Register now",
                          style: TextStyle(
                            fontFamily: 'aventa_bold',
                            color: Colors.blue,
                            fontSize: 14,
                          ),
                        ),
                      ]
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void onClickDialog(){
    Navigator.pop(context);
  }

  Future<void> openPrivacyPolicy() async{
    var url = "https://www.privacypolicygenerator.info/live.php?token=xAlhBib5UifN3Pdf3ic6SzIac7u4lzy6";
    if(await canLaunch(url)){
      await launch(url);
    }
    else{
      showToast("Cannot launch URL");
    }
  }

  Future<void> signIn() async{
    if(form_key.currentState.validate()){
      bool is_connected = await checkConnection();
      if(!is_connected){
        showToast("No internet connection");
      }
      else{
        if(mounted){
          setState(() {
            is_loading = true;
          });
        }
        bool is_email_exist = await db_helper.isEmailExist(email_controller.text.toString().toLowerCase());
        bool is_correct_password = await db_helper.isCorrectPassword(email_controller.text.toString(), password_controller.text.toString());
        if(is_email_exist && is_correct_password){
          await isEmailVerified();
          if(!is_email_verified){
            setState(() {
              is_loading = false;
            });
          }
          else{
            setState(() {
              is_loading = true;
            });
            AppUser user = await db_helper.getUserByEmail(email_controller.text.toString().toLowerCase().trim());
            bool is_same_device = false;
            DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
            String current_device = "";
            if(Platform.isAndroid){
              AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
              current_device = androidInfo.manufacturer.toLowerCase() + " " + androidInfo.model.toLowerCase();
            }
            else if(Platform.isIOS){
              IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
              current_device = iosInfo.utsname.machine.toLowerCase() + " " + iosInfo.model.toLowerCase();
            }

            if(current_device.toLowerCase() == user.device.toLowerCase()){
              is_same_device = true;
            }
            if(user.device == ""){
              is_same_device = true;
            }
            if(!is_same_device){
              if(mounted){
                setState(() {
                  showToast("You are logged in on another device");
                  is_loading = false;
                });
              }
            }
            else{
              String ip_details = await getLocationByIp();
              user.ip_address = ip_details;
              user.app_version_ios = Platform.isIOS ? Constants.ios_app_version : "";
              user.app_version_android = Platform.isAndroid ? Constants.android_app_version : "";

              DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
              if(Platform.isAndroid){
                AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
                user.device = androidInfo.manufacturer + " " + androidInfo.model;
              }
              else if(Platform.isIOS){
                IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
                user.device = iosInfo.utsname.machine + " " + iosInfo.model;
              }

              String firebase_token = await refreshFirebaseToken();
              await Purchases.logIn(user.hash);
              if(user.stripe_id == null || user.stripe_id == ""){
                String stripe_id = await createStripeUser();
                user.stripe_id = stripe_id;
              }
              await updateStripeUser(user);

              if(user.firebase_tokens == null || user.firebase_tokens == ""){
                var firebase_json = jsonDecode("{}");
                List<String> l = ['"${firebase_token}"'];
                firebase_json['"firebase_tokens"'] = l;
                user.firebase_tokens = firebase_token;
                user.logged_in = "true";
                String last_login = DateTime.now().millisecondsSinceEpoch.toString();
                user.last_login = last_login;
                await db_helper.saveAppUserSQLite(user);
                user.firebase_tokens = firebase_json.toString();
                await db_helper.updateUser(user);
                //await db_helper.getAndSaveNewUsers();
                int expiry = int.parse(user.expiry_date) + Constants.two_days;
                if(expiry < DateTime.now().millisecondsSinceEpoch){
                  user.logged_in = "false";
                  await db_helper.updateAppUserSQLite(user);
                  await db_helper.updateUser(user);
                  Channel channel = Channel(channel_name: "Notifications - Results");
                  setState(() {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => NotificationResultScreen(channel: channel,)));
                  });
                }
                else{
                  if(user.active == "false"){
                    showToast("Your account has been deactivated, contact admin");
                  }
                  else{
                    Channel channel = Channel(channel_name: "Notifications - Results");
                    setState(() {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => NotificationResultScreen(channel: channel,)));
                    });
                  }
                }
              }
              else if(user.firebase_tokens != ""){
                final firebase_json = jsonDecode(user.firebase_tokens);
                List<dynamic> l = [];
                if(!l.contains(firebase_token)){
                  l.add(firebase_token);
                }
                List<String> to_upload = [];
                for(var i = 0; i<l.length; i++){
                  to_upload.add('"${l[i]}"');
                }
                user.firebase_tokens = firebase_token;
                user.logged_in = "true";
                String last_login = DateTime.now().millisecondsSinceEpoch.toString();
                user.last_login = last_login;
                await db_helper.saveAppUserSQLite(user);
                var firebase_json_ = jsonDecode("{}");
                firebase_json_['"firebase_tokens"'] = to_upload;
                user.firebase_tokens = firebase_json_.toString();
                await db_helper.updateUser(user);
                //await db_helper.getAndSaveNewUsers();
                int expiry = int.parse(user.expiry_date) + Constants.two_days;
                if(expiry < DateTime.now().millisecondsSinceEpoch){
                  Channel channel = Channel(channel_name: "Notifications - Results");
                  setState(() {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => NotificationResultScreen(channel: channel,)));
                  });
                }
                else{
                  if(user.active == "false"){
                    showToast("Your account has been deactivated. Contact admin");
                    setState(() {
                      is_loading = false;
                    });
                  }
                  else{
                    Channel channel = Channel(channel_name: "Notifications - Results");
                    setState(() {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => NotificationResultScreen(channel: channel,)));
                    });
                  }
                }
              }
            }
          }

        }
        else{
          if(mounted){
            setState(() {
              showToast("Incorrect credentials");
              is_loading = false;
            });
          }
        }
      }
    }
  }

  showAlertDialog(BuildContext context, String text, Function f) {
    Widget okButton = TextButton(
      child: Text("OK"),
      onPressed: () async{
        f();
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Info"),
      content: Text("$text"),
      actions: [
        okButton,
      ],
    );
    // show the dialog
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  Future<void> updateStripeUser(AppUser user) async {
    Map<String, String> headers = {
      'Authorization': 'Bearer ${Constants.stripe_secret_key}',
      'Content-Type': 'application/x-www-form-urlencoded'
    };
    final params = {
      "email": user.email,
      "description": "SelectiveTradesApp customer",
      "name": user.username,
      "phone": user.phone_number,
    };
    final String url = 'https://api.stripe.com/v1/customers/${user.stripe_id}';
    var response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: params,
    );
    if (response.statusCode == 200) {
      //print("sign_in.updateStripeUser response ${response.body.toString()}");
      var json = jsonDecode(response.body.toString());
    } else {
      print("sign_up.updateStripeUser: Unable to create stripe user" + response.body);
    }
  }

}
