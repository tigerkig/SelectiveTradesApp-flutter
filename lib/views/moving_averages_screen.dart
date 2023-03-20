import 'dart:convert';
import 'dart:io';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:selective_chat/utils/constants.dart';
import 'package:selective_chat/utils/methods.dart';
import 'package:selective_chat/utils/widgets.dart';
import 'package:selective_chat/views/select_symbol.dart';

class MovingAveragesScreen extends StatefulWidget {

  String from;
  MovingAveragesScreen({this.from});

  @override
  State<MovingAveragesScreen> createState() => _MovingAveragesScreenState();
}

class _MovingAveragesScreenState extends State<MovingAveragesScreen> {

  String selected_symbol;
  String accepted_symbol;
  String selected_average = "sma";
  double current_value = 0.0;
  bool is_loading = true;

  List<charts.Series<MovingAverageSeries, DateTime>> series_list = [];
  List<charts.Series<MovingAverageSeries, DateTime>> series_list1 = [];

  String interval = "1min";
  String selected_duration = "one_hour";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: GestureDetector(
            onTap: () async {
              selected_symbol = await Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => SelectSymbol(from: Constants.stock,)));
              if(selected_symbol != null){
                accepted_symbol = selected_symbol;
                await getChartData();
              }
              else{
                setState(() {

                });
              }
            },
            child: Container(
              width: MediaQuery.of(context).size.width - 70,
              alignment: Alignment.centerRight,
              child: Text(accepted_symbol, style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontFamily: 'aventa_black'
              ))
            )
        ),
      ),
      resizeToAvoidBottomInset: false,
      body: is_loading ? loadingPage() : mainPage(),
    );
  }

  Future<void> getChartData() async {
    int list_limit = 0;

    switch(selected_duration){
      case "one_hour":
        list_limit = 60;
        break;
      case "four_hour":
        list_limit = 48;
        break;
      case "one_day":
        list_limit = 48;
        break;
      case "one_week":
        list_limit = 60;
        break;
      case "one_month":
        list_limit = 30;
        break;
      case "one_year":
        list_limit = 52;
        break;
    }

    bool is_connected = await checkConnection();
    if(is_connected){
      setState(() {
        is_loading = true;
      });
      try{
        final params = {
          "symbol": accepted_symbol,
          "apikey":Constants.twelvedata_api_key,
          "interval": interval,
          "outputsize": list_limit.toString()
        };

        var url = Uri.https('api.twelvedata.com', '/$selected_average', params);
        var response = await http.get(url);
        if(response.statusCode == 200){
          if(response.body.isNotEmpty){
            var json = jsonDecode(response.body.toString());
            Map<String, dynamic> quote = json;
            String status = "success";
            try{
              status = quote["status"];
            }
            catch(e){
              print("MovingAveragesScreen.getChartData error getting request status ${e.toString()}");
            }
            if(status == "error"){
              showToast("An error occurred");
              setState(() {
                is_loading = false;
              });
            }
            else{
              print("MovingAveragesScreen.getChartData response: ${response.body.toString()}");
              List<dynamic> series = quote["values"];

              series_list.clear();
              List<MovingAverageSeries> list = [];

              for(var i = 0; i<series.length; i++){
                Map<String, dynamic> series_data = series[i];
                DateTime date = DateTime.parse(series_data["datetime"]);
                double sma = double.parse(series_data[selected_average].toString());
                if(i == 0)
                  current_value = sma;

                MovingAverageSeries m = MovingAverageSeries(date, sma);
                list.add(m);
              }

              series_list = [
                new charts.Series(
                    id: 'stock_series',
                    data: list,
                    domainFn: (MovingAverageSeries avg, _) => avg.time,
                    measureFn: (MovingAverageSeries avg, _) => avg.value
                )
              ];

              setState(() {
                accepted_symbol = selected_symbol;
                is_loading = false;
              });
            }
          }
        }
        else{
          setState(() {
            is_loading = false;
          });
          print("MovingAveragesScreen.getChartData response error: ${response.statusCode}");
        }
      }
      catch(e){
        print("MovingAveragesScreen.getChartData exception error: ${e.toString()}");
        showToast("An error occurred");
        setState(() {
          is_loading = false;
        });
      }
    }
  }

  Future<void> init() async {
    if(widget.from == Constants.crypto)
      selected_symbol = "BTC/USD";
    else
      selected_symbol = Platform.isIOS ? "AAPL" : "GOOGL";
    accepted_symbol = selected_symbol;
    await getChartData();
  }

  @override
  void initState(){
    init();
    super.initState();
  }

  Widget mainPage(){
    return SingleChildScrollView(
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:[
            Container(height: 10,),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: (){
                    if(selected_average != "sma"){
                      setState(() {
                        selected_average = "sma";
                        getChartData();
                      });
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.all(8),
                    margin: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.all(Radius.circular(5)),
                    ),
                    child: Text(
                      "SMA",
                      style: TextStyle(
                          fontSize: 16,
                          color: selected_average == "sma" ? Colors.green : Colors.black,
                          fontFamily: 'aventa_black'
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: (){
                    if(selected_average != "ema"){
                      setState(() {
                        selected_average = "ema";
                        getChartData();
                      });
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.all(8),
                    margin: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.all(Radius.circular(5)),
                    ),
                    child: Text(
                      "EMA",
                      style: TextStyle(
                          fontSize: 16,
                          color: selected_average == "ema" ? Colors.green : Colors.black,
                          fontFamily: 'aventa_black'
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Container(height: 10,),
            Text(
              "Current value: ${current_value.toStringAsFixed(2)}",
              style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontFamily: 'aventa_black'
              ),
            ),
            Container(height: 10,),
            Expanded(
              child: SimpleTimeSeriesChart (
                series_list,
              ),
            ),
            Container(height: 10,),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: (){
                    if(selected_duration != "one_hour"){
                      setState(() {
                        selected_duration = "one_hour";
                        interval = "1min";
                        getChartData();
                      });
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.all(8),
                    margin: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.all(Radius.circular(5)),
                    ),
                    child: Text(
                      "1hr",
                      style: TextStyle(
                          fontSize: 16,
                          color: selected_duration == "one_hour" ? Colors.green : Colors.black,
                          fontFamily: 'aventa_black'
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: (){
                    if(selected_duration != "four_hour"){
                      setState(() {
                        selected_duration = "four_hour";
                        interval = "5min";
                        getChartData();
                      });
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.all(8),
                    margin: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.all(Radius.circular(5)),
                    ),
                    child: Text(
                      "4hr",
                      style: TextStyle(
                          fontSize: 16,
                          color: selected_duration == "four_hour" ? Colors.green : Colors.black,
                          fontFamily: 'aventa_black'
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: (){
                    if(selected_duration != "one_day"){
                      setState(() {
                        selected_duration = "one_day";
                        interval = "30min";
                        getChartData();
                      });
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.all(8),
                    margin: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.all(Radius.circular(5)),
                    ),
                    child: Text(
                      "1d",
                      style: TextStyle(
                          fontSize: 16,
                          color: selected_duration == "one_day" ? Colors.green : Colors.black,
                          fontFamily: 'aventa_black'
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: (){
                    if(selected_duration != "one_week"){
                      setState(() {
                        selected_duration = "one_week";
                        interval = "2h";
                        getChartData();
                      });
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.all(8),
                    margin: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.all(Radius.circular(5)),
                    ),
                    child: Text(
                      "1w",
                      style: TextStyle(
                          fontSize: 16,
                          color: selected_duration == "one_week" ? Colors.green : Colors.black,
                          fontFamily: 'aventa_black'
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: (){
                    if(selected_duration != "one_month"){
                      setState(() {
                        selected_duration = "one_month";
                        interval = "1day";
                        getChartData();
                      });
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.all(8),
                    margin: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.all(Radius.circular(5)),
                    ),
                    child: Text(
                      "1m",
                      style: TextStyle(
                          fontSize: 16,
                          color: selected_duration == "one_month" ? Colors.green : Colors.black,
                          fontFamily: 'aventa_black'
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: (){
                    if(selected_duration != "one_year"){
                      setState(() {
                        selected_duration = "one_year";
                        interval = "1week";
                        getChartData();
                      });
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.all(8),
                    margin: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.all(Radius.circular(5)),
                    ),
                    child: Text(
                      "1y",
                      style: TextStyle(
                          fontSize: 16,
                          color: selected_duration == "one_year" ? Colors.green : Colors.black,
                          fontFamily: 'aventa_black'
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Container(height: 10,),
          ],
        ),
      ),
    );
  }
}

class MovingAverageSeries {
  final DateTime time;
  final double value;

  MovingAverageSeries(this.time, this.value);
}

class SimpleTimeSeriesChart extends StatelessWidget {
  final List<charts.Series> seriesList;
  final bool animate;

  SimpleTimeSeriesChart(this.seriesList, {this.animate});

  @override
  Widget build(BuildContext context) {
    return new charts.TimeSeriesChart(
      seriesList,
      animate: animate,
      dateTimeFactory: const charts.LocalDateTimeFactory(),
    );
  }
}
