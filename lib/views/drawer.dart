import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:selective_chat/models/app_user.dart';
import 'package:selective_chat/utils/db_helper.dart';
import 'package:selective_chat/utils/methods.dart';
import 'package:selective_chat/utils/my_icons.dart';
import 'package:selective_chat/utils/widgets.dart';
import 'package:selective_chat/views/channel_screen.dart';
import 'package:selective_chat/views/crypto_chart_screen.dart';
import 'package:selective_chat/views/frequently_asked_questions.dart';
import 'package:selective_chat/views/general_chat.dart';
import 'package:selective_chat/views/notifications_screen.dart';
import 'package:selective_chat/views/stock_charts_screen.dart';
import 'package:selective_chat/views/crypto_portfolio.dart';
import 'package:selective_chat/views/crypto_watchlist.dart';
import 'package:selective_chat/views/earnings_calendar.dart';
import 'package:selective_chat/views/ipo_calendar.dart';
import 'package:selective_chat/views/live_options.dart';
import 'package:selective_chat/views/select_calendars.dart';
import 'package:selective_chat/views/select_portfolio.dart';
import 'package:selective_chat/views/select_watchlist.dart';
import 'package:selective_chat/views/settings.dart';
import 'package:selective_chat/views/sign_in.dart';
import 'package:selective_chat/views/stock_portfolio.dart';
import 'package:selective_chat/views/stock_watchlist.dart';
import 'package:selective_chat/views/support.dart';
import 'package:selective_chat/views/terms_and_conditions.dart';
import 'package:selective_chat/views/write_testimonial.dart';
import 'package:share_plus/share_plus.dart';

class DrawerLayout extends StatefulWidget{

  BuildContext context;
  DrawerLayout({this.context});

  @override
  _DrawerLayoutState createState() => _DrawerLayoutState();

}

class _DrawerLayoutState extends State<DrawerLayout> {

  bool is_loading = false;
  AppUser user;
  DbHelper db_helper = new DbHelper();

