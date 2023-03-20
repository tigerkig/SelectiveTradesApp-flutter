import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:selective_chat/adapters/live_option_adapter.dart';
import 'package:selective_chat/models/live_option.dart';
import 'package:selective_chat/models/message.dart';
import 'package:selective_chat/models/tracker.dart';
import 'package:selective_chat/utils/constants.dart';
import 'package:selective_chat/utils/db_helper.dart';
import 'package:selective_chat/utils/methods.dart';
import 'package:selective_chat/utils/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:selective_chat/views/closed_options.dart';

class LiveOptionsScreen extends StatefulWidget {
  @override
  _LiveOptionsScreenState createState() => _LiveOptionsScreenState();
}

class _LiveOptionsScreenState extends State<LiveOptionsScreen> {
  bool is_loading = false;
  List<LiveOption> option_list = [];
  List<Tracker> tracker_list = [];
  List<String> option_list_timestamps = [];

  List<String> user_tokens = [];
  Icon custom_icon = const Icon(Icons.search);
  Widget title_text;
  bool is_searching = false;
  List<LiveOption> search_list = [];
  TextEditingController search_controller = new TextEditingController();

  String access_token = "nnA0GySxyJq0OGjOjlPSMKpsfjzv";
  String server_key = "key=AAAAIT2SXPk:APA91bGGnfeSDcsa_p7OCIj9-I2SVeAY53uT7Xotb4YgA401QXUO1SS26e0KXzCiRVK7MxnRmxrbiD67xDEzlKf0NCgX8-Yw3yVT_L5YlX5H11XUJFFb62FzCGBRbdR63C-GbLNinLOq";
  String fcm_api = "https://fcm.googleapis/com/fcm/send";

  DbHelper db_helper = new DbHelper();

