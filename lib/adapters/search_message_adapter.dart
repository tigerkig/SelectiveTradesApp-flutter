import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:highlight_text/highlight_text.dart';
import 'package:intl/intl.dart';
import 'package:selective_chat/models/search_message.dart';
import 'package:selective_chat/utils/widgets.dart';
import 'package:selective_chat/views/view_image_attachment.dart';

class SearchMessageAdapter extends StatelessWidget {

  SearchMessage message;

  Map<String, HighlightedWord> words;

  SearchMessageAdapter({
    this.message
  });

  @override
  Widget build(BuildContext context) {
    words = {
      message.search_string: HighlightedWord(onTap: (){} ,textStyle: TextStyle(
        fontFamily: 'aventa_bold',
        color: Colors.blue,
        fontSize: 16,
      ),)
    };
    return Card(
      child: Container(
        //width: MediaQuery.of(context).size.width,
        margin: EdgeInsets.fromLTRB(0, 5, 0, 5),
        padding: EdgeInsets.fromLTRB(3, 0, 3, 0),
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
                (message.secondary_status_timestamp == null || message.secondary_status_timestamp == "0") ? Container() : Container(
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.fromLTRB(0, 2, 5, 2),
                  width: MediaQuery.of(context).size.width-110,
                  child: Text(
                    secondary_status_date,
                    style: secondaryTextStyle(),
                  ),
                ),
              ]
          ),
          Container(
              child: Text(date, style: secondaryTextStyle(),)
          )
        ],
      ),
    );
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
