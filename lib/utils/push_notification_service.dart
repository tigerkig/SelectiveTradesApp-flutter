import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:selective_chat/models/channel.dart';
import 'package:selective_chat/models/notification_to_display.dart';
import 'package:selective_chat/utils/db_helper.dart';

DbHelper db_helper = new DbHelper();

class PushNotificationService with WidgetsBindingObserver {

  BuildContext context;
  FirebaseMessaging fcm;
  bool is_background = true;
  FlutterLocalNotificationsPlugin notif_plugin;

  Function callback;

  PushNotificationService({this.context});

  Future<void> initialise() async {
    this.context = context;
    this.callback = callback;
    fcm = FirebaseMessaging.instance;

    await fcm.requestPermission(alert: true,
      announcement: true,
      badge: true,
      carPlay: false,
      criticalAlert: true,
      provisional: false,
      sound: true,);
    await fcm.setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: true);

    var android_init = new AndroidInitializationSettings("logo");
    var ios_init = new IOSInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
    );
    var init_settings = new InitializationSettings(
        android: android_init, iOS: ios_init
    );
    notif_plugin = new FlutterLocalNotificationsPlugin();
    notif_plugin.initialize(init_settings);

    fcm.getInitialMessage().then((value){
      RemoteMessage m = value;
      if(m != null){
        String screen = m.data['screen'];
        String channel = m.data['channel'];
        print("push_notification_service.initialise remote message data: screen = $screen, channel = $channel");
        Channel c = Channel(channel_name: channel);
      }
      else{
        print("push_notification_service.initialise remote message is null");
      }
    });

    FirebaseMessaging.onMessage.listen((event) async {
      if(event != null){
        String screen = event.data['screen'];
        String channel = event.data['channel'];
        String message = event.data['message'];
        String title = event.data['title'];
        String timestamp = event.data['timestamp'];
        String attachment = event.data['attachment'];

        NotificationToDisplay n = NotificationToDisplay(
          title: title,
          screen: screen,
          channel: channel,
          message: message,
          timestamp: timestamp,
        );

        if(channel == "Option Signals"){
          await db_helper.saveNotificationToDisplay(n);
        }
        else if(channel == "Option Leap Signals"){
          await db_helper.saveNotificationToDisplay(n);
        }
        else if(channel == "Options - 100k Target"){
          await db_helper.saveNotificationToDisplay(n);
        }
        //await db_helper.saveNotificationToDisplay(n);
      }
      else{
        print("push_notification_service.initialise notification event is null");
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((event) async {
      if(event != null){
        String screen = event.data['screen'];
        String channel = event.data['channel'];
        String message = event.data['message'];
        String title = event.data['title'];
        String body = event.data['body'];
        String timestamp = event.data['timestamp'];

        NotificationToDisplay n = NotificationToDisplay(
          screen: screen,
          channel: channel,
          message: message,
          title: title,
          timestamp: timestamp
        );
        print("push_notification_service.initialise saving notif to display title $title and message $message body $body");
        //await db_helper.saveNotificationToDisplay(n);
      }
    });
  }

  void setIsBackground(bool val){
    is_background = val;
  }

  void showNotification(String title, String message) async{
    print("push_notification_service: attempting to show notification");
    var android_details = new AndroidNotificationDetails("channelId", "Local notifications", importance: Importance.max,
        priority: Priority.high, playSound: true);
    var ios_details = new IOSNotificationDetails();
    var general_notif_details = new NotificationDetails(android: android_details, iOS: ios_details);
    await notif_plugin.show(0, title, message, general_notif_details);
  }
}