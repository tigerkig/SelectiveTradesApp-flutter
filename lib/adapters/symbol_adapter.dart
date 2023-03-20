import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:selective_chat/models/symbol.dart';
import 'package:selective_chat/utils/widgets.dart';

class SymbolAdapter extends StatelessWidget {

  Symbol symbol;
  BuildContext context;

  SymbolAdapter({
    this.symbol,
    this.context
  });

  @override
  Widget build(BuildContext context) {
    bool is_name = symbol.name.isEmpty ? false : true;

    return GestureDetector(
      onTap: (){
        Navigator.pop(this.context, symbol.symbol);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          color: Colors.blueGrey,
        ),
        width: MediaQuery.of(context).size.width,
        padding: EdgeInsets.all(10),
        margin: EdgeInsets.all(8),
        child: Text(
          "${symbol.symbol} ${is_name ? '(${symbol.name})' : ''}",
          style: TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontFamily: 'aventa_black'
        ),
        ),
      ),
    );
  }


}
