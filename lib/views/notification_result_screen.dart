import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:selective_chat/adapters/message_adapter.dart';
import 'package:selective_chat/adapters/search_message_adapter.dart';
import 'package:selective_chat/models/app_user.dart';
import 'package:selective_chat/models/channel.dart';
import 'package:selective_chat/models/message.dart';
import 'package:selective_chat/models/search_message.dart';
import 'package:selective_chat/utils/constants.dart';
import 'package:selective_chat/utils/db_helper.dart';
import 'package:selective_chat/utils/methods.dart';
import 'package:selective_chat/utils/widgets.dart';
import 'package:selective_chat/views/channel_screen.dart';
import 'package:selective_chat/views/sign_in.dart';
import 'package:selective_chat/views/subscriptions.dart';

class NotificationResultScreen extends StatefulWidget {

  Channel channel;
  Function callback;
  NotificationResultScreen({this.channel, this.callback});

  @override
  State<NotificationResultScreen> createState() => _NotificationResultScreenState();

}

class _NotificationResultScreenState extends State<NotificationResultScreen> {
  AppUser user;
  bool is_subscribed = false;

  int message_count_position = 0;
  int messages_count;

  Icon custom_icon = const Icon(Icons.search);
  Widget title_text;

  bool is_searching = false;
  List<SearchMessage> search_list = [];

  Message to_edit;
  bool is_loading = false;
  bool is_editing = false;

  List<Message> messages_list = [];
  double font_size = 18;

  TextEditingController search_controller = new TextEditingController();

  ScrollController scroll_controller = new ScrollController(keepScrollOffset: true);

  int last_id = 0;
  DbHelper db_helper = new DbHelper();

  StreamSubscription connection_stream_subscription;

  String message_text = "No messages yet...";

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
        onSubmitted: (String value) async {
          await filterMessages();
        },
        decoration: InputDecoration(
          hintText: 'Search for text',
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
      if(widget.channel.channel_name.length > 12)
        font_size = 18;
      String channel_name = widget.channel.channel_name;
      title_text =  Text("$channel_name", style: TextStyle(fontSize: font_size),);
    }

