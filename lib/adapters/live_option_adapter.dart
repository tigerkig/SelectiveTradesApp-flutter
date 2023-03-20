import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:selective_chat/models/live_option.dart';
import 'package:selective_chat/utils/db_helper.dart';
import 'package:selective_chat/utils/widgets.dart';

class LiveOptionAdapter extends StatelessWidget {

  LiveOption option;
  DbHelper db_helper = DbHelper();

  LiveOptionAdapter({this.option});

  @override
  Widget build(BuildContext context) {
    var pct_change = double.parse(option.pct_change);
    String channel = option.channel;
    if(channel == null)
      channel = "";
    double font_size = 12;
    if(channel.length > 20){
      font_size = 12;
    }
    return Container(
      color: Colors.black12,
      width: MediaQuery
          .of(context)
          .size
          .width,
      margin: EdgeInsets.all(8),
      padding: EdgeInsets.all(5),
      child: Container(
        child: Column(
            children: [
              Container(
                margin: EdgeInsets.fromLTRB(0, 7, 0, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      margin: EdgeInsets.fromLTRB(0, 0, 0, 0),
                      width: 200,
                      child: Text(
                        option.tracker,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: font_size, color: Colors.black),
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.fromLTRB(10, 0, 0, 0),
                      child: Text(
                        option.live_price,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black),
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.fromLTRB(10, 0, 0, 0),
                      child: Text(
                        option.pct_change,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: pct_change < 0 ? Colors.red : Colors.green),
                      ),
                    ),
                  ],
                ),
              ),
              Container(height: 5,),
              Container(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        child: Text(
                          DateFormat("yyyy/MM/dd").format(DateTime.fromMillisecondsSinceEpoch(int.parse(option.timestamp))),
                          style: primaryTextstyle(),
                        ),
                      ),
                      Container(
                        child: Image.asset(
                          option.status == "close" ? "assets/images/alarm.png" : "assets/images/thumb_up.png",
                          height: 20,
                          width: 20,
                        ),
                      ),
                      Container(
                        child: Text(
                            channel == "" ? "" : channel,
                            style: TextStyle(
                                fontSize: font_size,
                                color: Colors.black,
                                fontFamily: 'aventa_black'
                            )
                        ),
                      ),
                    ],
                  )

              ),
            ]
        ),
      ),
    );
  }

}
