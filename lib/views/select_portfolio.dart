import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:selective_chat/utils/my_icons.dart';
import 'package:selective_chat/utils/widgets.dart';
import 'package:selective_chat/views/crypto_portfolio.dart';
import 'package:selective_chat/views/stock_portfolio.dart';

class SelectPortfolioScreen extends StatefulWidget {

  @override
  _SelectPortfolioScreenState createState() => _SelectPortfolioScreenState();
}

class _SelectPortfolioScreenState extends State<SelectPortfolioScreen> {
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
            option("${MyIcons().green_check} Crypto portfolio", onClickCryptoPortfolio),
            option("${MyIcons().green_check} Stock portfolio", onClickStockPortfolio),
          ],
        )
    );
  }

  void onClickCryptoPortfolio(){
    Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => CryptoPortfolioScreen()));
  }

  void onClickStockPortfolio(){
    Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => StockPortfolioScreen()));
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
