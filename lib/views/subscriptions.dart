import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:selective_chat/models/app_user.dart';
import 'package:selective_chat/utils/constants.dart';
import 'package:selective_chat/utils/db_helper.dart';
import 'package:selective_chat/utils/methods.dart';
import 'package:selective_chat/utils/widgets.dart';
import 'package:selective_chat/views/card_page.dart';
import 'package:selective_chat/views/sign_in.dart';
import 'package:selective_chat/views/splash_screen.dart';
import 'package:http/http.dart' as http;

class SubscriptionsScreen extends StatefulWidget {

  bool is_leading = false;

  SubscriptionsScreen({this.is_leading});

  @override
  _SubscriptionsScreenState createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {

  bool is_loading = false;
  bool is_subscribed = false;
  bool is_stripe = false;

  Product product;
  Package package;

  Package tier_1_package;
  Product tier_1;

  Package tier_2_package;
  Product tier_2;

  Package tier_3_package;
  Product tier_3;

  AppUser user;
  bool is_tier1 = false;
  bool is_tier2 = false;
  bool is_tier3 = false;
  DbHelper helper = DbHelper();
  int expiry_date;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          leading: IconButton(
            icon:Icon(Icons.arrow_back),
            onPressed:(){
              widget.is_leading ?
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => SignIn())) : Navigator.pop(context);
            },),
          title: Container(
              child: Text("Subscription")
          )
      ),
      resizeToAvoidBottomInset: false,
      body: is_loading ? loadingPage() : mainPage(),
    );
  }

  Future<void> buyTier1Subscription() async {
    try {
      setState(() {
        is_loading = true;
      });
      UpgradeInfo info;
      // if(user.tier == "tier2" && is_subscribed){
      //   info = UpgradeInfo("futures_49_99", prorationMode: ProrationMode.immediateWithTimeProration);
      // }
      // else if(user.tier == "tier3" && is_subscribed){
      //   info = UpgradeInfo("selectivetradesapp_69_99_all_access", prorationMode: ProrationMode.immediateWithTimeProration);
      // }
      PurchaserInfo purchaserInfo;
      if(info == null){
        purchaserInfo = await Purchases.purchasePackage(package);
      }
      else{
        purchaserInfo = await Purchases.purchasePackage(package, upgradeInfo: info);
      }

      if (purchaserInfo.entitlements.all["selectivetradesapp_25_1m"].isActive) {
        setState(() {
          is_loading = false;
        });
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => SplashScreen()));
      }
      else{
        showToast("Unable to purchase subscription");
        setState(() {
          is_loading = false;
        });
      }
    } catch (e) {
      if(mounted)
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => SplashScreen()));
    }
  }

  Future<void> buyTier2Subscription() async {
    try {
      setState(() {
        is_loading = true;
      });
      UpgradeInfo info;
      // if(user.tier == "tier1" && is_subscribed){
      //   info = UpgradeInfo("selectivetradesapp_25_1m", prorationMode: ProrationMode.immediateWithTimeProration);
      // }
      // else if(user.tier == "tier3" && is_subscribed){
      //   info = UpgradeInfo("selectivetradesapp_69_99_all_access", prorationMode: ProrationMode.immediateWithTimeProration);
      // }

      PurchaserInfo purchaserInfo;
      if(info == null){
        purchaserInfo = await Purchases.purchasePackage(tier_2_package);
      }
      else{
        purchaserInfo = await Purchases.purchasePackage(tier_2_package, upgradeInfo: info);
      }
      if (purchaserInfo.entitlements.all["futures_49_99"].isActive) {
        setState(() {
          is_loading = false;
        });
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => SplashScreen()));
      }
      else{
        showToast("Unable to purchase subscription");
        setState(() {
          is_loading = false;
        });
      }
    } catch (e) {
      if(mounted)
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => SplashScreen()));
    }
  }

  Future<void> buyTier3Subscription() async {
    try {
      setState(() {
        is_loading = true;
      });
      UpgradeInfo info;
      // if(user.tier == "tier1" && is_subscribed){
      //   info = UpgradeInfo("selectivetradesapp_25_1m", prorationMode: ProrationMode.immediateWithTimeProration);
      // }
      // else if(user.tier == "tier2" && is_subscribed){
      //   info = UpgradeInfo("futures_49_99", prorationMode: ProrationMode.immediateWithTimeProration);
      // }

      PurchaserInfo purchaserInfo;
      if(info == null){
        purchaserInfo = await Purchases.purchasePackage(tier_3_package);
      }
      else{
        purchaserInfo = await Purchases.purchasePackage(tier_3_package, upgradeInfo: info);
      }
      if (purchaserInfo.entitlements.all["selectivetradesapp_69_99_all_access"].isActive) {
        setState(() {
          is_loading = false;
        });
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => SplashScreen()));
      }
      else{
        showToast("Unable to purchase subscription");
        setState(() {
          is_loading = false;
        });
      }
    } catch (e) {
      if(mounted)
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => SplashScreen()));
    }
  }

  Future<void> cancelStripeSubscription() async {
    setState(() {
      is_loading = true;
    });

    var sub_id = user.subscription_id;
    final String url = 'https://api.stripe.com/v1/subscriptions/$sub_id';
    print("subscriptions.cancelStripeSubscription url is $url");
    Map<String, String> headers = {
      'Authorization': 'Bearer ${Constants.stripe_secret_key}',
      'Content-Type': 'application/x-www-form-urlencoded'
    };
    var response = await http.delete(
      Uri.parse(url),
      headers: headers,
    );
    if (response.statusCode == 200) {
      var json = jsonDecode(response.body.toString());
      try{
        var status = json["status"];
        if(status == "canceled"){
          setState(() {
            is_loading = false;
          });
          AppUser temp = await helper.getUserByEmail(user.email);
          user.sub_type = "store";
          var firebase_token = user.firebase_tokens;
          user.firebase_tokens = temp.firebase_tokens;
          await helper.updateUser(user);
          user.firebase_tokens = firebase_token;
          await helper.updateAppUserSQLite(user);
          showToast("Stripe subscription cancelled");
        }
        else{
          setState(() {
            is_loading = false;
          });
          showToast("An error occurred, try again");
        }
      }
      catch(e){
        setState(() {
          is_loading = false;
        });
        showToast("An error occurred, try again");
      }
    } else {
      setState(() {
        is_loading = false;
      });
      print("subscriptions.payWithStripe: an error occurred: ${response.body.toString()}");
    }
  }

  String getMessage1(){
    return "You will access the channels below once you buy a subscription.\n\n"
        "Educational\n"
        "     Option Leap Signals\n"
        "     Option Signals\n"
        "     Options - 100k Target\n"
        "     Stock Optional Signals\n"
        "     Breakout Stock Signals\n"
        "     Educational Ideas\n"
        "     News Letter\n"
        "     Results – Optional and Breakout Stocks\n"
        "     Support\n\n"
        "User Defined\n"
        "     Stocks & Crypto Watchlist\n"
        "     Stocks & Crypto Portfolio\n\n"
        "Others\n"
        "     Live Options Tracker\n"
        "     IPO Calendar\n"
        "     Earnings Calendar\n\n"
        "Mobile Notifications\n";
  }

  String getMessage2() {
    return "You will access futures channel and below once you buy a subscription.\n\n"
        "Educational\n"
        "     Futures signals\n"
        "     Stock Optional Signals\n"
        "     Breakout Stock Signals\n"
        "     Educational Ideas\n"
        "     News Letter\n"
        "     Results – Optional and Breakout Stocks\n"
        "     Support\n\n"
        "User Defined\n"
        "     Stocks & Crypto Watchlist\n"
        "     Stocks & Crypto Portfolio\n\n"
        "Others\n"
        "     Live Options Tracker\n"
        "     IPO Calendar\n"
        "     Earnings Calendar\n\n"
        "Mobile Notifications\n";
  }

  String getMessage3() {
    return "You will access all channels below once you buy a subscription.\n\n"
        "Educational\n"
        "     Option Leap Signals\n"
        "     Option Signals\n"
        "     Options - 100k Target\n"
        "     Futures signals\n"
        "     Stock Optional Signals\n"
        "     Breakout Stock Signals\n"
        "     Educational Ideas\n"
        "     News Letter\n"
        "     Results – Optional and Breakout Stocks\n"
        "     Support\n\n"
        "User Defined\n"
        "     Stocks & Crypto Watchlist\n"
        "     Stocks & Crypto Portfolio\n\n"
        "Others\n"
        "     Live Options Tracker\n"
        "     IPO Calendar\n"
        "     Earnings Calendar\n\n"
        "Mobile Notifications\n";
  }

  Future<void> getOfferings() async {
    try{
      setState(() {
        is_loading = true;
      });
      user = await helper.getAppUserSQLite();
      AppUser temp = await helper.getUserByEmail(user.email);
      user.logged_in = "false";
      user.firebase_tokens = temp.firebase_tokens;
      await helper.updateUser(user);
      expiry_date = int.parse(user.expiry_date) + Constants.two_days;
      if(expiry_date > DateTime.now().millisecondsSinceEpoch){
        is_subscribed = true;
        if(user.tier == 'tier1'){
          is_tier1 = true;
        }
        else if(user.tier == "tier2"){
          is_tier2 = true;
        }
        else if(user.tier == "tier3"){
          is_tier3 = true;
        }
      }
      if(user.sub_type != null && user.sub_type != ""){
        if(user.sub_type == "stripe"){
          is_stripe = true;
        }
      }
      Offerings offerings = await Purchases.getOfferings();

      if (offerings.current != null && offerings.current.availablePackages.isNotEmpty) {
        package = offerings.current.monthly;
        product = package.product;

        tier_1_package = offerings.getOffering("default").monthly;
        tier_1 = tier_1_package.product;

        tier_2_package = offerings.getOffering("futures_subscription").monthly;
        tier_2 = tier_2_package.product;
        
        tier_3_package = offerings.getOffering("all_access").monthly;
        tier_3 = tier_3_package.product;

        setState(() {
          is_loading = false;
        });
      }
      else{
        showToast("An error occurred. Contact admin");
        setState(() {
          is_loading = false;
        });
      }
    }
    catch(e){
      print("subscriptions.getOfferings exception ${e.toString()}");
      setState(() {
        is_loading = false;
      });
    }
  }

  @override
  void initState(){
    getOfferings();
    super.initState();
  }

  Widget mainPage(){
    return SingleChildScrollView(
      child: Container(
          margin: EdgeInsets.all(5),
          padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
          width: MediaQuery.of(context).size.width,
          child: Column(
            children: [
              Container(height: 10,),
              subscription3(),
              Container(height: 10,),
              subscription2(),
              Container(height: 10,),
              subscription1(),
              Container(height: 10,),
            ],
          )
      ),
    );
  }

  showAlertDialog(String subscription_tier) {
    Widget okButton = TextButton(
      child: Text("OK"),
      onPressed: () async{
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (context) => CardPage(subcription_tier: subscription_tier,)));
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Info"),
      content: Text("You are about to make purchase a SelectiveTradesApp monthly subscription "
          "with Stripe. Kindly note that your credit or debit card information is "
          "not stored on our servers after this payment and are only used to "
          "process your subscription with Stripe"),
      actions: [
        okButton,
      ],
    );
    // show the dialog
    showDialog(
      barrierDismissible: true,
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  Widget subscription1(){
    return Card(
      elevation: 10,
      color: Colors.white,
      child: Container(
        padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
        child: Column(
          children: [
            Container(
              width: MediaQuery.of(context).size.width,
              alignment: Alignment.center,
              child: Text(
                "Gain options channel access",
                style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontFamily: 'aventa_black'
                ),
              ),
            ),
            Container(height: 5),
            Container(
              child: Text("\$34.99 / month",
                style: TextStyle(
                  decoration: TextDecoration.lineThrough,
                  fontSize: 20,
                  color: Colors.red,
                  fontWeight: FontWeight.normal,
                  fontFamily: 'aventa_black',
                ),
              ),
            ),
            Container(
              child: Text("\$24.99 / month",
                style: TextStyle(
                  fontSize: 30,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'aventa_black',
                ),
              ),
            ),
            Container(height: 5,),
            Container(
                width: MediaQuery.of(context).size.width,
                child: Text(
                  getMessage1(),
                  style: primaryTextstyle(),
                )
            ),
            is_tier1 && is_subscribed ? Container(
                width: MediaQuery.of(context).size.width,
                child: Text(
                  "Your current subscription will auto-renew on ${DateFormat("EEE, MM-dd-yyyy hh:mm:ss").format(DateTime.fromMillisecondsSinceEpoch(expiry_date))}",
                  style: TextStyle(
                      fontSize: 16,
                      color: Colors.green,
                      fontFamily: 'aventa_black'
                  ),
                )
            ) :
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  alignment: Alignment.center,
                  child: MaterialButton(
                    height: 50.0,
                    color: Colors.white,
                    textColor: Colors.green,
                    child: new Text(Platform.isAndroid ? "Pay with\n PlayStore" : "Buy subscription", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'aventa_regular'),),
                    onPressed: () async{
                      await buyTier1Subscription();
                    },
                    splashColor: Theme.of(context).primaryColor,
                  ),
                ),
                Container(width: 25,),
                Platform.isAndroid ? Container(
                  alignment: Alignment.center,
                  child: MaterialButton(
                    color: Colors.white,
                    textColor: Colors.green,
                    child: new Text("Pay with\n Stripe", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'aventa_regular'),),
                    onPressed: () async {
                      showAlertDialog(Constants.subscription_price_id);
                    },
                    splashColor: Theme.of(context).primaryColor,
                  ),
                ) : Container()
              ],
            ),
            Container(height: 10,),
            is_subscribed && is_stripe && is_tier1 ? GestureDetector(
              onTap: () async {
                await cancelStripeSubscription();
              },
              child: Text("Cancel subscription", style: TextStyle(color: Colors.red, fontSize: 16),),
            ) : Container()
          ],
        ),
      ),
    );
  }

  Widget subscription2(){
    return Card(
      elevation: 10,
      color: Colors.white,
      child: Container(
        padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
        child: Column(
          children: [
            Container(
              width: MediaQuery.of(context).size.width,
              alignment: Alignment.center,
              child: Text(
                "Gain futures channel access",
                style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontFamily: 'aventa_black'
                ),
              ),
            ),
            Container(height: 5),
            Container(
              child: Text("\$49.99 / month",
                style: TextStyle(
                  fontSize: 30,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'aventa_black',
                ),
              ),
            ),
            Container(height: 5),
            Container(
                width: MediaQuery.of(context).size.width,
                child: Text(
                  getMessage2(),
                  style: primaryTextstyle(),
                )
            ),
            Container(height: 15,),
            is_tier2 && is_subscribed ? Container(
                width: MediaQuery.of(context).size.width,
                child: Text(
                  "Your current subscription will auto-renew on ${DateFormat("EEE, MM-dd-yyyy hh:mm:ss").format(DateTime.fromMillisecondsSinceEpoch(expiry_date))}",
                  style: TextStyle(
                      fontSize: 16,
                      color: Colors.green,
                      fontFamily: 'aventa_black'
                  ),
                )
            ) :
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  alignment: Alignment.center,
                  child: MaterialButton(
                    height: 50.0,
                    color: Colors.white,
                    textColor: Colors.green,
                    child: new Text(Platform.isAndroid ? "Pay with\n PlayStore" : "Buy subscription", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'aventa_regular'),),
                    onPressed: () async{
                      await buyTier2Subscription();
                    },
                    splashColor: Theme.of(context).primaryColor,
                  ),
                ),
                Container(width: 25,),
                Platform.isAndroid ? Container(
                  alignment: Alignment.center,
                  child: MaterialButton(
                    color: Colors.white,
                    textColor: Colors.green,
                    child: new Text("Pay with\n Stripe", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'aventa_regular'),),
                    onPressed: () async {
                      showAlertDialog(Constants.tier2_subscription_price_id);
                    },
                    splashColor: Theme.of(context).primaryColor,
                  ),
                ) : Container()
              ],
            ),
            Container(height: 10,),
            is_subscribed && is_stripe && is_tier2 ? GestureDetector(
              onTap: () async {
                await cancelStripeSubscription();
              },
              child: Text("Cancel subscription", style: TextStyle(color: Colors.red, fontSize: 16),),
            ) : Container()
          ],
        ),
      ),
    );
  }

  Widget subscription3(){
    return Card(
      elevation: 10,
      color: Colors.white,
      child: Container(
        padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
        child: Column(
          children: [
            Container(
              width: MediaQuery.of(context).size.width,
              alignment: Alignment.center,
              child: Text(
                "Gain all channel access",
                style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontFamily: 'aventa_black'
                ),
              ),
            ),
            Container(height: 5),
            Container(
              child: Text("\$69.99 / month",
                style: TextStyle(
                  fontSize: 30,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'aventa_black',
                ),
              ),
            ),
            Container(height: 5),
            Container(
                width: MediaQuery.of(context).size.width,
                child: Text(
                  getMessage3(),
                  style: primaryTextstyle(),
                )
            ),
            Container(height: 15,),
            is_tier3 && is_subscribed ? Container(
                width: MediaQuery.of(context).size.width,
                child: Text(
                  "Your current subscription will auto-renew on ${DateFormat("EEE, MM-dd-yyyy hh:mm:ss").format(DateTime.fromMillisecondsSinceEpoch(expiry_date))}",
                  style: TextStyle(
                      fontSize: 16,
                      color: Colors.green,
                      fontFamily: 'aventa_black'
                  ),
                )
            ) :
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  alignment: Alignment.center,
                  child: MaterialButton(
                    height: 50.0,
                    color: Colors.white,
                    textColor: Colors.green,
                    child: new Text(Platform.isAndroid ? "Pay with\n PlayStore" : "Buy subscription", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'aventa_regular'),),
                    onPressed: () async{
                      await buyTier3Subscription();
                    },
                    splashColor: Theme.of(context).primaryColor,
                  ),
                ),
                Container(width: 25,),
                Platform.isAndroid ? Container(
                  alignment: Alignment.center,
                  child: MaterialButton(
                    color: Colors.white,
                    textColor: Colors.green,
                    child: new Text("Pay with\n Stripe", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'aventa_regular'),),
                    onPressed: () async {
                      showAlertDialog(Constants.all_access_price_id);
                    },
                    splashColor: Theme.of(context).primaryColor,
                  ),
                ) : Container()
              ],
            ),
            Container(height: 10,),
            is_subscribed && is_stripe && is_tier3 ? GestureDetector(
              onTap: () async {
                await cancelStripeSubscription();
              },
              child: Text("Cancel subscription", style: TextStyle(color: Colors.red, fontSize: 16),),
            ) : Container()
          ],
        ),
      ),
    );
  }

}