  String ios_app_link = "https://apps.apple.com/us/app/selectivetradesapp/id1593216934#?platform=iphone";
  String android_app_link = "https://play.google.com/store/apps/details?id=com.selectivetradesapp";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          title: Container(
              alignment: Alignment.centerLeft,
              width: MediaQuery.of(context).size.width,
              child: Text("Menu")
          )
      ),
      resizeToAvoidBottomInset: false,
      body: is_loading ? loadingPage() : mainPage(),
    );
  }

  Future<void> init() async{
    setState(() {
      is_loading = true;
    });
    user = await db_helper.getAppUserSQLite();
    setState(() {
      is_loading = false;
    });
  }

  @override
  void initState(){
    init();
    super.initState();
  }

  Widget mainPage(){
    return SingleChildScrollView(
      child: Container(
          width: MediaQuery.of(context).size.width,
          margin: EdgeInsets.all(10),
          child: Column(
            children: [
              option("General chat", onClickChat),
              option("Live options", onClickLiveOption),
              option("Stock watchlist", onClickStockWatchlist),
              option("Crypto watchlist", onClickCryptoWatchlist),
              option("Indices watchlist", onClickIndicesWatchlist),
              option("Sector watchlist", onClickSectorWatchlist),
              option("Stock portfolio", onClickStockPortfolio),
              option("Crypto portfolio", onClickCryptoPortfolio),
              option("Stock charts", onClickStockChart),
              option("Crypto charts", onClickCryptoChart),
              option("Terms and conditions", onClickTermsAndConditions),
              option("Write testimonial", onClickTestimonial),
              option("Forward to friends", onClickShare),
              option("Settings", onClickSettings),
              option("Contact support", onClickSupport),
              option("FAQs", onClickFAQs),
              option("Sign out", signOut),
              Container(
                alignment: Alignment.centerLeft,
                width: MediaQuery.of(context).size.width,
                height: 50,
                padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
                margin: EdgeInsets.fromLTRB(5, 5, 60, 5),
                child: Text(
                  "User ID: ${user.email}",
                  style: primaryTextstyle(),
                ),
              ),
            ],
          )
      ),
    );
  }

  Widget notificationOption(){
    return GestureDetector(
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: 50,
        padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
        margin: EdgeInsets.fromLTRB(5, 5, 5, 5),
        decoration: BoxDecoration(
            color: Colors.blueGrey.shade100,
            borderRadius: BorderRadius.circular(8)
        ),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${MyIcons().notification_bell} Notifications",
                style: primaryTextstyle(),
              ),
              ClipOval(
                child: Container(
                  color: Colors.red,
                  padding: EdgeInsets.symmetric(horizontal: 5),
                  child: Text(
                    "3",
                    style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontFamily: 'aventa_black'
                    ),
                  ),
                ),
              )
            ]
        ),
      ),
    );
  }

  void onClickChannels(){
    Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext context) => ChannelScreen()));
  }

  void onClickChat(){
    Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => GeneralChat()));
  }

  void onClickCryptoChart(){
    Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => CryptoChartScreen()));
  }

  void onClickCryptoPortfolio(){
    Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => CryptoPortfolioScreen()));
  }

  void onClickCryptoWatchlist(){
    Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => CryptoWatchlistScreen()));
  }

  void onClickIndicesWatchlist(){
    showToast("In development");
  }

  void onClickSectorWatchlist(){
    showToast("In development");
  }

  void onClickEarningsCalendar() {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (BuildContext context) => EarningsCalendarScreen()));
  }

  void onClickIPOCalendar(){
    Navigator.of(context).push(MaterialPageRoute(
        builder: (BuildContext context) => IPOCalendarScreen()));
  }

  void onClickLiveOption(){
    Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => LiveOptionsScreen()));
  }

  void onClickStockPortfolio(){
    Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => StockPortfolioScreen()));
  }

  void onClickStockWatchlist(){
    Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => StockWatchlistScreen()));
  }

  void onClickSettings() {
    Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext context) => SettingsScreen()));
  }

  void onClickShare() async {
    await Share.share('Selective trades provides stock and option signals for educational purpose and below are the app information to register\nIOS: ${ios_app_link}\nAndroid: ${android_app_link}', subject: 'Download Selective trades app');
  }

  void onClickStockChart(){
    Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => StockChartScreen()));
  }

  void onClickSupport(){
    Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => ContactSupportScreen()));
  }

  void onClickFAQs(){
    Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => FrequentlyAskedQuestions()));
  }

  void onClickTermsAndConditions(){
    Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => TermsAndConditions()));
  }

  void onClickTestimonial(){
    Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => WriteTestimonial()));
  }

  void onClickWatchlist(){
    Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext context) => SelectWatchlistScreen()));
  }

  Widget option(String title,VoidCallback function){
    return GestureDetector(
      onTap:function,
      child:Container(
        alignment: Alignment.centerLeft,
        width: MediaQuery.of(context).size.width,
        height: 50,
        padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
        margin: EdgeInsets.fromLTRB(5, 5, 60, 5),
        decoration: BoxDecoration(
            color: Colors.blueGrey.shade100,
            borderRadius: BorderRadius.circular(8)
        ),
        child: Text(
          title,
          style: primaryTextstyle(),
        ),
      ),
    );
  }

  Widget showOptionDialog(BuildContext context, String text){
    Dialog dialog = Dialog(
      child: Container(
          padding: EdgeInsets.all(15),
          child: Text(
            text,
          )
      ),
    );
    showDialog(context: context, builder: (BuildContext context) => dialog);
  }

  Future<void> signOut() async {
    setState(() {
      is_loading = true;
    });
    try{
      await FirebaseAuth.instance.signOut();
      LogInResult result = await Purchases.logIn(this.user.hash);
      if(result != null){
        await Purchases.logOut();
      }
      AppUser user = await db_helper.getUserByEmail(this.user.email);
      List<String> to_upload = [];

      if(user.firebase_tokens != null && user.firebase_tokens != ""){
        final firebase_json = jsonDecode(user.firebase_tokens);

        List<dynamic> l = firebase_json["firebase_tokens"];

        if(l.contains(this.user.firebase_tokens)){
          l.remove(this.user.firebase_tokens);
        }

        // for(var i = 0; i<l.length; i++){
        //   to_upload.add('"${l[i]}"');
        // }
      }

      var firebase_json_ = jsonDecode("{}");
      firebase_json_['"firebase_tokens"'] = to_upload;
      user.firebase_tokens = firebase_json_.toString();
      user.logged_in = "false";
      user.device = "";
      user.ip_address = "";
      await db_helper.updateUser(user);
      await db_helper.deleteDatabase();
      setState(() {
        is_loading = false;
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => SignIn()));
      });
    }
    catch(e){
      print("drawer.signOut exception ${e.toString()}");
      showToast("Error occurred: ${e.toString()}");
      setState(() {
        is_loading = false;
      });
    }
  }
}
