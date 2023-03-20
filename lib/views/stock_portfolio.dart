import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
import 'package:selective_chat/adapters/portfolio_adapter.dart';
import 'package:selective_chat/models/app_user.dart';
import 'package:selective_chat/models/portfolio.dart';
import 'package:selective_chat/utils/constants.dart';
import 'package:selective_chat/utils/db_helper.dart';
import 'package:selective_chat/utils/methods.dart';
import 'package:selective_chat/utils/widgets.dart';
import 'package:selective_chat/views/add_portfolio.dart';

class StockPortfolioScreen extends StatefulWidget {

  @override
  _StockPortfolioScreenState createState() => _StockPortfolioScreenState();
}

class _StockPortfolioScreenState extends State<StockPortfolioScreen> {
  bool is_loading = false;
  bool is_searching = false;
  Icon custom_icon = const Icon(Icons.search);
  Widget title_text = const Text("Stock portfolio");

  String symbols = "";

  DbHelper db_helper = new DbHelper();

  List<Portfolio> portfolios = [];
  TextEditingController search_controller = new TextEditingController();
  List<Portfolio> search_list = [];

  @override
  Widget build(BuildContext context) {
    if(is_searching){
      title_text = TextField(
        onTap: (){
          setState(() {
            is_searching = true;
          });
        },
        autofocus: true,
        focusNode: FocusNode(),
        autocorrect: false,
        controller: search_controller,
        onSubmitted: (String value){
          filterPortfolio();
        },
        decoration: InputDecoration(
          hintText: 'Search for symbol',
          hintStyle: TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontFamily: 'aventa_light'
          ),
          border: InputBorder.none,
        ),
        style: TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontFamily: 'aventa_black'
        ),
      );
    }
    else{
      title_text =  Text("Stock portfolio");
    }
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: (){
          Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => AddPortfolioScreen(from: Constants.stock_portfolio, callback: callback,)));
        },
        child: Icon(Icons.add),
      ),
      appBar: AppBar(
        title: title_text,
        actions: [
          searchIcon()
        ],
      ),
      resizeToAvoidBottomInset: false,
      body: is_loading ? loadingPage() : mainPage(),
    );
  }

  void callback(){
    setState(() {
      getPortfolios();
    });
  }

  void filterPortfolio(){
    String search_string = search_controller.text.toString().toLowerCase().trim();
    search_list = [];
    for(var i = 0; i<portfolios.length; i++){
      Portfolio p = portfolios[i];
      if(p.symbol.toLowerCase().contains(search_string)){
        search_list.add(p);
      }
    }

    if(search_list.isNotEmpty){
      setState(() {
        is_searching = true;
      });
    }
    else{
      setState(() {
        is_searching = true;
      });
    }
  }

  Future<void> getPortfolios() async {
    AppUser user = await db_helper.getAppUserSQLite();
    bool is_connected = await checkConnection();
    if(is_connected){
      setState(() {
        is_loading = true;
      });
      portfolios.clear();
      await db_helper.clearPortfolioTable(Constants.stock_portfolio);
      final params = {
        "user": user.email,
        "table": Constants.stock_portfolio
      };
      var url = Uri.https(Constants.server_get_url, '/selective_app/SelectiveTradesApp/getPortfolio.php', params);
      var response = await http.get(url);
      if(response.body != 'failure'){
        try{
          var json = jsonDecode(response.body.toString());
          List<dynamic> portfolio = json;
          for(var i = 0; i<portfolio.length; i++){
            Portfolio p = Portfolio(
                quantity: double.parse(portfolio[i]["quantity"]),
                id: portfolio[i]["id"],
                symbol: portfolio[i]["symbol"],
                buy_price: double.parse(portfolio[i]["buy_price"]),
                buy_date: portfolio[i]["buy_date"]
            );
            portfolios.add(p);
          }
          getQuote();
        }
        catch(e){
          print("crypto_portfolio.getPortfolios error: ${e.toString()}");
          setState(() {
            is_loading = false;
          });
        }
      }
      else{
        setState(() {
          is_loading = false;
        });
        print("crypto_portfolio.getPortfolios: response failure");
      }
    }
  }

  Future<void> getPortfolioSQLite() async {
    setState(() {
      is_loading = true;
    });
    portfolios = await db_helper.getStockPortfolioSQLite();
    portfolios.sort((a, b){
      return a.symbol.compareTo(b.symbol);
    });
    setState(() {
      is_loading = false;
    });
  }

  Future<void> getQuote() async{
    setState(() {
      is_loading = true;
    });
    for(var i = 0; i<portfolios.length; i++){
      try{
        final p = portfolios[i];
        final params = {
          "apikey":Constants.fmp_api_key
        };
        var url = Uri.https('financialmodelingprep.com', '/api/v3/quote/${portfolios[i].symbol}', params);
        var response = await http.get(url);
        if(response.statusCode == 200){
          if(response.body.isNotEmpty){
            var json = jsonDecode(response.body.toString());
            Map<String, dynamic> quote = null;
            String status = "success";
            try{
              quote = json[0];
            }
            catch(e){
              print("stock_portfolio.getQuote error getting request status: ${e.toString()}");
            }
            print("stock_portfolio.getQuote quote response: ${quote.toString()}");
            if(quote == null){
              //showToast("An error occurred");
              p.total_value = 0;
              p.net_change = 0;
              p.net_pct_change = 0;
              p.current_price = 0;
            }
            else{
              var close = quote["previousClose"];
              var net_change = close - p.buy_price;
              double pct_net_change = (net_change / p.buy_price) * 100;
              var total_value = close * p.quantity;

              p.total_value = total_value;
              p.net_change = net_change * p.quantity;
              p.net_change = double.parse(p.net_change.toStringAsFixed(2));
              p.net_pct_change = double.parse(pct_net_change.toStringAsFixed(2));
              p.current_price = close;
            }
            await db_helper.saveStockPortfolioSQLite(p);
            if(i == portfolios.length-1){
              portfolios.sort((a, b){
                return a.symbol.compareTo(b.symbol);
              });
              setState(() {
                is_loading = false;
              });
            }
          }
          else{
            // setState(() {
            //   is_loading = false;
            // });
          }
        }
        else{
          setState(() {
            is_loading = false;
          });
          print("stock_portfolio.getQuote response error: ${response.statusCode}");
        }
      }
      catch(e){
        print("stock_portfolio.getQuote exception: ${e.toString()}");
      }
    }
  }

  @override
  initState(){
    getPortfolioSQLite();
    super.initState();
  }

  Widget mainPage(){
    return RefreshIndicator(
      onRefresh: () async {
        getPortfolios();
      },
      child: Stack(
        children: [
          portfolioValue(),
          Container(
            margin: EdgeInsets.fromLTRB(0, 60, 0, 0),
            child: ListView.builder(
              itemCount: is_searching ? search_list.length : portfolios.length,
              shrinkWrap: false,
              itemBuilder: (context, index){
                Portfolio p = is_searching ? search_list[index] : portfolios[index];
                return PortfolioAdapter(portfolio: p, from: Constants.stock_portfolio, callback: callback,);
              },
            ),
          ),
          portfolios.isEmpty ? noItem("Press '+' to add a symbol pair\n and swipe down to refresh", context) : Container()
        ],
      ),
    );
  }

  Widget portfolioValue(){
    double total = 0;
    double gain_loss = 0;
    for(var i =0; i<portfolios.length; i++){
      total += portfolios[i].total_value;
      gain_loss += portfolios[i].net_change;
    }
    return Container(
        width: MediaQuery.of(context).size.width,
        height: 70,
        margin: EdgeInsets.all(8),
        padding: EdgeInsets.all(5),
        child: Column(
            children: [
              Container(
                child: Text("Portfolio value: \$${total.abs().toStringAsFixed(2)}", style: TextStyle(
                    fontSize: 18,
                    color: Colors.black,
                    fontFamily: 'aventa_black'
                )),
              ),
              Container(height: 3),
              Container(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      child: Text("Gain/Loss: ", style: TextStyle(
                          fontSize: 18,
                          color: Colors.black,
                          fontFamily: 'aventa_black'
                      )),
                    ),
                    Container(
                      child: Text(" \$${gain_loss.abs().toStringAsFixed(2)}", style: TextStyle(
                          fontSize: 18,
                          color: gain_loss > 0 ? Colors.green : Colors.red,
                          fontFamily: 'aventa_black'
                      )),
                    ),
                  ],
                )
              ),
            ]
        )
    );
  }

  void resetSearch(){
    search_controller.text = "";
    setState(() {
      is_searching = false;
    });
  }

  Widget searchIcon(){
    return IconButton(
      onPressed: (){
        is_searching ? resetSearch() : filterPortfolio();
      },
      icon: is_searching ? Icon(Icons.close) : Icon(Icons.search),
    );
  }

}
