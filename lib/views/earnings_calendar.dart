import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:selective_chat/adapters/earnings_calendar_adapter.dart';
import 'package:selective_chat/models/earnings_calendar.dart';
import 'package:selective_chat/utils/constants.dart';
import 'package:selective_chat/utils/db_helper.dart';
import 'package:selective_chat/utils/methods.dart';
import 'package:selective_chat/utils/widgets.dart';
import 'package:http/http.dart' as http;

class EarningsCalendarScreen extends StatefulWidget {

  @override
  _EarningsCalendarScreenState createState() => _EarningsCalendarScreenState();
}

class _EarningsCalendarScreenState extends State<EarningsCalendarScreen> {

  bool is_loading = false;

  String selected_date;

  List<EarningsCalendar> calendars = [];
  List<String> date_list = [];
  List<DropdownMenuItem<dynamic>> drop_down_list = [];

  DbHelper db_helper = DbHelper();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          actions: [
            GestureDetector(
              onTap: () async{
                await db_helper.deleteEarningsCalendar(selected_date);
                await getEarningsCalendar();
              },
              child: Container(
                margin: EdgeInsets.fromLTRB(0, 0, 10, 0),
                child: Icon(Icons.refresh),
              ),
            )
          ],
          title: Container(
              alignment: Alignment.centerLeft,
              width: MediaQuery.of(context).size.width,
              child: Text("Earnings calendar")
          )
      ),
      resizeToAvoidBottomInset: false,
      body: is_loading ? loadingPage() : mainPage(),
    );
  }

  List<String> getDateList() {
    List<String> date_list = [];
    DateTime date = DateTime.now();
    int date_in_long = date.millisecondsSinceEpoch;
    for(var i = 0; i<=7; i++){
      String d = DateFormat("yyyy-MM-dd").format(DateTime.fromMillisecondsSinceEpoch(date_in_long));
      date_list.add(d);
      DropdownMenuItem item = DropdownMenuItem(value: d,child: Text(d, style: primaryTextstyle(),));
      drop_down_list.add(item);
      date_in_long += 86400000;
    }
    selected_date = date_list[0];
    print("earnings_calendar.getDateList date_list: ${selected_date.toString()}");
    return date_list;
  }

  Future<void> getEarningsCalendar() async {
    bool is_connected = await checkConnection();
    if(is_connected){
      setState(() {
        is_loading = true;
      });
      final params = {
        "apikey": Constants.twelvedata_api_key,
      };
      var url = Uri.https('api.twelvedata.com', '/earnings_calendar', params);
      var response = await http.get(url);
      if(response.statusCode == 200){
        if(response.body.isNotEmpty){
          try{
            //print("earnings_calendar.getEarningCalendar response ${response.body}");
            var json = jsonDecode(response.body.toString());
            Map<String, dynamic> quote = json;
            String status = "success";
            try{
              status = quote["status"];
            }
            catch(e){
              print("earnings_calendar.getEarningsCalendar error getting request status: ${e.toString()}");
            }
            if(status == "error"){
              setState(() {
                is_loading = false;
                showToast("An error occurred");
              });
            }
            else{
              calendars.clear();
              Map<String, dynamic> earnings = quote["earnings"];
              List<dynamic> earning = earnings[selected_date];

              for(var i = 0; i<earning.length; i++){
                Map<String, dynamic> calendar = earning[i];
                String symbol = calendar["symbol"];
                String name = calendar["name"];
                double eps_estimate = calendar["eps_estimate"];
                double eps_actual = calendar["eps_actual"];
                double difference = calendar["difference"];
                String currency = calendar["currency"];
                double surprise_pct = calendar["surprise_pct"];
                EarningsCalendar c = EarningsCalendar(
                    symbol: symbol,
                    name: name,
                    eps_estimate: eps_estimate,
                    eps_actual: eps_actual,
                    difference: difference,
                    currency: currency,
                    surprise_pct: surprise_pct,
                    date: selected_date
                );
                await db_helper.saveEarningsCalendar(c);
                calendars.add(c);
              }
              calendars.sort((a,b){
                return a.compareTo(b);
              });
              setState(() {
                is_loading = false;
              });
            }
          }
          catch(e){
            print("earnings_calendar.getEarningsCalendar exception: ${e.toString()}");
            setState(() {
              is_loading = false;
            });
          }
        }
      }
      else{
        print("earnings_calendar.getEarningsCalendar response code error");
        setState(() {
          is_loading = false;
        });
      }
    }
  }

  Future<void> getEarningsCalendarSQLite() async {
    setState(() {
      is_loading = true;
    });
    calendars = await db_helper.getEarningsCalendar(selected_date);
    calendars.sort((a,b){
      return a.compareTo(b);
    });
    setState(() {
      is_loading = false;
    });
  }

  @override
  void initState(){
    date_list = getDateList();
    getEarningsCalendarSQLite();
    super.initState();
  }

  Widget mainPage(){
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: Column(
        children: [
          Container(
            width: MediaQuery.of(context).size.width,
            height: 50,
            color: Colors.grey,
            child: Row(
              children: [
                Container(
                    margin: EdgeInsets.fromLTRB(25, 15, 0, 0),
                    child: Row(
                        children: [
                          Text(
                            "Date: ",
                            style: primaryTextstyle(),
                          ),
                          DropdownButton(
                            items: drop_down_list,
                            value: selected_date,
                            underline: Container(
                              height: 2,
                              color: Colors.black,
                            ),
                            icon: Icon(Icons.arrow_downward),
                            iconSize: 18,
                            elevation:16,
                            style: primaryTextstyle(),
                            onChanged: (value) async{
                              selected_date = value.toString();
                              calendars = await db_helper.getEarningsCalendar(selected_date);
                              if(calendars.isEmpty){
                                setState(() {
                                  getEarningsCalendar();
                                });
                              }
                              else{
                                setState(() {

                                });
                              }
                            },
                          )
                        ]
                    )
                ),
              ],
            ),
          ),
          Container(height: 5,),
          Expanded(
            child: Stack(
              children: [
                ListView.builder(
                  itemCount: calendars.length,
                  shrinkWrap: true,
                  itemBuilder: (context, index){
                    EarningsCalendar c = calendars[index];
                    return EarningsCalendarAdapter(calendar: c);
                  },
                ),
                calendars.isEmpty ? noItem("Looks like there are no earnings today", context) : Container()
              ],
            ),
          )
        ],
      ),
    );
  }
}