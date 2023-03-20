import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:selective_chat/models/portfolio.dart';
import 'package:selective_chat/utils/constants.dart';
import 'package:selective_chat/utils/db_helper.dart';
import 'package:selective_chat/utils/methods.dart';
import 'package:selective_chat/utils/my_icons.dart';
import 'package:selective_chat/utils/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:selective_chat/views/add_portfolio.dart';

class PortfolioAdapter extends StatefulWidget {

  Portfolio portfolio;
  String from;
  Function callback;
  PortfolioAdapter({this.portfolio, this.from, this.callback});

  @override
  State<PortfolioAdapter> createState() => _PortfolioAdapterState();

}

class _PortfolioAdapterState extends State<PortfolioAdapter> {

  DbHelper db_helper = DbHelper();

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      direction: DismissDirection.endToStart,
      background: Container(
        width: MediaQuery.of(context).size.width,
        color: Colors.red,
        alignment: Alignment.center,
        child: Text(
          "Deleted",
          style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontFamily: 'aventa_black'
          ),
        ),
      ),
      key: UniqueKey(),
      onDismissed: (direction) async{
        await deletePortfolio();
      },
      child: Container(
        margin: EdgeInsets.all(5),
        padding: EdgeInsets.all(5),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(5)),
            color: Colors.black12
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            GestureDetector(
              onTap: (){
                showEditingDialog(context);
              },
              child: Padding(
                child: Icon(Icons.more_horiz, color: Colors.black,),
                padding: EdgeInsets.fromLTRB(10, 2.5, 10, 2.5),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${widget.portfolio.symbol}",
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black
                  ),
                ),
                Text(
                  "Buy price: ${widget.portfolio.buy_price.toStringAsFixed(2)} USD   ",
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.black
                  ),
                )
              ],
            ),
            Container(
                height: 5
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Qty: ${widget.portfolio.quantity} \n(${widget.portfolio.buy_date})",
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.black
                  ),
                ),
                Text(
                  "Live price: ${widget.portfolio.current_price} USD   ",
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.black
                  ),
                )
              ],
            ),
            Container(
                height: 5
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "% Change : ${widget.portfolio.net_pct_change}%",
                  style: TextStyle(
                      fontSize: 14,
                      color: widget.portfolio.net_pct_change < 0 ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold
                  ),
                ),
                Text(
                  "Net change: ${widget.portfolio.net_change}   ",
                  style: TextStyle(
                      fontSize: 14,
                      color: widget.portfolio.net_change < 0 ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> deletePortfolio() async {
    final params = {
      "id": widget.portfolio.id,
      "table": widget.from
    };
    var url = Uri.parse('${Constants.server_url}/selective_app/SelectiveTradesApp/deletePortfolio.php');
    var response = await http.post(url, body: params);
    if(response.body != "failure"){
      await db_helper.deletePortfolio(widget.portfolio, widget.from);
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
            Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => AddPortfolioScreen(from: widget.from,
              portfolio: widget.portfolio,callback: widget.callback,)));
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

