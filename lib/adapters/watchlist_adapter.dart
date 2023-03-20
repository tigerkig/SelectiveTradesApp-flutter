import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:selective_chat/models/watchlist.dart';
import 'package:selective_chat/utils/constants.dart';
import 'package:selective_chat/utils/db_helper.dart';
import 'package:selective_chat/utils/methods.dart';
import 'package:http/http.dart' as http;
import 'package:selective_chat/utils/widgets.dart';
import 'package:selective_chat/views/add_watchlist.dart';

class WatchlistAdapter extends StatelessWidget {

  Watchlist watchlist;
  String from;
  Function callback;
  WatchlistAdapter({this.from, this.watchlist, this.callback});

  DbHelper db_helper = DbHelper();

  @override
  Widget build(BuildContext context) {
    bool is_24hr_pct_positive = watchlist.pct_change_24hr > 0;
    bool is_net_change_positive = watchlist.net_change > 0;
    return Dismissible(
      direction: DismissDirection.endToStart,
      background: Container(
        width: MediaQuery.of(context).size.width,
        color: Colors.red,
        alignment: Alignment.center,
        child: Text(
          "Item deleted",
          style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontFamily: 'aventa_black'
          ),
        ),
      ),
      key: Key(watchlist.id),
      onDismissed: (direction) async {
        deleteWatchlist();
      },
      child: Container(
          decoration: BoxDecoration(
              color: Colors.lightBlue,
              borderRadius: BorderRadius.all(Radius.circular(10))
          ),
          margin: EdgeInsets.all(10),
          child: Row(
              children: [
                Container(
                  margin: EdgeInsets.fromLTRB(5, 0, 0, 0),
                  width: MediaQuery.of(context).size.width - 130,
                  height: Platform.isIOS ? 65 : 55,
                  color: Colors.black,
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Container(
                        width: 100,
                        margin: EdgeInsets.fromLTRB(0, 5, 0, 5),
                        alignment: Alignment.centerLeft,
                        child: Center(
                          child: Column(
                              children: [
                                Text(
                                    "${watchlist.symbol.toUpperCase()}",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold
                                    )
                                ),
                                Text(
                                    watchlist.buy_date == "null" ? " ": watchlist.buy_date,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    )
                                ),
                              ]
                          ),
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.fromLTRB(50, 5, 0, 5),
                        alignment: Alignment.center,
                        child: Column(
                            children: [
                              Text(
                                  watchlist.buy_price.toStringAsFixed(2),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  )
                              ),
                              Text(is_net_change_positive ? "+"+watchlist.net_change.toStringAsFixed(2) :
                                  watchlist.net_change.toStringAsFixed(2),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  )
                              ),
                            ]
                        ),
                      )
                    ],
                  ),
                ),
                Container(
                  margin: EdgeInsets.all(5),
                  width: 90,
                  height: Platform.isIOS ? 65 : 55,
                  alignment: Alignment.center,
                  color: is_24hr_pct_positive ? Colors.green : Colors.red,
                  child: Container(
                    margin: EdgeInsets.fromLTRB(0, 5, 0, 0),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(width: 1,),
                        Column(
                          children: [
                            Text(
                                watchlist.live_price.toStringAsFixed(2),
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold
                                )
                            ),
                            Text(is_24hr_pct_positive ? "+"+watchlist.pct_change_24hr.toStringAsFixed(2)+"%" :
                            watchlist.pct_change_24hr.toStringAsFixed(2)+"%",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold
                                )
                            )
                          ],
                        ),
                        GestureDetector(
                          onTap: (){
                            showEditingDialog(context);
                          },
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                            child: Icon(Icons.more_horiz, color: Colors.white,)
                          ),
                        ),
                      ],
                    )
                  ),
                ),
              ]
          )
      ),
    );
  }

  Future<void> deleteWatchlist() async {
    final params = {
      "id": watchlist.id,
      "table": from
    };
    var url = Uri.parse('${Constants.server_url}/selective_app/SelectiveTradesApp/deleteWatchlist.php');
    var response = await http.post(url, body: params);
    if(response.body != "failure"){
        await db_helper.deleteWatchlist(watchlist, from);
    }
    else{
      showToast("Unable to delete");
    }
  }

  showEditingDialog(BuildContext context) {
    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      content: GestureDetector(
          onTap: () async {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => AddWatchlistScreen(from: from,callback: callback,watchlist: watchlist,)));
          },
          child: Container(
              alignment: Alignment.centerLeft,
              width: 300,
              height: 20,
              child: Text("Edit                                    ", style: secondaryTextStyle(),)
          )
      ),
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

}
