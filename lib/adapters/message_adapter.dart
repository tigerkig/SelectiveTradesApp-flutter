import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:selective_chat/models/message.dart';
import 'package:selective_chat/utils/constants.dart';
import 'package:selective_chat/utils/db_helper.dart';
import 'package:selective_chat/utils/methods.dart';
import 'package:selective_chat/utils/widgets.dart';
import 'package:selective_chat/views/view_image_attachment.dart';
import 'package:http/http.dart' as http;

class MessageAdapter extends StatelessWidget {

  Message message;
  bool is_editing = false;
  bool is_sender = false;
  Function callback;
  DbHelper db_helper = new DbHelper();

  MessageAdapter({
    this.message,
    this.is_editing,
    this.callback,
    this.is_sender
  });

  @override
  Widget build(BuildContext context) {
    if(is_sender){
      return Dismissible(
        direction: DismissDirection.endToStart,
        background: Container(
          width: MediaQuery.of(context).size.width,
          color: Colors.red,
          alignment: Alignment.center,
          child: Text(
            "Deleted",
            style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontFamily: 'aventa_black'
            ),
          ),
        ),
        key: Key(message.message_id),
        onDismissed: (direction) async{
          await deleteMessage();
        },
        child: GestureDetector(
          onLongPress: (){
            showOptionsDialog(context);
          },
          child: Card(
            elevation: 5,
            child: Container(
              margin: EdgeInsets.fromLTRB(0, 5, 0, 5),
              padding: EdgeInsets.fromLTRB(0, 5, 0, 5),
              color: Colors.white,
              child: Row(
                children: [
                  message.attachment == "" ? Container() : imageAttachment(message.attachment, context),
                  messageText(context)
                ],
              ),
            ),
          ),
        ),
      );
    }
    else{
      return Card(
        elevation: 5,
        child: Container(
          //width: MediaQuery.of(context).size.width,
          margin: EdgeInsets.fromLTRB(0, 5, 0, 5),
          padding: EdgeInsets.fromLTRB(0, 5, 0, 5),
          color: Colors.white,
          child: Row(
            children: [
              message.attachment == "" ? Container() : imageAttachment(message.attachment, context),
              messageText(context)
            ],
          ),
        ),
      );
    }
  }

  Future<void> deleteMessage() async {
    final params = {
      "timestamp": message.timestamp,
      "message": message.message
    };
    var url = Uri.parse('${Constants.server_url}/selective_app/SelectiveTradesApp/deleteMessage.php');
    var response = await http.post(url, body: params);
    if(response.body != "failure"){
      await db_helper.deleteMessage(message);
    }
    else{
      showToast("Unable to delete");
    }
  }

  Widget imageAttachment(String url, BuildContext context){
    return GestureDetector(
      onTap: (){
        Navigator.push(context, MaterialPageRoute(builder: (context) => (ViewImageAttachment(image_url: url,))));
      },
      child: Container(
        width: 50,
        height: 50,
        margin: EdgeInsets.all(5),
        alignment: Alignment.centerLeft,
        child: Image.network(url, height: 50, width: 50,),
      ),
    );
  }

  Widget messageText(BuildContext context){
    Color secondary_status_color;
    Color message_color;

    if(message.secondary_status_color == "green"){
      secondary_status_color = Colors.green;
    }
    else if(message.secondary_status_color == "red"){
      secondary_status_color = Colors.red;
    }
    else if(message.secondary_status_color == "blue"){
      secondary_status_color = Colors.blue;
    }

    if(message.message_color == "green"){
      message_color = Colors.green;
    }
    else if(message.message_color == "red"){
      message_color = Colors.red;
    }
    else if(message.message_color == "blue"){
      message_color = Colors.blue;
    }
    else{
      message_color = Colors.black;
    }

    final formatted_date = DateFormat("MM-dd-yyyy \nhh:mm a");
    String date = formatted_date.format(new DateTime.fromMillisecondsSinceEpoch(int.parse(message.timestamp)));
    String secondary_status_date = formatted_date.format(new DateTime.fromMillisecondsSinceEpoch(int.parse(message.secondary_status_timestamp)));
    return Container(
      margin: EdgeInsets.all(1),
      padding: EdgeInsets.all(1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Column(
              children: [
                Container(
                    width: message.attachment == "" ? MediaQuery.of(context).size.width - 110 : MediaQuery.of(context).size.width - 180,
                    child: Text(message.message, style: TextStyle(
                        fontSize: 16,
                        color: message_color,
                        fontFamily: 'aventa_black'
                    ),)
                ),
                (message.status == "" || message.status=="null") ? Container() : Container(
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.fromLTRB(0, 2, 5, 2),
                  width: MediaQuery.of(context).size.width-110,
                  child: Text(
                    message.status,
                    style: TextStyle(
                        color: Colors.red,
                        fontSize: 15,
                        fontWeight: FontWeight.bold
                    ),
                  ),
                ),
                (message.secondary_status == null || message.secondary_status == "") ? Container() : Container(
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.fromLTRB(0, 2, 5, 2),
                  width: MediaQuery.of(context).size.width-110,
                  child: Text(
                    message.secondary_status,
                    style: TextStyle(
                        color: secondary_status_color,
                        fontSize: 15,
                        fontWeight: FontWeight.bold
                    ),
                  ),
                ),
              ]
          ),
          Column(
            children: [
              Container(
                  child: Text(date, style: secondaryTextStyle(),)
              ),
              Container(height: 10,),
              (message.secondary_status_timestamp == null || message.secondary_status_timestamp == "0") ? Container() : Container(
                alignment: Alignment.centerRight,
                padding: EdgeInsets.fromLTRB(0, 2, 5, 2),
                child: Text(
                  secondary_status_date,
                  style: secondaryTextStyle(),
                ),
              ),
            ],
          ),

        ],
      ),
    );
  }

  showOptionsDialog(BuildContext context){
    AlertDialog d = AlertDialog(
      title: Text("Select an option"),
      content: Container(
        height: 140,
        child: Column(
          children: [
            GestureDetector(
              onTap: (){
                Navigator.pop(context);
                callback(message);
              },
              child: Container(
                alignment: Alignment.centerLeft,
                margin: EdgeInsets.all(5.0),
                child: Text("Edit this message"),
              ),
            ),
            GestureDetector(
              onTap: () async {
                Navigator.pop(context);
                await updateStatus("open");
              },
              child: Container(
                alignment: Alignment.centerLeft,
                margin: EdgeInsets.all(5.0),
                child: Text("Set as open"),
              ),
            ),
            GestureDetector(
              onTap: () async {
                Navigator.pop(context);
                await updateStatus("close");
              },
              child: Container(
                alignment: Alignment.centerLeft,
                margin: EdgeInsets.all(5.0),
                child: Text("Set as close"),
              ),
            ),
            GestureDetector(
              onTap: () async {
                Navigator.pop(context);
                await updateStatus("stoploss");
              },
              child: Container(
                alignment: Alignment.centerLeft,
                margin: EdgeInsets.all(5.0),
                child: Text("Stoploss hit"),
              ),
            ),
          ],
        ),
      ),
    );
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return d;
      },
    );
  }

  Future<void> updateStatus(String status) async {
    final params = {
      "timestamp": message.timestamp,
      "status": status,
      "id": message.message_id.toString()
    };
    var url = Uri.parse('${Constants.server_url}/selective_app/SelectiveTradesApp/updateStatus.php');
    var response = await http.post(url, body: params);
    if(response.body != "failure"){
      message.status = status;
      await db_helper.updateMessage(message);
      showToast("Updated");
    }
    else{
      showToast("Unable to delete");
    }
  }

  Widget videoAttachment(String url, BuildContext context){
    return Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        margin: EdgeInsets.all(5),
        padding: EdgeInsets.all(8),
        child: Image.asset('assets/images/play_button.png', width:150, height:150)
    );
  }
}
