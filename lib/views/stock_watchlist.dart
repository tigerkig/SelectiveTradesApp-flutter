import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:selective_chat/adapters/watchlist_adapter.dart';
import 'package:selective_chat/models/app_user.dart';
import 'package:selective_chat/models/watchlist.dart';
import 'package:selective_chat/utils/constants.dart';
import 'package:selective_chat/utils/db_helper.dart';
import 'package:selective_chat/utils/methods.dart';
import 'package:selective_chat/utils/widgets.dart';
import 'package:selective_chat/views/add_watchlist.dart';
import 'package:web_socket_channel/io.dart';

class StockWatchlistScreen extends StatefulWidget {

  @override
  _StockWatchlistScreenState createState() => _StockWatchlistScreenState();

}

class _StockWatchlistScreenState extends State<StockWatchlistScreen> {
  bool is_loading = false;
  bool is_searching = false;
  Icon custom_icon = const Icon(Icons.search);
  Widget title_text = const Text("Stock watchlist");

  String symbols = "";

  DbHelper db_helper = new DbHelper();

  List<Watchlist> watchlists = [];
  TextEditingController search_controller = new TextEditingController();
  List<Watchlist> search_list = [];

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
          filterWatchlist();
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
      title_text =  Text("Stock watchlist");
    }

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: (){
          Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => AddWatchlistScreen(from: Constants.stock_watchlist, callback: callback,)));
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
      getWatchlists();
    });
  }

  void filterWatchlist(){
    String search_string = search_controller.text.toString().toLowerCase().trim();
    search_list = [];
    for(var i = 0; i<watchlists.length; i++){
      Watchlist w = watchlists[i];
      if(w.symbol.toLowerCase().contains(search_string)){
        search_list.add(w);
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

  @override
  initState(){
    getWatchlistSQLite();
    super.initState();
  }

  Future<void> getWatchlists() async {
    AppUser user = await db_helper.getAppUserSQLite();
    bool is_connected = await checkConnection();
    if(is_connected){
      setState(() {
        is_loading = true;
      });
      watchlists.clear();
      await db_helper.clearWatchlistTable(Constants.stock_watchlist);
      final params = {
        "user": user.email,
        "table": Constants.stock_watchlist
      };
      var url = Uri.https(Constants.server_get_url, '/selective_app/SelectiveTradesApp/getWatchlists.php', params);
      var response = await http.get(url);
      if(response.body != 'failure'){
        try{
          var json = jsonDecode(response.body.toString());
          List<dynamic> watchlist = json;
          for(var i = 0; i<watchlist.length; i++){
            Watchlist w = Watchlist(
                id: watchlist[i]["id"],
                symbol: watchlist[i]["symbol"],
                buy_price: double.parse(watchlist[i]["buy_price"]),
                buy_date: watchlist[i]["buy_date"]
            );
            watchlists.add(w);
          }
          getQuote();
        }
        catch(e){
          print("stock_watchlist.getWatchlists error: ${e.toString()}");
          setState(() {
            is_loading = false;
          });
        }
      }
      else{
        setState(() {
          is_loading = false;
        });
        print("stock_watchlist.getWatchlists: response failure");
      }
    }
  }

  Future<void> getWatchlistSQLite() async {
    setState(() {
      is_loading = true;
    });
    watchlists = await db_helper.getStockWatchlistSQLite();
    watchlists.sort((a, b){
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
    for(var i = 0; i<watchlists.length; i++){
      try{
        final w = watchlists[i];
        final params = {
          "apikey":Constants.fmp_api_key
        };
        var url = Uri.https('financialmodelingprep.com', '/api/v3/quote/${watchlists[i].symbol}', params);
        var response = await http.get(url);
        if(response.statusCode == 200){
          if(response.body.isNotEmpty){
            var json = jsonDecode(response.body.toString());
            //print("stock_watchlist.getQuote json response: ${json.toString()}");
            Map<String, dynamic> quote = null;
            String status = "success";
            try{
              quote = json[0];
            }
            catch(e){
              print("stock_watchlist.getQuote error getting request status: ${e.toString()}");
            }
            print("stock_watchlist.getQuote quote response: ${quote.toString()}");
            if(quote == null){
              //showToast("An error occurred");
              w.net_change = 0;
              w.net_pct_change = 0;
              w.live_price = 0;
              w.pct_change_24hr = 0;
              w.price_change_24hr = 0;
            }
            else{
              var price_change_24hr = quote["change"];
              var pct_change_24hr = quote["changesPercentage"];
              var close = quote["previousClose"];
              var net_change = close - w.buy_price;
              var pct_net_change = (net_change / w.buy_price) * 100;

              w.net_change = net_change;
              w.net_pct_change = pct_net_change;
              w.live_price = close;
              w.pct_change_24hr = pct_change_24hr;
              w.price_change_24hr = price_change_24hr;
            }

            await db_helper.saveStockWatchlistSQLite(w);

            if(i == watchlists.length-1){
              watchlists.sort((a, b){
                return a.symbol.compareTo(b.symbol);
              });
              setState(() {
                is_loading = false;
              });
            }
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

  Widget mainPage(){
    return RefreshIndicator(
      onRefresh: () async {
        getWatchlists();
      },
      child: Stack(
        children: [
          ListView.builder(
            itemCount: is_searching ? search_list.length : watchlists.length,
            shrinkWrap: false,
            itemBuilder: (context, index){
              Watchlist w = is_searching ? search_list[index] : watchlists[index];
              return WatchlistAdapter(watchlist: w, from: Constants.stock_watchlist, callback: callback,);
            },
          ),
          watchlists.isEmpty ? noItem("Press '+' to add a stock symbol\n and swipe down to refresh", context) : Container()
        ],
      ),
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
        is_searching ? resetSearch() : filterWatchlist();
      },
      icon: is_searching ? Icon(Icons.close) : Icon(Icons.search),
    );
  }
}
