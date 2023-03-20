import 'dart:io';
import 'dart:math';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:selective_chat/models/app_user.dart';
import 'package:selective_chat/models/chat_message.dart';
import 'package:selective_chat/utils/constants.dart';
import 'package:selective_chat/utils/db_helper.dart';
import 'package:selective_chat/utils/methods.dart';
import 'package:selective_chat/utils/widgets.dart';

class GeneralChat extends StatefulWidget {

  @override
  State<GeneralChat> createState() => _GeneralChatState();
}

class _GeneralChatState extends State<GeneralChat> {

  bool is_loading = false;

  File attachment;
  PickedFile _attachment;
  final picker = ImagePicker();
  types.PreviewData preview_data;

  TextEditingController search_controller = TextEditingController();

  List<ChatMessage> messages_list = [];
  List<types.Message> chat_messages = [];
  AppUser user;
  types.User _user;
  double font_size = 18;
  DbHelper db_helper = DbHelper();

  Icon custom_icon = const Icon(Icons.search);
  Widget title_text;

  bool is_searching = false;
  List<types.Message> search_list = [];

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
          filterMessages();
        },
        decoration: InputDecoration(
          hintText: 'Search for message',
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
      title_text =  Text("General chat", style: TextStyle(fontSize: font_size),);
    }
    if(is_loading){
      return Scaffold(
          backgroundColor: Colors.white,
          body: is_loading ? loadingPage() : mainPage()
      );
    }
    return Scaffold(
        appBar: AppBar(
          title: title_text,
          actions: [
            searchIcon()
          ],
        ),
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true,
        body: mainPage()
    );
  }

  void filterMessages(){
    String search_string = search_controller.text.toString().toLowerCase().trim();
    search_list = [];
    for(var i = 0; i<chat_messages.length; i++){
      types.Message m = chat_messages[i];
      String message = m.toJson()["text"];
      if(message.toLowerCase().contains(search_string)){
        search_list.add(m);
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

  Future<void> getChatMessagesSQLite() async {
    messages_list = await db_helper.getChatMessages();
    if(messages_list.isNotEmpty){
      for(var i = 0; i<messages_list.length; i++){
        ChatMessage m = messages_list[i];
        types.User author;

        List<String> names = m.sender_name.split(" ");
        String first_name = names[0];
        String last_name = names[1];
        author = types.User(
          id: m.sender_id.toString(),
          firstName: first_name,
          lastName: last_name,
        );

        types.Message _m;
        if(m.attachment_url == "null" || m.attachment_url == ""){
          _m = types.TextMessage(
            author: author,
            createdAt: int.parse(m.timestamp),
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            text: m.message,
            showStatus: true,
            status: m.status == "delivered" ? types.Status.delivered : types.Status.seen,
          );
        }
        else{
          _m = types.ImageMessage(
            size: 80,
            author: author,
            createdAt:int.parse(m.timestamp),
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: m.message,
            uri: m.attachment_url,
            showStatus: true,
            status: m.status == "delivered" ? types.Status.delivered : types.Status.seen,
            updatedAt: DateTime.now().millisecondsSinceEpoch,
          );
        }

        chat_messages.add(_m);
      }
    }
  }

  Future<void> getLatestDeletedChatMessages() async {
    int last_login = 0;
    if(user.last_login != "" && user.last_login != null){
      last_login = int.parse(user.last_login) - 864000000;
    }
    await db_helper.getLatestDeletedChatMessages(last_login.toString());
  }

  Future<void> getNewChatMessages() async {
    messages_list = await db_helper.getChatMessages();
    List<ChatMessage> new_messages;
    int last_timestamp = 0;
    if(messages_list.isNotEmpty){
      messages_list.sort((a, b) {
        return a.compareTo(b);
      });
      last_timestamp = int.parse(messages_list[0].timestamp);
    }
    new_messages = await db_helper.getNewChatMessages(last_timestamp);
    messages_list.addAll(new_messages);
    messages_list.sort((a,b){
      return a.compareTo(b);
    });
  }

  void handleMessageTap(BuildContext context, types.Message message) async {
    if (message is types.FileMessage) {
      await OpenFile.open(message.uri);
    }
  }

  void handlePreviewDataFetched(types.TextMessage message, types.PreviewData previewData){
    final index = chat_messages.indexWhere((element) => element.id == message.id);
    final updatedMessage = chat_messages[index];
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      setState(() {
        chat_messages[index] = updatedMessage;
      });
    });
    preview_data = previewData;
  }

  Future<void> handleSendMessage(types.PartialText message) async {
    bool is_connected = await checkConnection();
    if(is_connected){
      String attachment_url = "";
      var chat_message;
      if(attachment != null){
        final bytes = await attachment.readAsBytes();
        final image = await decodeImageFromList(bytes);
        chat_message = types.ImageMessage(
          author: _user,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: message.text,
          size: bytes.length,
          uri: _attachment.path,
          width: image.width.toDouble(),
          showStatus: true,
          status: types.Status.delivered,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );
      }
      else{
        chat_message = types.TextMessage(
          author: _user,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: message.text,
          showStatus: true,
          status: types.Status.delivered,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
          previewData: attachment == null ? null : preview_data,
        );
      }

      chat_messages.add(chat_message);
      setState(() {

      });
      if(attachment != null){
        attachment_url = await uploadImageToFirebase(context, attachment);
      }
      ChatMessage _message = ChatMessage(
        message_id: DateTime.now().millisecondsSinceEpoch,
        timestamp: chat_message.createdAt.toString(),
        attachment_url: attachment_url,
        sender_name: user.username,
        message: attachment == null ? chat_message.text : "Attachment",
        sender_id: int.parse(user.id),
        status: "delivered",
      );
      await sendMessage(_message);
      messages_list.add(_message);
      await db_helper.saveChatMessageSQLite(_message);
      attachment = null;
    }
    else{
      showToast("No internet connection");
    }
  }

  Future<void> init() async {
    setState(() {
      is_loading = true;
    });
    user = await db_helper.getAppUserSQLite();
    List<String> names = user.username.split(" ");
    String first_name = names[0];
    String last_name = "";
    if(names.length == 2) {
      last_name = names[1];
    }
    _user = types.User(
      id: user.id,
      firstName: first_name,
      lastName: last_name,
      createdAt: int.parse(user.date_registered),
      imageUrl: user.profile_image_url,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    await getNewChatMessages();
    await getLatestDeletedChatMessages();
    await getChatMessagesSQLite();

    setState(() {
      is_loading = false;
    });
  }

  @override
  void initState(){
    init();
    super.initState();
  }

  Widget mainPage(){
    List<types.Message> l = [];
    for(var i = chat_messages.length-1; i>=0; i--){
      l.add(chat_messages[i]);
    }
    return Chat(
      customDateHeaderText: (datetime){
        return "";
      },
      dateHeaderBuilder: (header){
        return null;
      },
      textMessageBuilder: textMessageBuilder,
      showUserAvatars: true,
      showUserNames: true,
      messages: is_searching ? search_list : l,
      onAttachmentPressed: selectAttachment,
      onPreviewDataFetched: handlePreviewDataFetched,
      onSendPressed: handleSendMessage,
      onMessageTap: handleMessageTap,
      user: _user,
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
        is_searching ? resetSearch() : filterMessages();
      },
      icon: is_searching ? Icon(Icons.close) : Icon(Icons.search),
    );
  }

  Future selectAttachment() async {
    final selected_image = await picker.getImage(source: ImageSource.gallery);
    if (selected_image == null) {
      return;
    }
    setState(() {
      attachment = File(selected_image.path);
      _attachment = PickedFile(attachment.path);
    });
  }

  Future<void> sendMessage(ChatMessage message) async {
    final params = {
      "message":message.message.trim(),
      "timestamp":message.timestamp,
      "attachment":message.attachment_url,
      "status":message.status,
      "sender_name":message.sender_name.toString(),
      "sender_id": message.sender_id.toString(),
    };
    var url = Uri.parse('${Constants.server_url}/selective_app/SelectiveTradesApp/sendChatMessage.php');
    var response = await http.post(url, body: params);
    if(response.body != "failure"){
      await sendNotifications(message);
    }
    else{
      showToast("An error occurred");
      setState(() {
        is_loading = false;
      });
    }
  }

  Future<void> sendNotifications(ChatMessage message) async{

  }

  Widget textMessageBuilder(types.TextMessage message, {int messageWidth, bool showName}){
    final formatted_date = DateFormat("MMM dd, hh:mm a");
    Color text_color;
    if(message.author.id == user.id){
      text_color = Colors.white;
    }
    else{
      text_color = Colors.black;
    }
    String date = formatted_date.format(new DateTime.fromMillisecondsSinceEpoch(message.createdAt));
    return Container(
      padding: EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          showName ? Text(message.author.firstName.substring(0,1).toUpperCase() + "." + message.author.lastName.substring(0,1).toUpperCase(), style: TextStyle(
              fontSize: 16,
              color: Colors.primaries[Random().nextInt(Colors.primaries.length)],
              fontFamily: 'aventa_regular'
          ),) : Container(),
          Text(message.text, style: TextStyle(
            fontSize: 16,
            color: text_color,
            fontFamily: 'aventa_regular'
          ),),
          Container(
            alignment: Alignment.centerRight,
            child: Text(date, style: TextStyle(
              fontSize: 14,
              color: Colors.black,
              fontFamily: 'aventa_light'
            )),
          ),
          //Text(message.)
        ],
      ),
    );
  }

  Future<String> uploadImageToFirebase(BuildContext context, File file) async {
    String filename = attachment.path.toString();
    String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    TaskSnapshot snapshot = await FirebaseStorage.instance.ref("general_chat_images").child("$filename").child("message_$timestamp").putFile(file);
    String image_url = await snapshot.ref.getDownloadURL();
    print("general_chat.uploadImageToFirebase image url: $image_url");
    return image_url;
  }

}
