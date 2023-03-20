import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// import 'package:focus_detector/focus_detector.dart';
import 'package:http/http.dart' as http;
// import 'package:intl/intl.dart';
import 'package:selective_chat/adapters/channel_adapter.dart';
import 'package:selective_chat/adapters/message_adapter.dart';
import 'package:selective_chat/adapters/search_message_adapter.dart';
import 'package:selective_chat/models/app_user.dart';
import 'package:selective_chat/models/channel.dart';
import 'package:selective_chat/models/message.dart';
import 'package:selective_chat/models/notification_to_display.dart';
import 'package:selective_chat/models/search_message.dart';
import 'package:selective_chat/utils/constants.dart';
import 'package:selective_chat/utils/db_helper.dart';
import 'package:selective_chat/utils/methods.dart';
import 'package:selective_chat/utils/push_notification_service.dart';
import 'package:selective_chat/utils/widgets.dart';
import 'package:selective_chat/views/subscriptions.dart';
import 'package:upgrader/upgrader.dart';
import '../locator.dart';
import 'channel_messages.dart';
import 'drawer.dart';

PushNotificationService notif = locator<PushNotificationService>();

class ChannelScreen extends StatefulWidget {

  @override
  _ChannelScreenState createState() => _ChannelScreenState();
}

class _ChannelScreenState extends State<ChannelScreen> {

  bool is_loading = false;

  Icon custom_icon = const Icon(Icons.search);
  Widget title_text;
  bool is_searching = false;
  List<Channel> search_list = [];
  TextEditingController search_controller = new TextEditingController();

  List<Channel> channel_list = [];

  DbHelper db_helper = new DbHelper();
  AppUser user;
  DrawerLayout drawer;

