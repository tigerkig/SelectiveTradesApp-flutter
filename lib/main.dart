import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:last_state/last_state.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:selective_chat/locator.dart';
import 'package:selective_chat/utils/constants.dart';
import 'package:selective_chat/utils/methods.dart';
import 'package:selective_chat/utils/push_notification_service.dart';
import 'package:selective_chat/views/channel_messages.dart';
import 'package:selective_chat/views/forgot_password.dart';
import 'package:selective_chat/views/home_screen.dart';
import 'package:selective_chat/views/splash_screen.dart';
import 'package:upgrader/upgrader.dart';

PushNotificationService notif = locator<PushNotificationService>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = new MyHttpOverrides();
  await Firebase.initializeApp();
  setupLocator();
  Stripe.publishableKey = Constants.stripe_publishable_key;
  await notif.initialise();
  await SavedLastStateData.init();
  await Upgrader.clearSavedSettings();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {

  @override
  _MyAppState createState() => _MyAppState();

}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver{

  StreamSubscription connection_stream_subscription;

  AppLifecycleState notification;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if(notification == AppLifecycleState.detached){

    }
    else if(notification == AppLifecycleState.inactive){

    }
    else if(notification == AppLifecycleState.paused){

    }
    else if(notification == AppLifecycleState.resumed){

    }

  }

  Future<void> initPlatformState() async {
    await Purchases.setDebugLogsEnabled(false);
    await Purchases.setup(Constants.revenuecat_public_key);
  }

  @override
  initState() {
    connection_stream_subscription = Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if(result == ConnectivityResult.none){
        //showToast("Lost internet connection");  
      }
    });
    checkConnection();
    initPlatformState();
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  dispose() {
    connection_stream_subscription.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool is_android = Platform.isAndroid;
    return MaterialApp(
      navigatorKey: GlobalVariable.navState,
      theme: ThemeData(
          primarySwatch: Colors.blue,
          fontFamily: 'aventa_regular'
      ),
      navigatorObservers: [SavedLastStateData.instance.navigationObserver],
      routes: {
        "forgot_password": (context) => ForgotPassword(),
        "splash_screen": (context) => SplashScreen(),
        "home_screen": (context) => HomeScreen(),
        "channel_messages": (context) => ChannelMessages()
      },
      debugShowCheckedModeBanner: false,
      initialRoute: SavedLastStateData.instance.lastRoute ?? "splash_screen",
      home: SplashScreen(),
    );
  }
}

/// Global variables
/// * [GlobalKey<NavigatorState>]
class GlobalVariable {

  /// This global key is used in material app for navigation through firebase notifications.
  /// [navState] usage can be found in [notification_notifier.dart] file.
  static final GlobalKey<NavigatorState> navState = GlobalKey<NavigatorState>();
}

class MyHttpOverrides extends HttpOverrides{
  @override
  HttpClient createHttpClient(SecurityContext context){
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port)=> true;
  }
}

