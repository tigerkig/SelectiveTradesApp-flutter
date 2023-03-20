import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:selective_chat/utils/my_icons.dart';
import 'package:selective_chat/utils/widgets.dart';
import 'package:selective_chat/views/crypto_watchlist.dart';
import 'package:selective_chat/views/stock_watchlist.dart';

class SelectWatchlistScreen extends StatefulWidget {

  @override
  _SelectWatchlistScreenState createState() => _SelectWatchlistScreenState();
}

class _SelectWatchlistScreenState extends State<SelectWatchlistScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          title: Container(
              alignment: Alignment.centerLeft,
              width: MediaQuery.of(context).size.width,
              child: Text("SelectiveTrades")
          )
      ),
      resizeToAvoidBottomInset: false,
      body: mainPage(),
    );
  }

  Widget mainPage(){
    return Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: Column(
          children: [
            option("${MyIcons().green_check} Crypto watchlist", onClickCryptoWatchlist),
            option("${MyIcons().green_check} Stock watchlist", onClickStockWatchlist),
          ],
        )
    );
  }

  void onClickCryptoWatchlist(){
    Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => CryptoWatchlistScreen()));
  }

  void onClickStockWatchlist(){
    Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => StockWatchlistScreen()));
  }

  Widget option(String title, VoidCallback function){
    return GestureDetector(
      onTap: function,
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: 50,
        padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
        margin: EdgeInsets.fromLTRB(5, 5, 5, 5),
        decoration: BoxDecoration(
          color: Colors.blueGrey.shade100,
          borderRadius: BorderRadius.circular(8)
        ),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: primaryTextstyle(),
              ),
            ]
        ),
      ),
    );
  }
}
