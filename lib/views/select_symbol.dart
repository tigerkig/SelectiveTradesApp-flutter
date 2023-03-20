import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:selective_chat/adapters/symbol_adapter.dart';
import 'package:selective_chat/utils/constants.dart';
import 'package:selective_chat/utils/methods.dart';
import 'package:selective_chat/utils/widgets.dart';
import 'package:selective_chat/models/symbol.dart';

class SelectSymbol extends StatefulWidget {

  String from;

  SelectSymbol({this.from});

  @override
  _SelectSymbolState createState() => _SelectSymbolState();
}

class _SelectSymbolState extends State<SelectSymbol> {

  bool is_loading = false;
  bool is_searching = true;
  Icon custom_icon = const Icon(Icons.search);
  Widget title_text = const Text("Select symbol");

  TextEditingController search_controller = new TextEditingController();
  List<Symbol> symbol_list = [];
  List<Symbol> search_list = [];

  @override
  void initState() {
    super.initState();
    initList();
  }

  @override
  void dispose() {
    symbol_list.clear();
    super.dispose();
  }

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
          filterSymbols();
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
      title_text =  Text("Select symbol");
    }

    return Scaffold(
      backgroundColor: Colors.white,
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

  void filterSymbols(){
    String search_string = search_controller.text.toString().toLowerCase().trim();
    search_list = [];
    for(var i = 0; i<symbol_list.length; i++){
      Symbol e = symbol_list[i];
      if(e.symbol.toLowerCase().contains(search_string) || e.name.toLowerCase().contains(search_string)){
        search_list.add(e);
      }
      else if(e.name.toLowerCase().contains(search_string)){
        search_list.add(e);
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

  Future<void> initList() async {
    if(widget.from == Constants.crypto_portfolio || widget.from == Constants.crypto_watchlist || widget.from == Constants.crypto){
      setState(() {
        is_loading = true;
      });
      symbol_list = await getCryptoList();
      setState(() {
        is_loading = false;
      });
    }
    else if (widget.from == Constants.stock_portfolio || widget.from == Constants.stock_watchlist || widget.from == Constants.stock) {
      setState(() {
        is_loading = true;
      });
      symbol_list = await getStockList();
      setState(() {
        is_loading = false;
      });
    }
    filterSymbols();
  }

  Widget mainPage(){
    return Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: ListView.builder(
          itemCount: is_searching ? search_list.length : symbol_list.length,
          shrinkWrap: false,
          itemBuilder: (context, index){
            Symbol s = is_searching ? search_list[index] : symbol_list[index];
            return SymbolAdapter(symbol: s, context: context,);
          },
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
        is_searching ? resetSearch() : filterSymbols();
      },
      icon: is_searching ? Icon(Icons.close) : Icon(Icons.search),
    );
  }

}
