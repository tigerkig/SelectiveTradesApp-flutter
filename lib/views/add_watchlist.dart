import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:selective_chat/models/app_user.dart';
import 'package:selective_chat/models/watchlist.dart';
import 'package:selective_chat/utils/constants.dart';
import 'package:selective_chat/utils/db_helper.dart';
import 'package:selective_chat/utils/methods.dart';
import 'package:selective_chat/utils/widgets.dart';
import 'package:selective_chat/views/select_symbol.dart';
import 'package:http/http.dart' as http;

class AddWatchlistScreen extends StatefulWidget {

  String from;
  Function callback;
  Watchlist watchlist;

  AddWatchlistScreen({this.from, this.callback, this.watchlist});

  @override
  _AddWatchlistScreenState createState() => _AddWatchlistScreenState();
}

class _AddWatchlistScreenState extends State<AddWatchlistScreen> {

  bool is_loading = false;

  final form_key = GlobalKey<FormState>();

  TextEditingController symbol_controller = new TextEditingController();
  TextEditingController price_controller = new TextEditingController();
  TextEditingController date_controller = new TextEditingController();

  DateTime buy_date = DateTime.now();

  AppUser user;
  DbHelper db_helper = new DbHelper();

  Future<void> addWatchlist() async{
    bool is_connect = await checkConnection();
    if(form_key.currentState.validate() && is_connect){
      setState(() {
        is_loading = true;
      });

      String buy_date;
      if(date_controller.text.isEmpty){
        buy_date = DateFormat(Constants.date_format).format(DateTime.now());
      }
      else{
        buy_date = DateFormat(Constants.date_format).format(this.buy_date);
      }

      if(price_controller.text.isEmpty){
        await getPrice();
      }

      Watchlist watchlist = Watchlist(
          symbol: symbol_controller.text.toString(),
          buy_price: double.parse(price_controller.text.toString()),
          buy_date: buy_date
      );

      user = await db_helper.getAppUserSQLite();

      final params = {
        "symbol": watchlist.symbol,
        "user": user.email,
        "buy_price": watchlist.buy_price.toString(),
        "buy_date": watchlist.buy_date,
        "table": widget.from
      };
      try{
        var url = Uri.parse("${Constants.server_url}/selective_app/SelectiveTradesApp/addWatchlist.php",);
        var response = await http.post(url, body: params);
        if(response.statusCode == 200){
          if(response.body == "success"){
            setState(() {
              is_loading = false;
              Navigator.pop(context);
              widget.callback();
            });
          }
          else{
            setState(() {
              is_loading = false;
              showToast("Unable to add watchlist");
            });
          }
        }
        else{
          setState(() {
            is_loading = false;
          });
          print("add_watchlist.AddWatchlist: Error response code ${response.statusCode}");
          showToast("An unknown error occurred, try again");
        }
      }
      catch(e){
        setState(() {
          is_loading = false;
        });
        print("add_watchlist.addWatchlist exception ${e.toString()}");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.watchlist == null ? "Add new watchlist" : "Edit watchlist"),
      ),
      resizeToAvoidBottomInset: false,
      body: is_loading ? loadingPage() : mainPage(),
    );
  }

  Future<void> deleteWatchlist() async {
    final params = {
      "id": widget.watchlist.id,
      "table": widget.from
    };
    print("add_watchlist.deleteWatchlist params: ${params.toString()}");
    var url = Uri.parse('${Constants.server_url}/selective_app/SelectiveTradesApp/deleteWatchlist.php');
    var response = await http.post(url, body: params);
    if(response.body != "failure"){
      await db_helper.deleteWatchlist(widget.watchlist, widget.from);
    }
    else{
      showToast("Unable to delete");
    }
  }

  Future<void> getPrice() async {
    print("add_watchlist.getPrice running ");
    final params = {
      "symbol": symbol_controller.text.toString(),
      "apikey":Constants.twelvedata_api_key
    };
    var url = Uri.https('api.twelvedata.com', '/quote', params);
    var response = await http.get(url);
    if(response.statusCode == 200){
      if(response.body.isNotEmpty){
        print("addWatchlist.getPrice response: ${response.body.toString()}");
        var json = jsonDecode(response.body.toString());
        Map<String, dynamic> quote = json;
        String status = "success";
        try{
          status = quote["status"];
        }
        catch(e){
          print("add_watchlist.getPrice error getting request status ${e.toString()}");
        }

        if(status == "error"){
          print("add_watchlist.getPrice: request status is an error");
        }
        else{
          var close = quote["close"];
          price_controller.text = close.toString();
        }
      }
    }
    else{
      print("add_watchlist.getPrice response error: ${response.statusCode}");
    }
  }

  Future<void> init() async {
    if(widget.watchlist != null){
      symbol_controller.text = widget.watchlist.symbol;
      price_controller.text = widget.watchlist.buy_price.toString();
      date_controller.text = widget.watchlist.buy_date;
    }
    setState(() {

    });
  }

  @override
  void initState(){
    super.initState();
    init();
  }

  Widget mainPage(){
    return Form(
      key: form_key,
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.all(5),
              padding: EdgeInsets.all(8),
              child: TextFormField(
                validator: (v){
                  return symbol_controller.text.isNotEmpty ? null : "Required";
                },
                onTap: () async{
                  String result = await Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => SelectSymbol(from: widget.from,)));
                  setState(() {
                    symbol_controller.text = result;
                    getPrice();
                  });
                },
                readOnly: true,
                style: primaryTextstyle(),
                controller: symbol_controller,
                decoration: InputDecoration(
                    labelStyle: secondaryTextStyle(),
                    labelText: "Symbol",
                    border: OutlineInputBorder()
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.all(5),
              padding: EdgeInsets.all(8),
              child: TextFormField(
                style: primaryTextstyle(),
                controller: price_controller,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                    labelStyle: secondaryTextStyle(),
                    labelText: "Price",
                    border: OutlineInputBorder()
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.all(5),
              padding: EdgeInsets.all(8),
              child: TextFormField(
                onTap: () async{
                  buy_date = await showDate(context);
                  if(buy_date != null){
                    date_controller.text = DateFormat(Constants.date_format).format(buy_date);
                  }
                },
                readOnly: true,
                style: primaryTextstyle(),
                controller: date_controller,
                decoration: InputDecoration(
                    labelStyle: secondaryTextStyle(),
                    labelText: "Date",
                    border: OutlineInputBorder()
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.all(8),
              width: MediaQuery.of(context).size.width,
              alignment: Alignment.center,
              child: MaterialButton(
                height: 50.0,
                minWidth: 150.0,
                color: Colors.white,
                textColor: Colors.green,
                child: new Text(widget.watchlist == null ? "Add" : "Save", style: TextStyle(fontSize: 16, fontFamily: 'aventa_regular'),),
                onPressed: () async{
                  if(widget.watchlist == null){

                  }
                  else{
                    await deleteWatchlist();
                  }
                  await addWatchlist();
                },
                splashColor: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

}