  @override
  Widget build(BuildContext context) {

    bool is_android = Platform.isAndroid;

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
          filterChannels();
        },
        decoration: InputDecoration(
          hintText: 'Search for channel',
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
      String channel_name = "Channels";
      title_text =  Text("$channel_name");
    }

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: DrawerLayout(context: context),
      appBar: AppBar(
        title: title_text,
        actions: [
          searchIcon()
        ],
      ),
      resizeToAvoidBottomInset: false,
        body: is_loading ? loadingPage() : UpgradeAlert(
          child: mainPage(),
          upgrader: Upgrader(
            dialogStyle: is_android ? UpgradeDialogStyle.material : UpgradeDialogStyle.cupertino,
            debugDisplayAlways: false,
            canDismissDialog: false,
            showIgnore: false,
            showLater: false,
            durationUntilAlertAgain: Duration(hours: 12),),
        )
    );
  }

  void callback() async {
    await db_helper.getLatestEditedMessages(user.last_login);
    await db_helper.getLatestDeletedMessages(user.last_login);
    setState(() {
      is_loading = false;
    });
  }

  Widget channelList(){
    if(is_searching){
      return ListView.builder(
        itemCount: search_list.length,
        shrinkWrap: false,
        itemBuilder: (context, index){
          Channel c = search_list[index];
          return ChannelAdapter(channel: c, callback: callback,);
        },
      );
    }
    else{
      channel_list.sort((a,b){
        return a.compareTo(b);
      });
      return ListView.builder(
        itemCount: channel_list.length,
        shrinkWrap: false,
        itemBuilder: (context, index){
          Channel c = channel_list[index];
          return ChannelAdapter(channel: c, callback: callback);
        },
      );
    }
  }

  @override
  void dispose(){
    channel_list.clear();
    super.dispose();
  }

  Future<void> downloadNewMessages(String channel_name) async {
    int last_timestamp = 0;
    List<Message> messages = await db_helper.getMessagesSQLite(channel_name);
    if(messages.isNotEmpty){
      messages.sort((a, b) {
        return a.compareTo(b);
      });
      last_timestamp = int.parse(messages[messages.length-1].timestamp);
    }
    await db_helper.getNewMessages(last_timestamp, channel_name);
  }

  void filterChannels(){
    String search_string = search_controller.text.toString().toLowerCase().trim();
    search_list = [];
    for(var i = 0; i<channel_list.length; i++){
      Channel c = channel_list[i];
      if(c.channel_name.toLowerCase().contains(search_string.toLowerCase())){
        Channel ch = Channel(
          number_of_members: c.number_of_members,
          unread_messages: c.unread_messages,
          channel_name: c.channel_name,
          channel_image: c.channel_image,
          channel_id: c.channel_id,
        );
        search_list.add(ch);
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

  Future<void> getChannels() async{
    setState(() {
      //is_loading = true;
    });
    channel_list = await db_helper.getChannelsSQLite();
    setState(() {
      is_loading = false;
    });
  }

  Future<void> getNewChannels() async {
    bool is_connected = await checkConnection();
    if(is_connected){
      setState(() {
        //is_loading = true;
      });
      int last_id = 0;
      channel_list.sort((a,b){
        var a0 = a.channel_id;
        var b0 = b.channel_id;

        if(a0 > b0){
          return 1;
        }
        else if(a0 == b0){
          return 0;
        }
        else{
          return -1;
        }
      });
      if(channel_list.isNotEmpty){
        last_id = channel_list.last.channel_id;
      }
      Map<String, dynamic> params = {
        "id": last_id.toString()
      };
      print("channel_screen.getNewChannels params ${params.toString()}");
      try{
        var url = Uri.https(Constants.server_get_url, '/selective_app/SelectiveTradesApp/getChannels.php', params);
        var response = await http.get(url);
        print("channel_screen.getNewChannels response: ${response.body.toString()}");
        if(response.body != "failure"){
          try{
            var json = jsonDecode(response.body.toString());
            List<dynamic> channels = json;
            for(var i = 0; i < channels.length; i++){
              Channel c = new Channel(
                  channel_id: int.parse(channels[i]["id"]),
                  channel_name: channels[i]["channel_name"],
                  number_of_members: channels[i]["number_of_members"],
                  members: channels[i]["members"],
                  channel_image: channels[i]["channel_image"],
                  position: int.parse(channels[i]["position"])
              );
              await db_helper.saveChannelSQLite(c);
            }
            await db_helper.getDeletedChannels();
            channel_list = await db_helper.getChannelsSQLite();
            setState(() {
              is_loading = false;
            });
          }
          catch(e){
            print("ChannelScreen.getNewChannels exception: ${e.toString}");
            setState(() {
              is_loading = false;
            });
          }
        }
        else{
          await db_helper.getDeletedChannels();
          channel_list = await db_helper.getChannelsSQLite();
          setState(() {
            is_loading = false;
          });
        }
      }
      catch(e){
        print("ChannelScreen.getChannels: ${e.toString()}");
        setState(() {
          is_loading = false;
        });
      }
    }
    else{
      getChannels();
    }
  }

  Future<void> init () async {
    channel_list = await db_helper.getChannelsSQLite();
    setState(() {

    });
    user = await db_helper.getAppUserSQLite();
    await getNewChannels();
    setState(() {

    });
    await db_helper.getLatestEditedMessages(user.last_login);
    await db_helper.getLatestDeletedMessages(user.last_login);
    setState(() {

    });
  }

  @override
  initState() {
    init();
    super.initState();
  }

  Widget loadingPage(){
    return Container(
        color: Colors.white,
        child: Center(
            child: CircularProgressIndicator()
        )
    );
  }

  Widget mainPage(){
    return RefreshIndicator(
      onRefresh: getNewChannels,
      child: channelList()
    );
  }

  void notificationCallback(){
    print("channel_screen.notificationCallback called");
    setState(() {
      getNewChannels();
    });
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
        is_searching ? resetSearch() : filterChannels();
      },
      icon: is_searching ? Icon(Icons.close) : Icon(Icons.search),
    );
  }

  showNotificationDialog(BuildContext context, NotificationToDisplay n){
    String notif_time = "";
    AlertDialog d = AlertDialog(
      title: Text("Message from ${n.channel}"),
      content: Container(
        margin: EdgeInsets.all(5.0),
        height: 100,
        child: Column(
          children: [
            Container(
              alignment: Alignment.centerLeft,
              margin: EdgeInsets.all(5.0),
              child: Text("${n.message}$notif_time"),
            ),
          ],
        ),
      ),
      actions: [
        GestureDetector(
          onTap: () async {
            //await db_helper.deleteNotificationToDisplay();
            Channel c = Channel(channel_name: n.channel);
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (context) => ChannelMessages(channel: c, callback: callback,)));
          },
          child: Text("Open", style: primaryTextstyle(),)
        ),
        GestureDetector(
            onTap: () async {
              //await db_helper.deleteNotificationToDisplay();
              Navigator.pop(context);
            },
            child: Text("Close", style: primaryTextstyle(),)
        )
      ],
    );
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return d;
      },
    );
  }

}


