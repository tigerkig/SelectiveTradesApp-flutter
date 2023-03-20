import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:selective_chat/models/app_user.dart';
import 'package:selective_chat/models/channel.dart';
import 'package:selective_chat/utils/constants.dart';
import 'package:selective_chat/utils/db_helper.dart';
import 'package:selective_chat/utils/methods.dart';
import 'package:selective_chat/views/channel_screen.dart';
import 'package:selective_chat/views/notification_result_screen.dart';
import 'package:selective_chat/views/notifications_screen.dart';
import 'package:selective_chat/views/sign_in.dart';
import 'package:http/http.dart' as http;

class SplashScreen extends StatefulWidget {

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  DbHelper db_helper = new DbHelper();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      alignment: Alignment.bottomCenter,
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/images/logo.jpeg', width:150, height:150),
          Container(height: 8,),
          CircularProgressIndicator()
        ],
      ),
    );
  }

  Future<void> checkLoggedIn() async{
    bool is_connected = await checkConnection();
    if(is_connected){
      AppUser user = await db_helper.getAppUserSQLite();
      if(user != null){
        AppUser u = await db_helper.getUserByEmail(user.email, user_hash: user.hash);

        if(Platform.isAndroid){
          if(user.app_version_android != Constants.android_app_version){
            String message = "${u.username} changed their app version from ${u.app_version_android} "
                "to ${Constants.android_app_version}. \nRunning on android device: ${u.device}";
            u.logged_in = "false";
            u.app_version_ios = Platform.isIOS ? Constants.ios_app_version : "";
            u.app_version_android = Platform.isAndroid ? Constants.android_app_version : "";
            u.device = "";
            await db_helper.updateUser(u);
            await db_helper.updateAppUserSQLite(u);
            await sendAdminEmail(message, u.username);
            setState(() {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => SignIn()));
            });
          }
        }
        else if(Platform.isIOS){
          if(user.app_version_ios != Constants.ios_app_version){
            String message = "${u.username} changed their app version from ${u.app_version_android} "
                "to ${Constants.android_app_version}. \nRunning on android device: ${u.device}";
            u.logged_in = "false";
            u.app_version_ios = Platform.isIOS ? Constants.ios_app_version : "";
            u.app_version_android = Platform.isAndroid ? Constants.android_app_version : "";
            u.device = "";
            await db_helper.updateUser(u);
            await db_helper.updateAppUserSQLite(u);
            await sendAdminEmail(message, u.username);
            setState(() {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => SignIn()));
            });
          }
        }

        if(user.logged_in == "false"){
          u.logged_in = "false";
          u.ip_address = await getLocationByIp();
          u.app_version_ios = Platform.isIOS ? Constants.ios_app_version : "";
          u.app_version_android = Platform.isAndroid ? Constants.android_app_version : "";
          u.device = "";
          await db_helper.updateUser(u);
          setState(() {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => SignIn()));
          });
        }
        else{
          int expiry = int.parse(u.expiry_date) + Constants.two_days;
          if(expiry > DateTime.now().millisecondsSinceEpoch){
            u.logged_in = "true";
            u.ip_address = await getLocationByIp();
            u.app_version_ios = Platform.isIOS ? Constants.ios_app_version : "";
            u.app_version_android = Platform.isAndroid ? Constants.android_app_version : "";

            DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
            if(Platform.isAndroid){
              AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
              u.device = androidInfo.manufacturer.toLowerCase() + " " + androidInfo.model.toLowerCase();
            }
            else if(Platform.isIOS){
              IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
              u.device = iosInfo.utsname.machine.toLowerCase() + " " + iosInfo.model.toLowerCase();
            }

            String last_login = DateTime.now().millisecondsSinceEpoch.toString();
            u.last_login = last_login;
            await db_helper.updateAppUserSQLite(u);
            await db_helper.updateUser(u);
            if(u.active == "false"){
              showToast("Your account has been deactivated. Contact admin");
              setState(() {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => SignIn()));
              });
            }
            else{
              Channel channel = Channel(channel_name: "Notifications - Results");
              setState(() {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => NotificationResultScreen(
                  channel: channel
                )));
              });
            }
          }
          else{
            u.logged_in = "false";
            u.ip_address = await getLocationByIp();
            u.app_version_ios = Platform.isIOS ? Constants.ios_app_version : "";
            u.app_version_android = Platform.isAndroid ? Constants.android_app_version : "";
            u.device = "";

            DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
            if(Platform.isAndroid){
              AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
              u.device = androidInfo.manufacturer.toLowerCase() + " " + androidInfo.model.toLowerCase();
            }
            else if(Platform.isIOS){
              IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
              u.device = iosInfo.utsname.machine.toLowerCase() + " " + iosInfo.model.toLowerCase();
            }
            await db_helper.updateAppUserSQLite(u);
            await db_helper.updateUser(u);
            Channel channel = Channel(channel_name: "Notifications - Results");
            setState(() {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => NotificationResultScreen(channel: channel,)));
            });
          }
        }

      }
      else{
        setState(() {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => SignIn()));
        });
      }
    }
    else{

    }
  }

  @override
  void initState() {
    super.initState();
    try{
      checkLoggedIn();
    }
    catch(e){
      showToast("splash_screen.initState error ${e.toString()}");
    }
  }

  Future<void> sendAdminEmail(String message, String username) async {
    final params = {
      "message": message,
      "user": username,
    };
    var url = Uri.https(Constants.server_get_url,'/selective_app/SelectiveTradesApp/contactSupport.php', params);
    var response = await http.get(url);
    print("support.sendMessage response ${response.body.toString()}");
  }

}