    return Scaffold(
        backgroundColor: Colors.white,
        floatingActionButton: is_subscribed ? Container() : ElevatedButton(
          onPressed: (){
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => SubscriptionsScreen(is_leading: true,)));
          },
          child: new Text("Subscribe", style: TextStyle(fontSize: 16, fontFamily: 'aventa_regular'),),
          style: ElevatedButton.styleFrom(shape: StadiumBorder()),
        ),
        appBar: AppBar(
          title: title_text,
          actions: [
            searchIcon(),
            Container(width: 10,),
            IconButton(
              onPressed: () async {
                if(is_subscribed){
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ChannelScreen()));
                }
                else{
                  user.logged_in = "false";
                  user.ip_address = await getLocationByIp();
                  user.app_version_ios = Platform.isIOS ? Constants.ios_app_version : "";
                  user.app_version_android = Platform.isAndroid ? Constants.android_app_version : "";
                  user.device = "";
                  await db_helper.updateUser(user);
                  setState(() {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => SignIn()));
                  });
                }
              },
              icon: Icon(Icons.close),
            )
          ],
        ),
        resizeToAvoidBottomInset: true,
        body: is_loading ? loadingPage() : mainPage()
    );
  }

  Future<void> filterMessages() async {
    String search_string = search_controller.text.toString().toLowerCase().trim();
    search_list = [];
    List<Message> m_list = await db_helper.getAllMessagesSQLite(widget.channel.channel_name);
    for(var i = 0; i<m_list.length; i++){
      Message m = m_list[i];
      if(m.message.toLowerCase().contains(search_string)){
        SearchMessage sm = SearchMessage(
            message_id: m.message_id,
            message: m.message,
            channel: m.channel,
            timestamp: m.timestamp,
            attachment: m.attachment,
            attachment_type: m.attachment_type,
            status: m.status,
            search_string: search_string
        );
        search_list.add(sm);
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

  Future<void> getMessages() async{
    if(mounted){
      setState(() {
        //is_loading = true;
      });
    }
    List<Message> m = await db_helper.getMessagesSQLite(widget.channel.channel_name);
    messages_list.clear();
    messages_list.addAll(m);
    //widget.callback();
    setState(() {
      is_loading = false;
    });
  }

  Future<void> getMoreMessages() async {
    int total_message_count = await db_helper.getMessagesCount();
    if(messages_list.length < total_message_count){
      message_count_position = int.parse(messages_list[messages_list.length-1].message_id);
      List<Message> m = await db_helper.getMoreMessages(widget.channel.channel_name, message_count_position);
      messages_list.addAll(m);
      //widget.callback();
      setState(() {

      });
    }
  }

  Future<void> getNewMessages() async {
    bool is_connected = await checkConnection();
    if(is_connected){
      if(mounted){
        setState(() {
          //is_loading = true;
        });
      }
      await db_helper.clearChannelNotificationCount(widget.channel.channel_name);
      messages_list = await db_helper.getAllMessagesSQLite(widget.channel.channel_name);
      if(messages_list.isNotEmpty){
        messages_list.sort((a, b) {
          return a.compareTo(b);
        });
        last_id = int.parse(messages_list[0].message_id);
      }
      else{
        print("channel_messages.getNewMessages messages list: ${messages_list.length}");
      }
      await db_helper.getNewMessages(last_id, widget.channel.channel_name);
      int last_login = 0;
      if(user.last_login != "" && user.last_login != null){
        last_login = int.parse(user.last_login) - 864000000;
      }
      await db_helper.getLatestSecondaryStatus(last_login.toString());
      await getMessages();
    }
    else{
      getMessages();
    }
  }

  Future<void> init() async {
    user = await db_helper.getAppUserSQLite();
    int expiry = int.parse(user.expiry_date) + Constants.two_days;
    if(expiry > DateTime.now().millisecondsSinceEpoch){
      is_subscribed = true;
    }
    else{
      is_subscribed = false;
    }
    setState(() {

    });
    await getMessages();
    scroll_controller.addListener(() {
      if(scroll_controller.position.atEdge){
        if(scroll_controller.position.pixels != 0){
          getMoreMessages();
        }
      }
    });

    connection_stream_subscription = Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if(result == ConnectivityResult.none){
        showToast("Lost internet connection");
      }
      else{
        getNewMessages();
      }
    });
    widget.channel.unread_messages = "0";
    getNewMessages();
  }

  @override
  void initState(){
    init();
    super.initState();
  }

  Widget mainPage(){
    return RefreshIndicator(
      onRefresh: getNewMessages,
      child: Stack(
        children: [
          Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: messagesList(),
          ),
          messages_list.isEmpty ? noItem(message_text, context) : Container()
        ],
      ),
    );
  }

  Widget messagesList(){
    if(is_searching){
      search_list.sort((a, b) {
        return a.compareTo(b);
      });
      return ListView.builder(
        controller: scroll_controller,
        itemCount: search_list.length,
        shrinkWrap: false,
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        itemBuilder: (context, index){
          SearchMessage m = search_list[index];
          return SearchMessageAdapter(message: m);
        },
      );
    }
    else{
      messages_list.sort((a, b) {
        return a.compareTo(b);
      });
      return ListView.builder(
        controller: scroll_controller,
        itemCount: messages_list.length,
        shrinkWrap: false,
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        itemBuilder: (context, index){
          Message m = messages_list[index];
          return MessageAdapter(message: m, is_sender: false,);
        },
      );
    }
  }

  void resetSearch(){
    search_controller.text = "";
    setState(() {
      is_searching = false;
    });
  }

  Widget searchIcon(){
    return IconButton(
      onPressed: () async {
        is_searching ? resetSearch() : await filterMessages();
      },
      icon: is_searching ? Icon(Icons.close) : Icon(Icons.search),
    );
  }

}
