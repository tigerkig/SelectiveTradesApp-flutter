import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:selective_chat/adapters/watchlist_adapter.dart';
import 'package:selective_chat/models/app_user.dart';
import 'package:selective_chat/models/watchlist.dart';
import 'package:selective_chat/utils/constants.dart';
import 'package:selective_chat/utils/db_helper.dart';
import 'package:selective_chat/utils/methods.dart';
import 'package:selective_chat/utils/widgets.dart';
import 'package:selective_chat/views/add_watchlist.dart';

class CryptoWatchlistScreen extends StatefulWidget {

  @override
  _CryptoWatchlistScreenState createState() => _CryptoWatchlistScreenState();

}

class _CryptoWatchlistScreenState extends State<CryptoWatchlistScreen> {

  bool is_loading = false;
  bool is_searching = false;
  Icon custom_icon = const Icon(Icons.search);
  Widget title_text = const Text("Crypto watchlist");

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
      title_text =  Text("Crypto watchlist");
    }
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: (){
          Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => AddWatchlistScreen(from: Constants.crypto_watchlist, callback: callback,)));
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

    print("select_symbol.filterSymbols search list length : ${search_list.length}");
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
              return WatchlistAdapter(watchlist: w, from: Constants.crypto_watchlist, callback: callback,);
            },
          ),
          watchlists.isEmpty ? noItem("Press '+' to add a crypto pair\n and swipe down to refresh", context) : Container()
        ],
      ),
    );
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
        List<String> s = watchlists[i].symbol.split("/");
        var url = Uri.https('financialmodelingprep.com', '/api/v3/quote/${s[0]}${s[1]}', params);
        var response = await http.get(url);
        if(response.statusCode == 200){
          if(response.body.isNotEmpty){
            var json = jsonDecode(response.body.toString());
            //print("crypto_watchlist.getQuote json response: ${json.toString()}");
            Map<String, dynamic> quote = null;
            String status = "success";
            try{
              quote = json[0];
            }
            catch(e){
              print("crypto_watchlist.getQuote error getting request status: ${e.toString()}");
            }
            print("crypto_watchlist.getQuote quote response: ${quote.toString()}");
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
              var close = quote["price"];
              var net_change = close - w.buy_price;
              var pct_net_change = (net_change / w.buy_price) * 100;

              w.net_change = net_change;
              w.net_pct_change = pct_net_change;
              w.live_price = close;
              w.pct_change_24hr = pct_change_24hr;
              w.price_change_24hr = price_change_24hr;
            }

            await db_helper.saveCryptoWatchlistSQLite(w);

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
          print("crypto_portfolio.getQuote response error: ${response.statusCode}");
        }
      }
      catch(e){
        print("crypto_portfolio.getQuote exception: ${e.toString()}");
      }

    }
  }

  Future<void> getWatchlists() async {
    AppUser user = await db_helper.getAppUserSQLite();
    bool is_connected = await checkConnection();
    if(is_connected){
      setState(() {
        is_loading = true;
      });
      watchlists.clear();
      await db_helper.clearWatchlistTable(Constants.crypto_watchlist);
      final params = {
        "user": user.email,
        "table": Constants.crypto_watchlist
      };
      try{
        var url = Uri.https(Constants.server_get_url, '/selective_app/SelectiveTradesApp/getWatchlists.php', params);
        var response = await http.get(url);

        if(response.body != 'failure'){
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
        else{
          setState(() {
            is_loading = false;
          });
          print("stock_watchlist.getWatchlists: response ${response.body}");
        }
      }
      catch(e){
        print("stock_watchlist.getWatchlists error: ${e.toString()}");
        setState(() {
          is_loading = false;
        });
      }
    }
  }

  Future<void> getWatchlistSQLite() async {
    setState(() {
      is_loading = true;
    });
    watchlists = await db_helper.getCryptoWatchlistSQLite();
    watchlists.sort((a, b){
      return a.symbol.compareTo(b.symbol);
    });
    setState(() {
      is_loading = false;
    });
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
