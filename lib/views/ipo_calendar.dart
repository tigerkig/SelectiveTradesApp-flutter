import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:selective_chat/adapters/ipo_calendar_adapter.dart';
import 'package:selective_chat/models/ipo_calendar.dart';
import 'package:selective_chat/utils/constants.dart';
import 'package:http/http.dart' as http;
import 'package:selective_chat/utils/db_helper.dart';
import 'package:selective_chat/utils/methods.dart';
import 'package:selective_chat/utils/widgets.dart';

class IPOCalendarScreen extends StatefulWidget {

  @override
  _IPOCalendarScreenState createState() => _IPOCalendarScreenState();
}

class _IPOCalendarScreenState extends State<IPOCalendarScreen> {

  bool is_loading = false;

  String selected_date;

  List<IPOCalendar> calendars = [];
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
              await db_helper.deleteIPOCalendar(selected_date);
              await getIPOCalendar();
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
          child: Text("IPO calendar")
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
      date_in_long += 86400000;
      String d = DateFormat("yyyy-MM-dd").format(DateTime.fromMillisecondsSinceEpoch(date_in_long));
      date_list.add(d);
      DropdownMenuItem item = DropdownMenuItem(value: d,child: Text(d, style: primaryTextstyle(),));
      drop_down_list.add(item);
    }
    selected_date = date_list[0];
    print("ipo_calendar.getDateList date_list: ${selected_date.toString()}");
    return date_list;
  }

  Future<void> getIPOCalendar() async {
    bool is_connected = await checkConnection();
    if(is_connected){
      setState(() {
        is_loading = true;
      });
      final params = {
        "apikey": Constants.twelvedata_api_key,
      };
      var url = Uri.https('api.twelvedata.com', '/ipo_calendar', params);
      var response = await http.get(url);
      if(response.statusCode == 200){
        if(response.body.isNotEmpty){
          try{
            var json = jsonDecode(response.body.toString());
            Map<String, dynamic> quote = json;
            String status = "success";
            try{
              status = quote["status"];
            }
            catch(e){
              print("ipo_calendar.getIPOCalendar error getting request status: ${e.toString()}");
            }
            if(status == "error"){
              setState(() {
                is_loading = false;
                showToast("An error occurred");
              });
            }
            else{
              calendars.clear();
              List<dynamic> ipo = quote[selected_date];
              for(var i = 0; i<ipo.length; i++){
                Map<String, dynamic> calendar = ipo[i];
                String symbol = calendar["symbol"];
                String name = calendar["name"];
                num price_range_low = calendar["price_range_low"];
                num price_range_high = calendar["price_range_high"];
                num offer_price = calendar["offer_price"];
                String currency = calendar["currency"];
                num shares = calendar["shares"];
                IPOCalendar c = IPOCalendar(
                    id: DateTime.now().millisecondsSinceEpoch,
                    symbol: symbol,
                    name: name,
                    price_range_low: price_range_low,
                    price_range_high: price_range_high,
                    offer_price: offer_price,
                    currency: currency,
                    shares: shares,
                    date: selected_date
                );
                await db_helper.saveIPOCalendar(c);
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
            print("ipo_calendar.getIPOCalendar exception: ${e.toString()}");
            setState(() {
              is_loading = false;
            });
          }
        }
      }
      else{
        print("ipo_calendar.getIPOCalendar response code error");
        setState(() {
          is_loading = false;
        });
      }
    }
  }

  Future<void> getIPOCalendarSQLite() async {
    setState(() {
      is_loading = true;
    });
    calendars = await db_helper.getIPOCalendar(selected_date);
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
    getIPOCalendarSQLite();
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
                          calendars = await db_helper.getIPOCalendar(selected_date);
                          if(calendars.isEmpty){
                            setState(() {
                              getIPOCalendar();
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
                    IPOCalendar c = calendars[index];
                    return IPOCalendarAdapter(calendar: c);
                  },
                ),
                calendars.isEmpty ? noItem("Looks like there are no IPOs today", context) : Container()
              ],
            ),
          )
        ],
      ),
    );
  }

}
