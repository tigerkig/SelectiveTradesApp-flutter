import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
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

class ChannelMessages extends StatefulWidget {

  Channel channel;
  Function callback;
  ChannelMessages({this.channel, this.callback});

  @override
  _ChannelMessagesState createState() => _ChannelMessagesState();

}

class _ChannelMessagesState extends State<ChannelMessages> {

  AppUser user;

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

  TextEditingController message_controller = new TextEditingController();

  ScrollController scroll_controller = new ScrollController(keepScrollOffset: true);

  int last_id = 0;
  DbHelper db_helper = new DbHelper();

  StreamSubscription connection_stream_subscription;

  bool is_sender = false;

  File attachment;
  final picker = ImagePicker();

  String message_text = "No messages yet...";

  String server_key = "key=AAAAIT2SXPk:APA91bGGnfeSDcsa_p7OCIj9-I2SVeAY53uT7Xotb4YgA401QXUO1SS26e0KXzCiRVK7MxnRmxrbiD67xDEzlKf0NCgX8-Yw3yVT_L5YlX5H11XUJFFb62FzCGBRbdR63C-GbLNinLOq";
  String fcm_api = "https://fcm.googleapis/com/fcm/send";

  Widget bottomSheet(){
    if(is_editing){
      message_controller.text = to_edit.message;
    }
    else{
      message_controller.text = "";
    }
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 50,
      child: Row(
        children: [
          attachment == null ? Container() : showAttachment(),
          GestureDetector(
            onTap: (){
              selectAttachment();
            },
            child: Container(
                width: 50,
                decoration: BoxDecoration(
                  //borderRadius: BorderRadius.circular(40),
                    gradient: LinearGradient(
                        colors: [
                          const Color(0xFFFFFF),
                          const Color(0xFFFFFF)
                        ]
                    )
                ),
                padding: EdgeInsets.all(5),
                height: 50,
                child: Image.asset("assets/images/plus.png")),
          ),
          Expanded(child: Container(
            child: FocusScope(
              child: Focus(
                onFocusChange: ((focus){

                }),
                child: TextField(
                  expands: true,
                  maxLines: null,
                  controller: message_controller,
                  style: TextStyle(
                      color: Colors.black
                  ),
                  decoration: InputDecoration(
                      hintText: "Message...",
                      hintStyle: TextStyle(
                          color: Colors.black54
                      ),
                      border: InputBorder.none
                  ),
                ),
              ),
            ),
          )),
          GestureDetector(
            onTap: (){
              sendMessage();
            },
            child: Container(
                width: 50,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    gradient: LinearGradient(
                        colors: [
                          const Color(0xFFFFFF),
                          const Color(0xFFFFFF)
                        ]
                    )
                ),
                padding: EdgeInsets.all(10),
                height: 50,
                child: Image.asset("assets/images/send.png")),
          ),
        ],
      ),
    );
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
        bottomSheet: is_sender ? bottomSheet() : Container(height: 1,),
        appBar: AppBar(
          title: title_text,
          actions: [
            searchIcon()
          ],
        ),
        resizeToAvoidBottomInset: true,
        body: is_loading ? loadingPage() : mainPage()
    );
  }

  Future<void> checkCanSend() async {
    user = await db_helper.getAppUserSQLite();
    Map<String,dynamic> params = {
      "channel": widget.channel.channel_name
    };
    var url = Uri.https(Constants.server_get_url, '/selective_app/SelectiveTradesApp/getSenders.php', params);
    var response = await http.get(url);
    if(response.statusCode == 200){
      if(response.body != 'failure'){
        if(response.body.isNotEmpty){
          List<dynamic> json = jsonDecode('${response.body}');
          if(json[0]["senders"] != null){
            var json_ = jsonDecode(json[0]["senders"]);
            if(json_["${user.email}"] != null){
              is_sender = true;
            }
          }
        }
      }
    }
    else{
      print("channel_messages.checkCanSend response exception : ${response.body}");
    }
  }

  Future<void> filterMessages() async {
    String search_string = search_controller.text.toString().toLowerCase().trim();
    search_list = [];
    List<Message> m_list = await db_helper.getAllMessagesSQLite(widget.channel.channel_name);
    for(var i = 0; i<m_list.length; i++){
      Message m = m_list[i];
      if(m.message.toLowerCase().contains(search_string) || m.status.toLowerCase().contains(search_string) || m.secondary_status.toLowerCase().contains(search_string)){
        SearchMessage sm = SearchMessage(
          message_id: m.message_id,
          message: m.message,
          channel: m.channel,
          timestamp: m.timestamp,
          attachment: m.attachment,
          attachment_type: m.attachment_type,
          status: m.status,
          search_string: search_string,
          secondary_status_timestamp: m.secondary_status_timestamp,
          secondary_status_color: m.secondary_status_color,
          secondary_status: m.secondary_status,
          message_color: m.message_color
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
    widget.callback();
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
      widget.callback();
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
    checkCanSend();
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
          return MessageAdapter(message: m, is_sender: is_sender,);
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

  Future selectAttachment() async {
    final selected_image = await picker.getImage(source: ImageSource.gallery);
    if (selected_image == null)
      return;

    var cropped_image = await ImageCropper().cropImage(
        sourcePath: selected_image.path,
        aspectRatio: CropAspectRatio(ratioX: 1, ratioY: 1));

    if (cropped_image == null)
      return;
    cropped_image = await compressImage(cropped_image.path, 20);

    setState(() {
      attachment = File(cropped_image.path);
      print("channel_messages.selectAttachment selected image ${attachment.path}");
    });
  }

  Future sendMessage() async {
    bool is_connected = await checkConnection();
    if(is_connected){
      if(message_controller.text.isEmpty){
        showToast("Message required");
      }
      else{
        setState(() {
          //is_loading = true;
        });
        String attachment_url = "";
        if(attachment != null){
          attachment_url = await uploadImageToFirebase(context, attachment);
        }
        if(is_editing){
          final params = {
            "timestamp": to_edit.timestamp,
            "id": to_edit.message_id,
            "message": message_controller.text.toString()
          };
          to_edit.message = message_controller.text.toString();
          var url = Uri.parse('${Constants.server_url}/selective_app/SelectiveTradesApp/editMessage.php');
          var response = await http.post(url, body: params);
          if(response.body == 'success'){
            await db_helper.updateMessage(to_edit);
            setState(() {
              to_edit = null;
              is_editing = false;
              message_controller.text = "";
              attachment = null;
              showToast("Message updated");
              getMessages();
            });
          }
          else{
            setState(() {
              is_loading = false;
            });
          }
        }
        else{
          var timestamp = DateTime.now().millisecondsSinceEpoch.toString();
          final params = {
            "message":message_controller.text.toString().trim(),
            "channel":widget.channel.channel_name,
            "timestamp":timestamp,
            "attachment":attachment_url,
            "attachment_type":""
          };
          var url = Uri.parse("${Constants.server_url}/selective_app/SelectiveTradesApp/addMessage.php");
          var response = await http.post(url, body: params);
          if(response.body == 'success'){
            Message m = Message(message: params["message"], attachment: attachment_url);
            showToast("Message sent, sending notifications...");
            await sendNotifications(m);
            setState(() {
              message_controller.text = "";
              attachment = null;
              getNewMessages();
            });

          }
          else{
            setState(() {
              is_loading = false;
            });
          }
        }
      }
    }
  }

  Future sendNotifications(Message m) async {
    List<String> s = await db_helper.getFirebaseTokensSQLite();
    print("channel_messages.sendNotifications firebase tokens ${s.toString()}");
    Map<String, dynamic> message;
    if(m.attachment != ""){
      message = {
        "notification": {
          "sound": "default",
          "title": "New message from ${widget.channel.channel_name}",
          "body": "${m.message}",
          "image": "${m.attachment}"
        },
        "data": {
          "click_action": "FLUTTER_NOTIFICATION_CLICK",
          "channel": "${widget.channel.channel_name}",
          "title": "New message from ${widget.channel.channel_name}",
          "message": "${m.message}",
          "attachment": "${m.attachment}",
          "timestamp": "${m.timestamp}",
          "screen": "channel_messages"
        },
        "registration_ids": s
      };
    }
    else{
      message = {
        "notification": {
          "sound": "default",
          "title": "New message from ${widget.channel.channel_name}",
          "body": "${m.message}"
        },
        "data": {
          "click_action": "FLUTTER_NOTIFICATION_CLICK",
          "channel": "${widget.channel.channel_name}",
          "message": "${m.message}",
          "title": "New message from ${widget.channel.channel_name}",
          "attachment": "${m.attachment}",
          "timestamp": "${m.timestamp}",
          "screen": "channel_messages"
        },
        "registration_ids": s
      };
    }
    var url = Uri.parse("https://fcm.googleapis.com/fcm/send");
    var response = await http.post(url, body:jsonEncode(message), headers: {"Authorization":server_key,"Content-Type":"application/json"});
    print("channel_messages.sendNotifications response ${response.body.toString()}");
  }

  Widget showAttachment(){
    return GestureDetector(
      onTap: (){
        setState(() {
          attachment = null;
        });
      },
      child: Container(
        width: 50,
        height: 50,
        child: Image.file(attachment),
      ),
    );
  }

  Future<String> uploadImageToFirebase(BuildContext context, File file) async {
    String filename = attachment.path.toString();
    String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    TaskSnapshot snapshot = await FirebaseStorage.instance.ref("channel_images").child("$filename").child("message_$timestamp").putFile(file);
    String image_url = await snapshot.ref.getDownloadURL();
    return image_url;
  }

}


