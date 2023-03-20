import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:selective_chat/models/app_user.dart';
import 'package:selective_chat/models/portfolio.dart';
import 'package:selective_chat/utils/constants.dart';
import 'package:selective_chat/utils/db_helper.dart';
import 'package:selective_chat/utils/methods.dart';
import 'package:selective_chat/utils/widgets.dart';
import 'package:selective_chat/views/select_symbol.dart';

class AddPortfolioScreen extends StatefulWidget {

  String from;
  Function callback;
  Portfolio portfolio;
  AddPortfolioScreen({this.from, this.callback, this.portfolio});

  @override
  _AddPortfolioScreenState createState() => _AddPortfolioScreenState();

}

class _AddPortfolioScreenState extends State<AddPortfolioScreen> {

  bool is_loading = false;

  final form_key = GlobalKey<FormState>();

  TextEditingController symbol_controller = new TextEditingController();
  TextEditingController price_controller = new TextEditingController();
  TextEditingController date_controller = new TextEditingController();
  TextEditingController quantity_controller = new TextEditingController();

  DateTime buy_date = DateTime.now();

  AppUser user;
  DbHelper db_helper = new DbHelper();

  Future<void> addPortfolio() async {
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
      if(quantity_controller.text.isEmpty){
        quantity_controller.text = "1";
      }

      Portfolio portfolio = Portfolio(
          symbol: symbol_controller.text.toString(),
          buy_price: double.parse(price_controller.text.toString()),
          buy_date: buy_date,
          quantity: double.parse(quantity_controller.text.toString())
      );

      user = await db_helper.getAppUserSQLite();

      final params = {
        "symbol": portfolio.symbol,
        "user": user.email,
        "buy_price": portfolio.buy_price.toString(),
        "buy_date": portfolio.buy_date,
        "quantity": portfolio.quantity.toString(),
        "table": widget.from
      };
      print("add_portfolio.addPortfolio params ${params.toString()}");
      try{
        var url = Uri.parse("${Constants.server_url}/selective_app/SelectiveTradesApp/addPortfolio.php");
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
              print("add_portfolio.addPortfolio response ${response.body}");
              showToast("Unable to add portfolio");
            });
          }
        }
        else{
          setState(() {
            is_loading = false;
          });
          print("add_portfolio.AddPortfolio: Error response code ${response.statusCode}");
          showToast("An unknown error occurred, try again");
        }
      }
      catch(e){
        setState(() {
          is_loading = false;
        });
        print("add_portfolio.addPortfolio exception ${e.toString()}");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print("add_portfolio.build from ${widget.from}");
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.portfolio == null ? "Add new portfolio" : "Edit portfolio"),
      ),
      resizeToAvoidBottomInset: false,
      body: is_loading ? loadingPage() : mainPage(),
    );
  }

  Future<void> deletePortfolio() async {
    final params = {
      "id": widget.portfolio.id,
      "table": widget.from
    };
    print("add_portfolio.deletePortfolio params: ${params.toString()}");
    var url = Uri.parse('${Constants.server_url}/selective_app/SelectiveTradesApp/deletePortfolio.php');
    var response = await http.post(url, body: params);
    if(response.body != "failure"){
      print("add_portfolio.deletePortfolio response: ${response.body.toString()}");
      await db_helper.deletePortfolio(widget.portfolio, widget.from);
    }
    else{
    }
  }

  Future<void> getPrice() async {
    final params = {
      "symbol": symbol_controller.text.toString(),
      "apikey":Constants.twelvedata_api_key
    };
    var url = Uri.https('api.twelvedata.com', '/quote', params);
    var response = await http.get(url);
    if(response.statusCode == 200){
      if(response.body.isNotEmpty){
        var json = jsonDecode(response.body.toString());
        Map<String, dynamic> quote = json;
        String status = "success";
        try{
          status = quote["status"];
        }
        catch(e){
          print("add_portfolio.getPrice error getting request status ${e.toString()}");
        }

        if(status == "error"){
          print("add_portfolio.getPrice: request status is an error");
        }
        else{
          var close = quote["close"];
          price_controller.text = close.toString();
        }
      }
    }
    else{
      print("add_portfolio.getPrice response error: ${response.statusCode}");
    }
  }

  Future<void> init() async {
    if(widget.portfolio != null){
      symbol_controller.text = widget.portfolio.symbol;
      price_controller.text = widget.portfolio.buy_price.toString();
      quantity_controller.text = widget.portfolio.quantity.toString();
      date_controller.text = widget.portfolio.buy_date.toString();
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
                    labelText: "Buy price",
                    border: OutlineInputBorder()
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.all(5),
              padding: EdgeInsets.all(8),
              child: TextFormField(
                style: primaryTextstyle(),
                controller: quantity_controller,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                    labelStyle: secondaryTextStyle(),
                    labelText: "Quantity",
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
                child: new Text(widget.portfolio == null ? "Add" : "Save", style: TextStyle(fontSize: 16, fontFamily: 'aventa_regular'),),
                onPressed: () async{
                  if(widget.portfolio == null){

                  }
                  else{
                    await deletePortfolio();
                  }
                  await addPortfolio();
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
