import 'dart:convert';
import 'package:candlesticks/candlesticks.dart';
import 'package:flutter/material.dart';
import 'package:selective_chat/utils/constants.dart';
import 'package:selective_chat/utils/methods.dart';
import 'package:selective_chat/utils/widgets.dart';
import 'package:selective_chat/views/select_symbol.dart';
import 'package:http/http.dart' as http;

class CryptoChartScreen extends StatefulWidget {

  @override
  State<CryptoChartScreen> createState() => _CryptoChartScreenState();
}

class _CryptoChartScreenState extends State<CryptoChartScreen> {
  String selected_symbol  = "BTC/USD";
  String accepted_symbol = "BTC/USD";
  bool is_loading = true;

  List<Candle> candle_list = [];
  String interval = "1min";
  String selected_duration = "one_hour";

  String _r1, _r2, _r3;
  String _s1, _s2, _s3;
  String _pp;

  double high = 0, low = 0, open = 0, close = 0, change = 0, price = 0;
  double adx = 0, vwap = 0, rsi = 0, macd = 0, supertrend = 0, rvol = 0;
  String _change;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Container(
          width: MediaQuery.of(context).size.width - 50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(accepted_symbol, style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontFamily: 'aventa_black'
              ),),
              GestureDetector(child: Icon(Icons.list, color: Colors.white, size: 24,), onTap: () async {
                selected_symbol = await Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => SelectSymbol(from: Constants.crypto,)));
                if(selected_symbol != null && selected_symbol != ""){
                  accepted_symbol = selected_symbol;
                  await getChartData();
                }
                else{
                  setState(() {

                  });
                }
              })
            ],
          ),
        ),
      ),
      resizeToAvoidBottomInset: false,
      body: is_loading ? loadingPage() : mainPage(),
    );
  }

  Future<void> getADX() async {
    bool is_connected = await checkConnection();
    if(is_connected){
      try{
        final params = {
          "symbol": accepted_symbol,
          "apikey":Constants.twelvedata_api_key,
          "interval": interval
        };

        var url = Uri.https('api.twelvedata.com', '/adx', params);
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
              print("CryptoChartScreen.getADX error getting request status ${e.toString()}");
            }
            print("CryptoChartScreen.getADX response ${response.body.toString()}");
            if(status == "error"){
              showToast("An error occurred getting ADX");
              setState(() {
                is_loading = false;
              });
            }
            else{
              List<dynamic> series = quote["values"];
              Map<String, dynamic> data = series[0];
              adx = double.parse(data["adx"].toString());
              await getVWAP();
            }
          }
          else{
            setState(() {
              is_loading = false;
            });
          }
        }
        else{
          setState(() {
            is_loading = false;
          });
          print("CryptoChartScreen.getADX response error: ${response.statusCode}");
        }
      }
      catch(e){
        print("CryptoChartScreen.getADX exception error: ${e.toString()}");
        showToast("An error occurred");
        setState(() {
          is_loading = false;
        });
      }
    }
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

        var url = Uri.https('api.twelvedata.com', '/time_series', params);
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
              print("CryptoChartScreen.getChartData error getting request status ${e.toString()}");
            }
            print("CryptoChartScreen.getChartData response ${response.body.toString()}");
            if(status == "error"){
              showToast("An error occurred");
              setState(() {
                is_loading = false;
              });
            }
            else{
              List<dynamic> series = quote["values"];

              double max_high = 0, max_low = double.maxFinite;

              candle_list.clear();

              for(var i = 0; i<series.length; i++){
                Map<String, dynamic> candle_data = series[i];
                DateTime date = DateTime.parse(candle_data["datetime"]);
                double open = double.parse(candle_data["open"].toString());
                double close = double.parse(candle_data["close"].toString());
                double high = double.parse(candle_data["high"].toString());
                double low = double.parse(candle_data["low"].toString());

                if(high > max_high){
                  max_high = high;
                }
                if(low < max_low){
                  max_low = low;
                }

                Candle candle = Candle(
                    high: high,
                    low: low,
                    open: open,
                    close: close,
                    volume: 1,
                    date: date
                );
                candle_list.add(candle);
              }

              high = max_high;
              low = max_low;
              close = candle_list[0].close;
              open = candle_list[candle_list.length-1].open;

              change = ((close - open) / open) * 100;
              if(change < 0){
                _change = change.toStringAsFixed(2)+"%";
                _change+=", Bearish";
              }
              else{
                _change = "+" + change.toStringAsFixed(2)+"%";
                _change+=", Bullish";
              }

              double pp = (low + high+ close) / 3;
              double s1 = (2 * pp) - high;
              double r1 = (2 * pp) - low;
              double s2 = pp - (r1 - s1);
              double r2 = pp + (r1 - s1);
              double s3 = low - 2 * (high - pp);
              double r3 = high + 2 * (pp - low);

              _s1 = s1.toStringAsFixed(2);
              _s2 = s2.toStringAsFixed(2);
              _s3 = s3.toStringAsFixed(2);
              _r1 = r1.toStringAsFixed(2);
              _r2 = r2.toStringAsFixed(2);
              _r3 = r3.toStringAsFixed(2);
              _pp = pp.toStringAsFixed(2);


              await getPrice();

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
          print("CryptoChartScreen.getChartData response error: ${response.statusCode}");
        }
      }
      catch(e){
        print("CryptoChartScreen.getChartData exception error: ${e.toString()}");
        showToast("An error occurred");
        setState(() {
          is_loading = false;
        });
      }
    }
  }

  Future<void> getMacd() async {
    bool is_connected = await checkConnection();
    if(is_connected){
      try{
        final params = {
          "symbol": accepted_symbol,
          "apikey":Constants.twelvedata_api_key,
          "interval": interval
        };

        var url = Uri.https('api.twelvedata.com', '/macd', params);
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
              print("CryptoChartScreen.getMacd error getting request status ${e.toString()}");
            }
            print("CryptoChartScreen.getMacd response ${response.body.toString()}");
            if(status == "error"){
              showToast("An error occurred getting MACD");
              setState(() {
                is_loading = false;
              });
            }
            else{
              List<dynamic> series = quote["values"];
              Map<String, dynamic> data = series[0];
              macd = double.parse(data["macd"].toString());
              print("CryptoChartScreen.getMacd macd is ${macd.toString()}");
              await getSupertrend();
            }
          }
          else{
            setState(() {
              is_loading = false;
            });
          }
        }
        else{
          setState(() {
            is_loading = false;
          });
          print("CryptoChartScreen.getMacd response error: ${response.statusCode}");
        }
      }
      catch(e){
        print("CryptoChartScreen.getMacd exception error: ${e.toString()}");
        showToast("An error occurred");
        setState(() {
          is_loading = false;
        });
      }
    }
  }

  Future<void> getPrice() async {
    bool is_connected = await checkConnection();
    if(is_connected){
      try{
        final params = {
          "symbol": accepted_symbol,
          "apikey":Constants.twelvedata_api_key,
        };
        var url = Uri.https('api.twelvedata.com', '/price', params);
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
              print("CryptoChartScreen.getPrice error getting request status ${e.toString()}");
            }
            print("CryptoChartScreen.getPrice response ${response.body.toString()}");
            if(status == "error"){
              showToast("An error occurred getting price");
              setState(() {
                is_loading = false;
              });
            }
            else{
              price = double.parse(quote["price"].toString());
              await getADX();
            }
          }
          else{
            setState(() {
              is_loading = false;
            });
          }
        }
        else{
          setState(() {
            is_loading = false;
          });
          print("CryptoChartScreen.getChartData response error: ${response.statusCode}");
        }
      }
      catch(e){
        showToast("An error occurred");
        print("CryptoChartScreen.getPrice: exception occurred ${e.toString()}");
        setState(() {
          is_loading = false;
        });
      }
    }
  }

  Future<void> getRSI() async {
    bool is_connected = await checkConnection();
    if(is_connected){
      try{
        final params = {
          "symbol": accepted_symbol,
          "apikey":Constants.twelvedata_api_key,
          "interval": interval
        };

        var url = Uri.https('api.twelvedata.com', '/rsi', params);
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
              print("CryptoChartScreen.getRSI error getting request status ${e.toString()}");
            }
            print("CryptoChartScreen.getRSI response ${response.body.toString()}");
            if(status == "error"){
              showToast("An error occurred getting RSI");
              setState(() {
                is_loading = false;
              });
            }
            else{
              List<dynamic> series = quote["values"];
              Map<String, dynamic> data = series[0];
              rsi = double.parse(data["rsi"].toString());
              print("CryptoChartScreen.getRSI RSI is ${rsi.toString()}");
              await getMacd();
            }
          }
          else{
            setState(() {
              is_loading = false;
            });
          }
        }
        else{
          setState(() {
            is_loading = false;
          });
          print("CryptoChartScreen.getRSI response error: ${response.statusCode}");
        }
      }
      catch(e){
        print("CryptoChartScreen.getRSI exception error: ${e.toString()}");
        showToast("An error occurred");
        setState(() {
          is_loading = false;
        });
      }
    }
  }

  Future<void> getSupertrend() async {
    bool is_connected = await checkConnection();
    if(is_connected){
      try{
        final params = {
          "symbol": accepted_symbol,
          "apikey":Constants.twelvedata_api_key,
          "interval": interval
        };

        var url = Uri.https('api.twelvedata.com', '/supertrend', params);
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
              print("CryptoChartScreen.getSuperTrend error getting request status ${e.toString()}");
            }
            print("CryptoChartScreen.getSuperTrend response ${response.body.toString()}");
            if(status == "error"){
              showToast("An error occurred getting SuperTrend");
              setState(() {
                is_loading = false;
              });
            }
            else{
              List<dynamic> series = quote["values"];
              Map<String, dynamic> data = series[0];
              supertrend = double.parse(data["supertrend"].toString());
              print("CryptoChartScreen.getSuperTrend supertrend is ${supertrend.toString()}");
              await getRVOL();
            }
          }
          else{
            setState(() {
              is_loading = false;
            });
          }
        }
        else{
          setState(() {
            is_loading = false;
          });
          print("CryptoChartScreen.getSuperTrend response error: ${response.statusCode}");
        }
      }
      catch(e){
        print("CryptoChartScreen.getSuperTrend exception error: ${e.toString()}");
        showToast("An error occurred");
        setState(() {
          is_loading = false;
        });
      }
    }
  }

  Future<void> getVWAP() async {
    bool is_connected = await checkConnection();
    if(is_connected){
      try{
        final params = {
          "symbol": accepted_symbol,
          "apikey":Constants.twelvedata_api_key,
          "interval": interval
        };

        var url = Uri.https('api.twelvedata.com', '/vwap', params);
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
              print("CryptoChartScreen.getVWAP error getting request status ${e.toString()}");
            }
            print("CryptoChartScreen.getVWAP response ${response.body.toString()}");
            if(status == "error"){
              showToast("An error occurred getting VWAP");
              setState(() {
                is_loading = false;
              });
            }
            else{
              List<dynamic> series = quote["values"];
              Map<String, dynamic> data = series[0];
              vwap = double.parse(data["vwap"].toString());
              print("CryptoChartScreen.getVWAP vwap is ${vwap.toString()}");
              await getRSI();
            }
          }
          else{
            setState(() {
              is_loading = false;
            });
          }
        }
        else{
          setState(() {
            is_loading = false;
          });
          print("CryptoChartScreen.getVWAP response error: ${response.statusCode}");
        }
      }
      catch(e){
        print("CryptoChartScreen.getVWAP exception error: ${e.toString()}");
        showToast("An error occurred");
        setState(() {
          is_loading = false;
        });
      }
    }
  }

  Future<void> getRVOL() async {
    bool is_connected = await checkConnection();
    if(is_connected){
      try{
        final params = {
          "symbol": accepted_symbol,
          "apikey":Constants.twelvedata_api_key,
          "interval": interval
        };

        var url = Uri.https('api.twelvedata.com', '/rvol', params);
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
              print("CryptoChartScreen.getRVOL error getting request status ${e.toString()}");
            }
            print("CryptoChartScreen.getRVOL response ${response.body.toString()}");
            if(status == "error"){
              showToast("An error occurred getting RVOL");
              setState(() {
                is_loading = false;
              });
            }
            else{
              List<dynamic> series = quote["values"];
              Map<String, dynamic> data = series[0];
              rvol = double.parse(data["rvol"].toString());
              print("CryptoChartScreen.getRVOL rvol is ${rvol.toString()}");
            }
          }
          else{
            setState(() {
              is_loading = false;
            });
          }
        }
        else{
          setState(() {
            is_loading = false;
          });
          print("CryptoChartScreen.getRVOL response error: ${response.statusCode}");
        }
      }
      catch(e){
        print("CryptoChartScreen.getRVOL exception error: ${e.toString()}");
        showToast("An error occurred");
        setState(() {
          is_loading = false;
        });
      }
    }
  }

  Future<void> init() async {
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
            Expanded(
              child: Candlesticks(
                candles: candle_list,
              ),
            ),
            Container(height: 10,),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(
                  "Price: ${price.toStringAsFixed(2)}",
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                      fontFamily: 'aventa_black'
                  ),
                ),
                Text(
                  "Open: ${open.toStringAsFixed(2)}",
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                      fontFamily: 'aventa_black'
                  ),
                ),
                Text(
                  "Close: ${close.toStringAsFixed(2)}",
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                      fontFamily: 'aventa_black'
                  ),
                ),
              ],
            ),
            Container(height: 10,),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(
                  "High: ${high.toStringAsFixed(2)}",
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                      fontFamily: 'aventa_black'
                  ),
                ),
                Text(
                  "Low: ${low.toStringAsFixed(2)}",
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                      fontFamily: 'aventa_black'
                  ),
                ),
                Text(
                  "Vol: N/A",
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                      fontFamily: 'aventa_black'
                  ),
                ),
              ],
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
            Container(
              margin: EdgeInsets.fromLTRB(10, 0, 0, 10),
              child: Text(
                "Change: $_change",
                style: TextStyle(
                    fontSize: 16,
                    color: change < 0 ? Colors.red : Colors.green,
                    fontFamily: 'aventa_black'
                ),
              ),
            ),
            Container(height: 10,),
            Container(
                margin: EdgeInsets.fromLTRB(10, 0, 0, 10),
                child: Text("Resistances",)
            ),
            Container(height: 5,),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(
                  "R1: $_r1",
                  style: primaryTextstyle(),
                ),
                Text(
                  "R2: $_r2",
                  style: primaryTextstyle(),
                ),
                Text(
                  "R3: $_r3",
                  style: primaryTextstyle(),
                ),
              ],
            ),
            Container(height: 5,),
            Container(
                margin: EdgeInsets.fromLTRB(10, 0, 0, 10),
                child: Text("Supports",)
            ),
            Container(height: 5,),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(
                  "S1: $_s1",
                  style: primaryTextstyle(),
                ),
                Text(
                  "S2: $_s2",
                  style: primaryTextstyle(),
                ),
                Text(
                  "S3: $_s3",
                  style: primaryTextstyle(),
                ),
              ],
            ),
            Container(
              color: Colors.black,
              height: 1,
              width: MediaQuery.of(context).size.width,
              margin: EdgeInsets.fromLTRB(15, 8, 15, 8),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(
                  "ADX: ${adx.toStringAsFixed(2)}",
                  style: primaryTextstyle(),
                ),
                Text(
                  "VWAP: ${vwap.toStringAsFixed(2)}",
                  style: primaryTextstyle(),
                ),
                Text(
                  "RSI: ${rsi.toStringAsFixed(2)}",
                  style: primaryTextstyle(),
                ),
              ],
            ),
            Container(
              color: Colors.black,
              height: 1,
              width: MediaQuery.of(context).size.width,
              margin: EdgeInsets.fromLTRB(15, 8, 15, 8),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(
                  "MACD: ${macd.toStringAsFixed(2)}",
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                      fontFamily: 'aventa_black'
                  ),
                ),
                Text(
                  "RVOL: ${rvol.toStringAsFixed(2)}",
                  style:  TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                      fontFamily: 'aventa_black'
                  ),
                ),
                Text(
                  "Supertrend: ${supertrend.toStringAsFixed(2)}",
                  style:  TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                      fontFamily: 'aventa_black'
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