import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:selective_chat/models/app_user.dart';
import 'package:selective_chat/utils/constants.dart';
import 'package:selective_chat/utils/methods.dart';
import 'package:selective_chat/utils/my_icons.dart';
import 'package:selective_chat/utils/widgets.dart';
import 'package:selective_chat/views/change_password.dart';
import 'package:selective_chat/views/sign_in.dart';
import 'package:selective_chat/views/subscriptions.dart';
import 'package:http/http.dart' as http;

import '../utils/db_helper.dart';

class SettingsScreen extends StatefulWidget {

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  bool is_loading = false;
  DbHelper db_helper = DbHelper();
  AppUser user;
  AppUser temp_user;

  SMSDialog smsDialog;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          title: Container(
              alignment: Alignment.centerLeft,
              width: MediaQuery.of(context).size.width,
              child: Text("Settings")
          )
      ),
      resizeToAvoidBottomInset: false,
      body: is_loading ? loadingPage() : mainPage(),
    );
  }

  Future<void> requestDeletion() async {
    setState(() {
      is_loading = true;
    });
    await sendEmail();
    AppUser u = await db_helper.getUserByEmail(user.email);
    u.active = "false";
    await db_helper.updateUser(u);
    showToast("Your account will be deleted by the admin");
    setState(() {
      is_loading = false;
    });
    Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => SignIn()));
  }

  Future<void> init() async {
    setState(() {
      is_loading = true;
    });
    user = await db_helper.getAppUserSQLite();
    setState(() {
      is_loading = false;
    });
    temp_user = await db_helper.getUserByEmail(user.email);
  }

  @override
  void initState(){
    init();
    super.initState();
  }

  Widget mainPage() {
    return Container(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      child: Column(
        children: [
          Card(
            margin: EdgeInsets.all(8),
            child: GestureDetector(
              onTap: (){
                Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => ChangePasswordScreen()));
              },
              child: Container(
                padding: EdgeInsets.all(8),
                width: MediaQuery.of(context).size.width,
                height: 50,
                alignment: Alignment.centerLeft,
                child: Text(
                  "${MyIcons().padlock} Change password",
                  style: primaryTextstyle(),
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: (){
              Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => SubscriptionsScreen(is_leading: false,)));
            },
            child: Card(
              margin: EdgeInsets.all(8),
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: 50,
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.all(8),
                child: Text(
                  "${MyIcons().subscription} Subscription",
                  style: primaryTextstyle(),
                ),
              ),
            ),
          ),
          Card(
            margin: EdgeInsets.all(8),
            child: Container(
              padding: EdgeInsets.all(8),
              width: MediaQuery.of(context).size.width,
              height: 50,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("${MyIcons().email_icon} Email notifications", style: primaryTextstyle(),),
                  Container(
                    width: 50,
                    height: 50,
                    child: Switch(
                      value: user.email_notif == "on",
                      onChanged: (value) async {
                        if(user.email_notif == ""){
                          await showEmailDialog();
                          if(value){
                            user.email_notif = "on";
                          }
                          else{
                            user.email_notif = "off";
                          }
                          setState(() {

                          });
                          await db_helper.updateAppUserSQLite(user);
                          user.firebase_tokens = temp_user.firebase_tokens;
                          user.last_login = DateTime.now().millisecondsSinceEpoch.toString();
                          await db_helper.updateUser(user);
                        }
                        else{
                          if(value){
                            user.email_notif = "on";
                          }
                          else{
                            user.email_notif = "off";
                          }
                          setState(() {

                          });
                          await db_helper.updateAppUserSQLite(user);
                          user.firebase_tokens = temp_user.firebase_tokens;
                          user.last_login = DateTime.now().millisecondsSinceEpoch.toString();
                          await db_helper.updateUser(user);
                        }

                      },
                    ),
                  )
                ],
              )
            ),
          ),
          Card(
            margin: EdgeInsets.all(8),
            child: Container(
                padding: EdgeInsets.all(8),
                width: MediaQuery.of(context).size.width,
                height: 50,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("${MyIcons().text_bubble} SMS notifications", style: primaryTextstyle(),),
                    Container(
                      width: 50,
                      height: 50,
                      child: Switch(
                        value: user.sms_notif == "on",
                        onChanged: (value) async {
                          bool consent = false;
                          if(user.sms_notif == ""){
                            await showSMSDialog(consent);
                            if(smsDialog.consent && value){
                              user.sms_notif = "on";
                            }
                            else{
                              user.sms_notif = "off";
                            }
                            setState(() {

                            });
                            await db_helper.updateAppUserSQLite(user);
                            user.firebase_tokens = temp_user.firebase_tokens;
                            user.last_login = DateTime.now().millisecondsSinceEpoch.toString();
                            await db_helper.updateUser(user);
                          }
                          else{
                            if(value){
                              user.sms_notif = "on";
                            }
                            else{
                              user.sms_notif = "off";
                            }
                            setState(() {

                            });
                            await db_helper.updateAppUserSQLite(user);
                            user.firebase_tokens = temp_user.firebase_tokens;
                            user.last_login = DateTime.now().millisecondsSinceEpoch.toString();
                            await db_helper.updateUser(user);
                          }
                        },
                      ),
                    )
                  ],
                )
            ),
          ),
          GestureDetector(
            onTap: (){
              showDeleteDialog();
            },
            child: Card(
              margin: EdgeInsets.all(8),
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: 50,
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.all(8),
                child: Text(
                  "${MyIcons().trash} Request account deletion",
                  style: primaryTextstyle(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future sendEmail() async {
    bool is_connected = await checkConnection();
    if(is_connected){
      String basic_auth =
          'Basic ' + base64Encode(utf8.encode('9c568fca2f1a16a5a30fa8782c554ed4:683a79fa6567dc22b5d5327fd1d3d629'));
      String message = "${user.username} is requesting that their account be deleted.\n\nUser email: ${user.email}\nPhone number: ${user.phone_number}.";
      var json = jsonDecode("{}");
      json["Email"] = "support@selectivetrades.com";
      json["Name"] = "SelectiveTradesApp";
      List<dynamic> admin_email_list = [json];

      final params = {
        "FromEmail": "support@selectivetrades.com",
        "FromName": "SelectiveTradesApp",
        "Recipients": admin_email_list,
        "Subject": "Request for account deletion by ${user.username}",
        "Text-part": message
      };
      var url = Uri.parse("https://api.mailjet.com/v3/send");
      var response = await http.post(url, body:jsonEncode(params), headers: {"Authorization":basic_auth,"Content-Type":"application/json"});
    }
    else{
      showToast("No internet connection");
      setState(() {
        is_loading = false;
      });
    }
  }

  Future<void> showDeleteDialog() async {
    Widget okButton = TextButton(
      child: Text("OK"),
      onPressed: () async{
        await Navigator.pop(context);
        await requestDeletion();
      },
    );

    Widget cancelButton = TextButton(
      child: Text("Cancel"),
      onPressed: () async{
        await Navigator.pop(context);
      },
    );

    String store = Platform.isAndroid ? "PlayStore" : "AppStore";

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Info"),
      content: Text("Deleting your account will remove all your data.\nThis action will not cancel your subscription if you have an active one. You can do that from the $store.\n\nDo you want to proceed?"),
      actions: [
        cancelButton,
        Container(width: 10,),
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

  Future<void> showSMSDialog(bool consent) async {

    smsDialog = SMSDialog(consent: consent,);

    Widget okButton = TextButton(
      child: Text("OK"),
      onPressed: () async{
        await Navigator.pop(context);

      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("SMS Consent"),
      content: smsDialog,
      actions: [
        okButton,
      ],
    );
    // show the dialog
    await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  Future<void> showEmailDialog() async {
    Widget okButton = TextButton(
      child: Text("OK"),
      onPressed: () async{
        await Navigator.pop(context);
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Info"),
      content: Text("This will enable you to receive email notifications"),
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

}

class SMSDialog extends StatefulWidget {

  bool consent;

  SMSDialog({this.consent});

  @override
  State<SMSDialog> createState() => _SMSDialogState();
}

class _SMSDialogState extends State<SMSDialog> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: Platform.isAndroid ? 185 : 160,
      child: Column(
        children: [
          Text("By checking this box you agree to receive periodic SMS notifications and updates sent by SelectiveTradesApp admin"),
          CheckboxListTile(
            controlAffinity: ListTileControlAffinity.platform,
            title: Text("I agree to SMS consent"),
            onChanged: (bool value) {
              setState(() {
                widget.consent = value;
              });
            },
            value: widget.consent,
          )
        ],
      ),
    );
  }
}