  Future<void> addOptionToMessages(LiveOption option) async {
    bool is_connected = await checkConnection();
    if(is_connected){
      setState(() {
        is_loading = true;
      });
      String attachment_url = "";
      var timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final params = {
        "message":option.tracker,
        "channel":option.channel,
        "timestamp":timestamp,
        "attachment":attachment_url,
        "attachment_type":""
      };
      var url = Uri.https(Constants.server_get_url, '/selective_app/SelectiveTradesApp/addMessage.php', params);
      var response = await http.get(url);
      if(response.body == 'success'){
        setState(() {
          is_loading = false;
        });
      }
      else{
        setState(() {
          is_loading = false;
        });
      }
    }
  }

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
      String channel_name = "Live options";
      title_text = Text("$channel_name");
    }
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
            actions: [
              Container(
                child: Row(
                  children: [
                    GestureDetector(
                      child: Container(
                          margin: EdgeInsets.fromLTRB(0, 0, 10, 0),
                          child: Icon(Icons.refresh)),
                      onTap: () async {
                        await getTrackers();
                      },
                    ),
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
        floatingActionButton: FloatingActionButton(
          onPressed: (){
            Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => ClosedOptions()));
          },
          child: Icon(Icons.notifications),
        ),
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

  Future<void> getOption(Tracker t) async {
    List<String> list = t.tracker.toString().split("-");
    var symbol = list[0].toUpperCase();
    var expiry = list[1];
    var call_put_ = list[2];
    var strike_ = list[3];
    var strike_price_ = list[4];
    String stoploss = "";

    if(list.length == 6){
      double sl = 0;
      try{
        sl = double.parse(list[5]);
        stoploss = list[5];
      }
      catch(e){

      }
    }
    else if(list.length == 7){
      stoploss = list[5];
    }
    else if(list.length == 8){
      stoploss = list[5];
    }

    var year = expiry.toString().substring(0, 2);
    var month = expiry.toString().substring(2, 4);
    var day = expiry.toString().substring(4, 6);
    var exp = "20" + year + "-" + month + "-" + day;
    var exp_ = year + month + day;

    Map<String, String> params = {"symbol": symbol, "expiration": exp};

    var url =
    Uri.https("api.tradier.com", "/v1/markets/options/chains", params);
    Map<String, String> headers = {
      "Authorization": "Bearer $access_token",
      "Accept": "application/json"
    };
    await http.get(url, headers: headers).then((value) async {
      Response response = value;
      var json = jsonDecode(response.body);
      if (json != null) {
        var options = json["options"];
        if (options != null) {
          List<dynamic> option = json["options"]["option"];
          for (var i = 0; i < option.length; i++) {
            try {
              Map<String, dynamic> e = {};
              e.addAll(option[i]);

              String option_type =
              e["option_type"].toString().substring(0, 1).toLowerCase();
              double strike = double.parse(e["strike"].toString());
              if (option_type ==
                  call_put_.toString().toLowerCase().substring(0, 1) &&
                  strike == double.parse(strike_)) {
                var tracker_ = "";
                if (stoploss == "") {
                  tracker_ =
                  "${symbol.toUpperCase()}$exp_${option_type.toUpperCase()}$strike_@$strike_price_";
                } else {
                  tracker_ =
                  "${symbol.toUpperCase()}$exp_${option_type.toUpperCase()}$strike_@${strike_price_}SL${stoploss}";
                }
                var last = double.parse(e["last"].toString());
                var diff = last - double.parse(strike_price_);
                var pct = (diff / double.parse(strike_price_)) * 100;
                String status = "open";
                if(pct < -35){
                  status = "close";
                }
                var option = LiveOption(
                    pct_change: pct.toStringAsFixed(2),
                    live_price: last.toStringAsFixed(2),
                    timestamp: t.timestamp.toString(),
                    status: status,
                    tracker: tracker_,
                    channel: t.channel);
                option_list.add(option);
                await db_helper.saveLiveOption(option);
                option_list.sort();
              }
            } catch (e) {
              print("live_options.getOptions exception ${e.toString()}");
            }
          }
        } else {
          print(
              "live_options.getOption: could not fetch details for tracker ${t.tracker} from api");
          //await deleteLiveOption(t.tracker);
        }
      }
      else {
        setState(() {
          is_loading = false;
        });
      }
    });
  }

  Future<void> getOptions() async {
    // Loop through tracker list to get options for each tracker
    option_list.clear();
    await db_helper.deleteLiveOptions();
    for (var i = 0; i < tracker_list.length; i++) {
      if(tracker_list[i].status != "close"){
        await getOption(tracker_list[i]);
      }
      else{

      }
    }
    option_list.sort((a, b) {
      return a.compareTo(b);
    });
  }

  Future<void> getOptionsSQLite() async {
    setState(() {
      is_loading = true;
    });
    option_list = await db_helper.getLiveOptions();
    option_list.sort((a, b) {
      return a.compareTo(b);
    });
    setState(() {
      is_loading = false;
    });
  }

  Future<void> getTrackers() async {
    setState(() {
      is_loading = true;
      is_searching = false;
    });
    var url =
    Uri.https(Constants.server_get_url, "/selective_app/SelectiveTradesApp/getTrackers.php");
    try {
      var response = await http.get(url);
      if (response.body != 'failure') {
        var json = jsonDecode(response.body);
        List<dynamic> l = json;
        tracker_list.clear();
        for (var i = 0; i < l.length; i++) {
          Tracker t =
          Tracker(tracker: l[i]["tracker"], timestamp: l[i]["timestamp"], status: l[i]["status"], channel: l[i]["channel"]);
          tracker_list.add(t);
          print("live_options_screen.getTrackers adding tracker ${l[i]["tracker"]}");
        }
        await getOptions();
        setState(() {
          is_loading = false;
        });
      }
    } catch (e) {
      setState(() {
        is_loading = false;
      });
      showToast("An error occurred, contact developer");
      print("live_options_screen.getTrackers exception ${e.toString()}");
    }
  }

  Future<void> init() async {
    await getOptionsSQLite();
    await getTrackers();
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
                "Live price",
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
      width: 100,
      child: Row(
        children: [
          GestureDetector(
            child: Container(
                margin: EdgeInsets.fromLTRB(0, 0, 10, 0),
                child: Icon(Icons.refresh)),
            onTap: () async {
              await getTrackers();
            },
          ),
          IconButton(
            onPressed: () {
              is_searching ? resetSearch() : filterOptions();
            },
            icon: is_searching ? Icon(Icons.close) : Icon(Icons.search),
          )
        ],
      ),
    );
  }

}
