import 'dart:convert';
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;
import 'package:selective_chat/models/symbol.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

Future<String> getLocationByIp() async{
  try{
    Map<String, dynamic> params = {"apiKey": "16b5efc568624c188fb43c3bddc936a0"};
    Uri url = Uri.https('api.ipgeolocation.io', '/ipgeo', params);
    var response = await http.get(url);
    if(response.statusCode == 200){
      var json = jsonDecode(response.body);
      String ip_address = json["ip"];
      String country = json["country_name"];
      String region = json["state_prov"];
      String city = json["city"];
      String isp = json["isp"];
      return "IP: $ip_address\nCountry: $country\nRegion: $region\nCity: $city\nISP: $isp";
    }
    else{
      return "";
    }
  }
  catch(e){
    print("getLocationByIp Exception: ${e.toString()}");
    return "";
  }
}

bool isValidEmail(String email){
  if(email.isEmpty)
    return false;
  bool email_valid = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(email);
  return email_valid;
}

Future showToast(String message){
  return Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 2,
      backgroundColor: Colors.white,
      textColor: Colors.black,
      fontSize: 16.0
  );
}

Future<bool> checkConnection() async{
  var result = await (Connectivity().checkConnectivity());
  if(result == ConnectivityResult.none){
    return false;
  }
  else{
    return true;
  }
}

Future<File> compressImage(String path, int quality) async {
  final new_path = p.join((await getTemporaryDirectory()).path, '${DateTime.now()}.${p.extension(path)}');
  final result = await FlutterImageCompress.compressAndGetFile(
      path,
      new_path,
      quality: quality);
  return result;
}

Future<String> refreshFirebaseToken() async{
  final FirebaseMessaging fcm = FirebaseMessaging.instance;
  print("methods.refreshFirebaseToken: token is ${fcm.toString()}");
  return await fcm.getToken();
}

Future<File> writeToFile(ByteData data, String path) {
  return File(path).writeAsBytes(data.buffer.asUint8List(
    data.offsetInBytes,
    data.lengthInBytes,
  ));
}

Future<DateTime> showDate(BuildContext context) async{
  final DateTime picker = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1960, 8),
      lastDate: DateTime(2101)
  );
  return picker;
}

Future<List<Symbol>> getCryptoList() async {
  List<Symbol> crypto_list = [];
  final data = await rootBundle.load('assets/symbols/crypto.csv');
  final directory = (await getTemporaryDirectory()).path;
  final file = await writeToFile(data, '$directory/crypto.txt');
  List<String> list = await file.readAsLines();
  list.forEach((element) {
    List<String> split_string = element.toString().substring(0).split(",");
    var symbol_ = split_string[0];
    var symbol = new Symbol(symbol: symbol_, name: split_string[2], type: "crypto");
    if(!crypto_list.contains(symbol)){
      crypto_list.add(symbol);
    }
  });
  return crypto_list;
}

Future<List<Symbol>> getStockList() async {
  List<Symbol> stock_list = [];
  final data = await rootBundle.load('assets/symbols/stocks.csv');
  final directory = (await getTemporaryDirectory()).path;
  final file = await writeToFile(data, '$directory/stock.txt');
  List<String> list = await file.readAsLines();
  list.forEach((element) {
    List<String> split_string = element.toString().substring(0).split(",");
    var symbol_ = split_string[0];
    var name = split_string[1];
    var symbol = new Symbol(symbol: symbol_, name: name, type: "stock");
    if(!stock_list.contains(symbol)){
      stock_list.add(symbol);
    }
  });
  stock_list.removeAt(0);
  return stock_list;
}

Future<void> openTermsOfService() async{
  var url = "https://www.privacypolicies.com/live/ef17ed9a-8aa5-4b07-ab93-50da974b098e";
  if(await canLaunch(url)){
    await launch(url);
  }
  else{
    showToast("Cannot launch URL");
  }
}