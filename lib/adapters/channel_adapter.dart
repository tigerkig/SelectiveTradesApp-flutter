import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:selective_chat/models/channel.dart';
import 'package:selective_chat/views/channel_messages.dart';

class ChannelAdapter extends StatelessWidget {

  Channel channel;
  Function callback;
  ChannelAdapter({this.channel, this.callback});

  @override
  Widget build(BuildContext context) {
    int count = 0;
    if(channel.unread_messages != null && channel.unread_messages != "null")
      count = int.parse(channel.unread_messages);

    double font_size = 18;
    if(channel.channel_name.length > 25){
      font_size = 17;
    }

    return GestureDetector(
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (context) => ChannelMessages(channel: channel, callback: callback,)));
        await callback();
      },
      child: Card(
        child: Container(
          width: MediaQuery.of(context).size.width,
          margin: EdgeInsets.all(7),
          padding: EdgeInsets.all(7),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18.0,
                      backgroundImage:
                      NetworkImage("${channel.channel_image}"),
                      backgroundColor: Colors.transparent,
                    ),
                    Container(
                      margin: EdgeInsets.fromLTRB(15, 0, 0, 0),
                      child: Text(
                        channel.channel_name,
                        style: TextStyle(
                          fontSize: font_size,
                          fontFamily: 'aventa_black',
                        ),
                      ),
                    ),
                  ],
                )
              ),
              count == 0 ? Container() : ClipOval(
                child: Container(
                  color: Colors.red,
                  padding: EdgeInsets.symmetric(horizontal: 5),
                  child: Text(
                    "${channel.unread_messages}",
                    style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontFamily: 'aventa_black'
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
