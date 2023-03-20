import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:selective_chat/models/app_user.dart';
import 'package:selective_chat/utils/constants.dart';
import 'package:selective_chat/utils/db_helper.dart';
import 'package:selective_chat/utils/methods.dart';
import 'package:selective_chat/utils/push_notification_service.dart';
import 'package:selective_chat/utils/widgets.dart';
import 'package:crypto/crypto.dart';
import 'package:selective_chat/views/sign_in.dart';

import '../locator.dart';

class SignUp extends StatefulWidget {

  @override
  _SignUpState createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {

  PhoneNumber phone_code;

  String server_key = "key=AAAAIT2SXPk:APA91bGGnfeSDcsa_p7OCIj9-I2SVeAY53uT7Xotb4YgA401QXUO1SS26e0KXzCiRVK7MxnRmxrbiD67xDEzlKf0NCgX8-Yw3yVT_L5YlX5H11XUJFFb62FzCGBRbdR63C-GbLNinLOq";

  AppUser user;

  TextEditingController firstname_controller = new TextEditingController();
  TextEditingController lastname_controller = new TextEditingController();
  TextEditingController email_controller = new TextEditingController();
  TextEditingController phone_number_controller = new TextEditingController();
  TextEditingController password_controller = new TextEditingController();
  TextEditingController confirm_password_controller = new TextEditingController();
  TextEditingController pin_controller = new TextEditingController();

  bool password_visible = false;
  bool confirm_password_visible = false;
  bool is_select_terms_of_service = false;
  bool is_input_pin = false;

  List<AppUser> app_users = [];

  final isValidCharacters = RegExp(r'^[a-zA-Z ]+$');
  final form_key = GlobalKey<FormState>();

  final DbHelper db_helper = new DbHelper();

  bool is_loading = false;

  String pin = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Container(
          alignment: Alignment.centerLeft,
          width: MediaQuery.of(context).size.width,
          child: Text("Create new account")
        )
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        margin: EdgeInsets.fromLTRB(10, 15, 10, 10),
        padding: EdgeInsets.all(10),
        child: is_loading ? loadingPage() : mainPage()
      ),
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
      print("sign_up.createStripeUser: Unable to create stripe user" + json.decode(response.body));
    }
    return stripe_id;
  }

  String emailMessage(){
    String fullname = "${firstname_controller.text.toString().trim()} ${lastname_controller.text.toString().trim()}";
    String result = "Hello $fullname \n\n"
        "Thank you for your registration at SelectiveTrades\n\n"
        "Your login details:\n"
        "Email ID: ${email_controller.text.toString().toLowerCase()}\n"

        "You will access the channels below once you become a member.\n\n"
        "Educational\n"
        "     Stock Optional Signals\n"
        "     Breakout Stock Signals\n"
        "     Option Leaps\n"
        "     Educational Ideas\n"
        "     News\n"
        "     Results – Notifications\n"
        "     Stock charts"
        "     Chat discussion"
        "     Support\n\n"
        "User Defined\n"
        "     Stocks & Crypto Watchlist\n"
        "     Stocks & Crypto Portfolio\n\n"
        "Others\n"
        "     Live Options Tracker\n"
        "     Earnings Calendar\n"
        "     Economic Calendar\n\n"
        "     Mobile Notifications\n\n"
        "Note : All signals for options use 30-35% and stocks 1.5% as stoploss."
        "NOTE : ALL CONTENT ON WEB SITE & MOBILE APPS REPRESENTS OPINIONS ONLY AND PROVIDED FOR EDUCATIONAL PURPOSES ONLY. CONTENT SHOULD NOT BE CONSIDERED ADVICE OR A RECOMMENDATION TO BUY OR SELL A SECURITY. PLEASE SEEK ADVICE FROM AN INVESTMENT PROFESSIONAL.";
    return result;
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
                    onPressed: () async {
                      if(form_key.currentState.validate()){
                        if(isVerifyPin(pin_controller.text.toString())){
                          setState(() {
                            is_input_pin = false;
                            is_loading = true;
                          });
                          bool upload_user = await db_helper.uploadUser(user);
                          if(upload_user){
                            await sendRegistrationEmail(user);
                            await sendAdminEmail(user);
                            await sendNotifications();
                            PushNotificationService psn = locator<PushNotificationService>();
                            psn.setIsBackground(false);
                            setState(() {
                              is_loading = false;
                            });
                            Navigator.pop(context);
                          }
                          else{
                            showToast("Could not sign up");
                            setState(() {
                              is_loading = false;
                            });
                          }
                        }
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

  String generatePin(){
    final _random = new Random();
    String pin = "";
    for(int i=0; i<4; i++){
      int next(int min, int max) => min + _random.nextInt(max-min);
      pin += next(1,9).toString();
    }
    return pin;
  }

  Future<void> init() async {

  }

  @override
  void initState(){
    init();
    super.initState();
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

  Widget mainPage(){
    return is_input_pin ?
    enterPin() :
    SingleChildScrollView(
      child: Form(
        key: form_key,
        child: Column(
          children: [
            TextFormField(
              validator: (v){
                return isValidCharacters.hasMatch(firstname_controller.text.toString()) ? null : "No special characters allowed";
              },
              style: primaryTextstyle(),
              textCapitalization: TextCapitalization.sentences,
              controller: firstname_controller,
              decoration: InputDecoration(
                  labelStyle: secondaryTextStyle(),
                  labelText: "First name",
                  border: OutlineInputBorder()
              ),
            ),
            Container(height: 10,),
            TextFormField(
              validator: (v){
                return isValidCharacters.hasMatch(lastname_controller.text.toString()) ? null : "No special characters allowed";
              },
              style: primaryTextstyle(),
              textCapitalization: TextCapitalization.sentences,
              controller: lastname_controller,
              decoration: InputDecoration(
                  labelStyle: secondaryTextStyle(),
                  labelText: "Last name",
                  border: OutlineInputBorder()
              ),
            ),
            Container(height: 10,),
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
            IntlPhoneField(
              decoration: InputDecoration(
                labelText: "Mobile number",
                labelStyle: secondaryTextStyle(),
                border: OutlineInputBorder(
                  borderSide: BorderSide(),
                )
              ),
              initialCountryCode: 'US',
              onChanged: (phone){
                phone_code = phone;
              },
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: (){
                    openTermsOfService();
                  },
                  child: Container(
                    padding: EdgeInsets.all(10),
                    child: Text(
                      "Terms of service",
                      style: TextStyle(
                        fontFamily: 'aventa_bold',
                        color: Colors.blue,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                Checkbox(
                  value: is_select_terms_of_service,
                  onChanged: (newValue){
                    setState(() {
                      is_select_terms_of_service = newValue;
                    });
                  },
                )
              ],
            ),
            Container(height: 3),
            Container(
              child: Text("By checking the box, you agree to SelectiveTrades LLC terms of service", style: primaryTextstyle(),),
            ),
            Container(height: 5,),
            Container(
              margin: EdgeInsets.fromLTRB(0, 0, 0, 50),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    MaterialButton(
                      height: 50.0,
                      minWidth: 100.0,
                      color: Colors.white,
                      textColor: Colors.green,
                      child: new Text("Create account", style: TextStyle(fontSize: 14, fontFamily: 'aventa_regular'),),
                      onPressed: () => {
                        if(is_select_terms_of_service)
                          showAlertDialog(context, "All content on the mobile app represent opinions "
                      "only, and are provided for educational purposes only. Content"
                      " should not be considered as financial advice or a recommendation "
                      "to buy or sell a security. Please seek advice from an investment professional.", onClosePrivacyPolicyMessage)
                      },
                      splashColor: Theme.of(context).primaryColor,
                    ),
                    MaterialButton(
                      height: 50.0,
                      minWidth: 100.0,
                      color: Colors.white,
                      textColor: Colors.green,
                      child: new Text("Login instead", style: TextStyle(fontSize: 14, fontFamily: 'aventa_regular'),),
                      onPressed: () => {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => SignIn()))
                      },
                      splashColor: Theme.of(context).primaryColor,
                    )
                  ],
                )
            ),
          ],
        ),
      ),
    );
  }

  Future onClosePrivacyPolicyMessage() async{
    Navigator.pop(context);
    await signUp();
  }

  void onClickEmailDialog(){
    setState(() {
      is_loading = false;
    });
    Navigator.pop(context);
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => SignIn()));
  }

  Future<void> sendAdminEmail(AppUser user) async {
    try{
      String reg_date = DateFormat("yyyy/MM/dd mm:hh:ss").format(DateTime.fromMillisecondsSinceEpoch(int.parse(user.date_registered)));
      String expiry = DateFormat("yyyy/MM/dd mm:hh:ss").format(DateTime.fromMillisecondsSinceEpoch(int.parse(user.expiry_date)));
      String message = "A new user just signed up \n\n"
          "User details\n\n"
          "Name: ${user.username}\n"
          "Email ID: ${user.email}\n"
          "Phone number: ${user.phone_number}\n"
          "Device: ${user.device}\n"
          "${user.ip_address}\n"
          "Registration date: $reg_date\n"
          "Expiry date: $expiry\n";
      Map<String, String> params = {"pin": "$message"};
      var uri = Uri.https(Constants.server_get_url, "/selective_app/SelectiveTradesApp/sendAdminEmail.php", params);
      await http.get(uri);
    }
    catch(e){

    }
  }

  Future sendNotifications() async {
    String firebase_token = await refreshFirebaseToken();
    List<String> s = ["$firebase_token"];
    String m = "Thank you for your registration at SelectiveTrades\n\n"
        "Here are your login details:\n"
        "Email ID: ${email_controller.text.toString().trim()}\n"
        "Password: ${password_controller.text.toString().trim()}\n\n";
    Map<String, dynamic> message;
    message = {
      "notification": {
        "sound": "default",
        "title": "Welcome to SelectiveTrades",
        "body": "$m"
      },
      "data": {
        "click_action": "FLUTTER_NOTIFICATION_CLICK",
        "screen": "channel_messages",
        "title": "Welcome to SelectiveTrades",
        "message": "${m}",
      },
      "registration_ids": s
    };
    var url = Uri.parse("https://fcm.googleapis.com/fcm/send");
    var response = await http.post(url, body:jsonEncode(message), headers: {"Authorization":server_key,"Content-Type":"application/json"});
  }

  void sendPinToEmail(String email) async{
    pin = generatePin();

    String message = "Hello ${user.username}\nWelcome to SelectiveTrades, use " + pin + " to finalise your registration";

    Map<String, String> params = {"pin": message, "email": user.email};
    var url = Uri.https(Constants.server_get_url, "/selective_app/SelectiveTradesApp/sendPinToEmail.php", params);
    await http.get(url).then((value){
      Response response = value;
      if(response.statusCode == 200){
        showToast("A 4 digit pin has been sent to your email");
        print("sign_up.sendPinToEmail success response: ${response.body.toString()}");
        setState(() {
          is_input_pin = true;
          is_loading = false;
        });
      }
      else{
        showToast("An error occurred");
        print("sign_up.sendPinToEmail failure response: ${response.body.toString()}");
        setState(() {
          is_loading = false;
        });
      }
    });
  }

  Future<void> sendRegistrationEmail(AppUser user) async{
    try{
      Map<String, String> params = {"pin": emailMessage(), "email": user.email};
      var uri = Uri.https(Constants.server_get_url, "/selective_app/SelectiveTradesApp/sendRegistrationEmail.php", params);
      await http.get(uri);
    }
    catch(e){

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

  Future<void> signUp() async{
    bool is_connected = await checkConnection();
    if(is_connected){
      if(form_key.currentState.validate()){

        setState(() {
          is_loading = true;
        });

        var email = email_controller.text.toString().toLowerCase().trim();
        var firstname = firstname_controller.text.toString();
        var lastname = lastname_controller.text.toString();
        var password = password_controller.text.toString();
        var confirm_password = confirm_password_controller.text.toString();
        var phone_number = phone_code.completeNumber+phone_number_controller.text.toString();

        if(!isValidEmail(email)){
          showToast("Invalid email");
        }
        else if(!isValidCharacters.hasMatch(firstname)){
          showToast("Firstname should contain only alphabets");
        }
        else if(!isValidCharacters.hasMatch(lastname)){
          showToast("Lastname should contain only alphabets");
        }
        else if(password.isEmpty || confirm_password.isEmpty){
          showToast("Password required");
        }
        else if(password != confirm_password){
          showToast("Passwords don't match");
        }
        else if(phone_number.isEmpty){
          showToast("Phone number required");
        }

        bool email_exist = await db_helper.isEmailExist(email);
        bool phone_exist = await db_helper.isPhoneExist(phone_number);

        if(email_exist){
          showToast("This email is taken by another user");
          setState(() {
            is_loading = false;
          });
        }
        // if(phone_exist){
        //   showToast("This phone number is registered to another user");
        //   setState(() {
        //     is_loading = false;
        //   });
        // }

        if(!email_exist){
          String ip_address = await getLocationByIp();
          String id = "";
          String date_registered = DateTime.now().millisecondsSinceEpoch.toString();
          String expiry_date = date_registered;
          String firebase_tokens = '"{firebase_tokens:[]}"';
          String active = "true";
          String app_version_ios = Platform.isIOS ? Constants.ios_app_version : "";
          String app_version_android = Platform.isAndroid ? Constants.android_app_version : "";
          DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
          String device = "";
          if(Platform.isAndroid){
            AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
            device = androidInfo.manufacturer + " " + androidInfo.model;
          }
          else if(Platform.isIOS){
            IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
            device = iosInfo.utsname.machine + " " + iosInfo.model;
          }
          String logged_in = "false";
          String profile_image_url = "";
          String username = "${firstname_controller.text.toString().trim()} ${lastname_controller.text.toString().trim()}";
          String hash = sha256.convert(utf8.encode(email)).toString();

          String stripe_id = await createStripeUser();

          user = AppUser(
              id: id,
              stripe_id: stripe_id,
              username: username,
              email: email,
              phone_number: phone_number,
              date_registered: date_registered,
              expiry_date: expiry_date,
              firebase_tokens: firebase_tokens,
              user_password: password,
              active: active,
              app_version_ios: app_version_ios,
              app_version_android: app_version_android,
              device: device,
              ip_address: ip_address,
              logged_in: logged_in,
              profile_image_url: profile_image_url,
              hash: hash,
              last_login: date_registered
          );

          UserCredential c;
          try{
            c = await FirebaseAuth.instance.signInWithEmailAndPassword(email: user.email, password: user.user_password);
          }
          catch(e){
            print("sign_up.signUp user credential exception1 ${e.toString()}");
            c = null;
          }

          if(c == null){
            try{
              UserCredential result = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email.toLowerCase(), password: password);
              await result.user.sendEmailVerification();
              await uploadUser(user);
              showAlertDialog(context, "A verification link has been sent to your email, kindly also check the spam folder. Verify your email and login", onClickEmailDialog);
            }
            catch(e){
              print("sign_up.signUp user credential exception2 ${e.toString()}");
              setState(() {
                is_loading = false;
              });
            }
          }
          else{
            if(!c.user.emailVerified) {
              try{
                await c.user.sendEmailVerification();
                await uploadUser(user);
                showAlertDialog(context, "A verification link has been sent to your email, kindly also check the spam folder. Verify your email and login", onClickEmailDialog);
              }
              catch(e){
                print("sign_up.signUp user credential exception3 ${e.toString()}");
                setState(() {
                  is_loading = false;
                });
              }
            }
            else{
              setState(() {
                is_loading = false;
              });
              await uploadUser(user);
              showAlertDialog(context, "Registration successful, you can login", onClickEmailDialog);
            }
          }
        }
      }
    }
    else{
      showToast("No internet connection");
    }
  }

  Future<void> uploadUser(AppUser user) async {
    bool upload_user = await db_helper.uploadUser(user);
    if(upload_user){
      await sendRegistrationEmail(user);
      await sendAdminEmail(user);
      await sendNotifications();
      PushNotificationService psn = locator<PushNotificationService>();
      psn.setIsBackground(false);
    }
    else{
      showToast("Could not sign up");
      setState(() {
        is_loading = false;
      });
    }
  }

}
