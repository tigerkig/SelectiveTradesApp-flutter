import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:selective_chat/utils/methods.dart';
import 'package:selective_chat/utils/my_icons.dart';
import 'package:selective_chat/utils/widgets.dart';
import 'package:selective_chat/views/channel_screen.dart';
import 'package:selective_chat/views/ipo_calendar.dart';
import 'package:selective_chat/views/select_calendars.dart';
import 'package:selective_chat/views/select_portfolio.dart';
import 'package:selective_chat/views/select_watchlist.dart';
import 'package:selective_chat/views/settings.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  bool is_loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          title: Container(
              alignment: Alignment.centerLeft,
              width: MediaQuery.of(context).size.width,
              child: Text("SelectiveTrades")
          )
      ),
      resizeToAvoidBottomInset: false,
      body: is_loading ? loadingPage() : mainPage(),
    );
  }

  Widget loadingPage(){

  }

  void onClickCalendars(){
    Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext context) => SelectCalendars()));
  }

  void onclickChannels(){
    Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext context) => ChannelScreen()));
  }

  void onClick(){

  }

  void onClickPortfolio() {
    Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext context) => SelectPortfolioScreen()));
  }

  void onClickSettings() {
    Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext context) => SettingsScreen()));
  }

  void onClickWatchlist(){
    Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext context) => SelectWatchlistScreen()));
  }

  Widget mainPage(){
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: Column(
        children: [
          option("${MyIcons().green_check} Channels", "Lorem ipsum dolor sit amet, consectetur adipiscing elit,"
              " sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, "
              "quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat."
              " Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat n", onclickChannels),
          option("${MyIcons().green_check} Calendars", "Lorem ipsum dolor sit amet, consectetur adipiscing elit,"
              " sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, "
              "quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat."
              " Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat n", onClickCalendars),
          option("${MyIcons().green_check} Live options", "Lorem ipsum dolor sit amet, consectetur adipiscing elit,"
              " sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam,"
              " quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. "
              "Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat", onClick),
          option("${MyIcons().green_check} Portfolios", "Lorem ipsum dolor sit amet, consectetur adipiscing elit,"
              " sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam,"
              " quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. "
              "Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat", onClickPortfolio),
          option("${MyIcons().green_check} Watchlists", "Lorem ipsum dolor sit amet, consectetur adipiscing elit,"
              " sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam,"
              " quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. "
              "Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat", onClickWatchlist),
          notificationOption(),
          option("${MyIcons().wrench_icon} Settings and support", "", onClickSettings)
        ],
      )
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
                    "99",
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

  Widget option(String title, String description, VoidCallback function){
    return GestureDetector(
      onTap:function,
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
              title,
              style: primaryTextstyle(),
            ),
            GestureDetector(
              onTap: (){
                showOptionDialog(context, description);
              },
              child: Container(
                child: Text(
                  description.isEmpty ?
                  "" :
                  "${MyIcons().text_bubble}"
                ),
              ),
            )
          ]
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
}
