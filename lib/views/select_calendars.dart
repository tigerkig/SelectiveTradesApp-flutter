import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:selective_chat/utils/my_icons.dart';
import 'package:selective_chat/utils/widgets.dart';
import 'package:selective_chat/views/earnings_calendar.dart';
import 'package:selective_chat/views/ipo_calendar.dart';

class SelectCalendars extends StatefulWidget {

  @override
  _SelectCalendarsState createState() => _SelectCalendarsState();
}

class _SelectCalendarsState extends State<SelectCalendars> {
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
      body: mainPage(),
    );
  }

  Widget mainPage(){
    return Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: Column(
          children: [
            option("${MyIcons().green_check} Earnings calendar", onClickEarningsCalendar),
            option("${MyIcons().green_check} IPO calendar", onClickIPOCalendar),
          ],
        )
    );
  }

  void onClickEarningsCalendar(){
    Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => EarningsCalendarScreen()));
  }

  void onClickIPOCalendar(){
    Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => IPOCalendarScreen()));
  }

  Widget option(String title, VoidCallback function){
    return GestureDetector(
      onTap: function,
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
            ]
        ),
      ),
    );
  }
}
