import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:selective_chat/adapters/live_option_adapter.dart';
import 'package:selective_chat/models/live_option.dart';
import 'package:selective_chat/utils/constants.dart';
import 'package:selective_chat/utils/methods.dart';
import 'package:selective_chat/utils/widgets.dart';
import 'package:http/http.dart' as http;

class ClosedOptions extends StatefulWidget {

  @override
  State<ClosedOptions> createState() => _ClosedOptionsState();

}

class _ClosedOptionsState extends State<ClosedOptions> {

  bool is_loading = false;

  List<LiveOption> option_list = [];
  List<LiveOption> search_list = [];
  Icon custom_icon = const Icon(Icons.search);
  Widget title_text;
  bool is_searching = false;

  TextEditingController search_controller = new TextEditingController();

  @override
  Widget build(BuildContext context) {
    if (is_searching) {
      title_text = TextField(
        onTap: () {
          setState(() {
            is_searching = true;
          });
        },
        autocorrect: false,
        controller: search_controller,
        onSubmitted: (String value) {
          filterOptions();
        },
        decoration: InputDecoration(
          hintText: 'Search for tracker',
          hintStyle: TextStyle(
              fontSize: 16, color: Colors.white, fontFamily: 'aventa_light'),
          border: InputBorder.none,
        ),
        style: TextStyle(
            fontSize: 16, color: Colors.white, fontFamily: 'aventa_black'),
      );
    }
    else {
      String channel_name = "Under 35% premium";
      title_text = Text("$channel_name");
    }
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
            actions: [
              Container(
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        is_searching ? resetSearch() : filterOptions();
                      },
                      icon: is_searching ? Icon(Icons.close) : Icon(Icons.search),
                    )
                  ],
                ),
              ),
            ],
            title: title_text
        ),
        resizeToAvoidBottomInset: false,
        body: is_loading ? loadingPage() : mainPage());
  }

  void filterOptions() {
    String search_string =
    search_controller.text.toString().toLowerCase().trim();
    search_list = [];
    for (var i = 0; i < option_list.length; i++) {
      LiveOption o = option_list[i];
      if (o.tracker.toLowerCase().contains(search_string.toLowerCase())) {
        LiveOption lo = LiveOption(
          timestamp: o.timestamp,
          tracker: o.tracker,
          pct_change: o.pct_change,
          live_price: o.live_price,
          status: o.status,
          channel: o.channel,
        );
        search_list.add(lo);
      }
    }
    if (search_list.isNotEmpty) {
      setState(() {
        is_searching = true;
      });
    } else {
      setState(() {
        is_searching = false;
      });
    }
  }

  Future<void> getOptions() async {
    setState(() {
      is_loading = true;
    });
    var url =
    Uri.https(Constants.server_get_url, "/selective_app/SelectiveTradesApp/getTrackers.php");
    var response = await http.get(url);
    if (response.body != 'failure') {
      var json = jsonDecode(response.body);
      List<dynamic> l = json;
      for (var i = 0; i < l.length; i++) {
        LiveOption option = LiveOption(
          tracker: l[i]["tracker"],
          timestamp: l[i]["timestamp"],
          status: l[i]["status"],
          channel: l[i]["channel"],
          live_price: l[i]["live_price"],
          pct_change: l[i]["pct_change"],
        );
        if(option.live_price == ''){
          option.live_price = '0';
        }
        if(option.pct_change == ''){
          option.pct_change = '0';
        }
        if(option.status == 'close'){
          option_list.add(option);
        }
      }
      setState(() {
        is_loading = false;
      });
    }
    else{
      setState(() {
        is_loading = false;
      });
      showToast("An error occurred, try again");
    }
  }

  Future<void> init() async {
    await getOptions();
  }

  @override
  void initState() {
    init();
    super.initState();
  }

  Widget mainPage() {
    return Stack(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              margin: EdgeInsets.fromLTRB(20, 0, 0, 0),
              width: 170,
              child: Text(
                "Tracker",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black),
              ),
            ),
            Container(
              child: Text(
                "Close price",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black),
              ),
            ),
            Container(
              margin: EdgeInsets.fromLTRB(0, 0, 10, 0),
              child: Text(
                "%P/L",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black),
              ),
            ),
          ],
        ),
        Container(
            margin: EdgeInsets.fromLTRB(0, 40, 0, 0),
            child: optionList()
        ),
        option_list.isEmpty
            ? noItem("", context)
            : Container()
      ],
    );
  }

  Widget optionList(){
    if(is_searching){
      search_list.sort((a, b) {
        return a.compareTo(b);
      });
      return ListView.builder(
        itemCount: search_list.length,
        shrinkWrap: false,
        itemBuilder: (context, index){
          LiveOption l = search_list[index];
          return LiveOptionAdapter(option: l,);
        },
      );
    }
    else{
      option_list.sort((a, b) {
        return a.compareTo(b);
      });
      return ListView.builder(
        itemCount: option_list.length,
        shrinkWrap: false,
        itemBuilder: (context, index){
          LiveOption l = option_list[index];
          return LiveOptionAdapter(option: l);
        },
      );
    }
  }

  void resetSearch() {
    search_controller.text = "";
    setState(() {
      is_searching = false;
    });
  }

  Widget searchIcon() {
    return Container(
      width: 50,
      child: IconButton(
        onPressed: () {
          is_searching ? resetSearch() : filterOptions();
        },
        icon: is_searching ? Icon(Icons.close) : Icon(Icons.search),
      ),
    );
  }

}
