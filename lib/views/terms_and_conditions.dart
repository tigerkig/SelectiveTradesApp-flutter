import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:selective_chat/utils/widgets.dart';

class TermsAndConditions extends StatefulWidget {

  @override
  _TermsAndConditionsState createState() => _TermsAndConditionsState();
}

class _TermsAndConditionsState extends State<TermsAndConditions> {

  bool is_loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          title: Container(
              alignment: Alignment.centerLeft,
              width: MediaQuery.of(context).size.width,
              child: Text("T&C")
          )
      ),
      resizeToAvoidBottomInset: false,
      body: is_loading ? loadingPage() : mainPage(),
    );
  }

  Widget mainPage(){
    String t_and_c = "Legal Disclaimer: Selective Trades LLC & Team Offer general trading\n"
        "information and opinions that does not take into consideration factors such as\n"
        "your trading experience, personal objectives and goals, financial means, or risk\n"
        "tolerance. Decisions to buy, sell, hold or trade in securities and other\n"
        "investments involve risk tolerance. Decisions to buy, sell, hold or trade in\n"
        "securities and other investments involve risk and are best made based on the\n"
        "advice of qualified financial professionals.\n"
        "Selective trades LLC & Team guarantee no profit whatsoever, you assume the\n"
        "entire cost and risk of any trading or investing activities you choose to\n"
        "undertake. You are solely responsible for making your own investment decisions.\n"
        "Selective Trades LLC NOT a registered as securities broker-dealers or\n"
        "investment advisors either with the U.S. Securities and Exchange Commission,\n"
        "CFTC or with any other securities/regulatory authority. Consult with a\n"
        "registered investment advisor, broker-dealer, and/or financial advisor. By \n"
        "signing up for the mobile messenger chat app as a member, you are agreeing \n"
        "to these terms and conditions";
    return SingleChildScrollView(
      child: Container(
        alignment: Alignment.centerLeft,
        width: MediaQuery.of(context).size.width,
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.all(13),
              child: Text(
                "Terms and conditions",
                style: TextStyle(
                    fontSize: 24,
                    color: Colors.black,
                    fontFamily: 'aventa_black'
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.all(13),
              child: Text(
                t_and_c,
                style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontFamily: 'aventa_black'
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

