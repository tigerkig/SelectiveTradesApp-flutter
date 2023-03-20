import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:selective_chat/models/notification_to_display.dart';
import 'package:selective_chat/utils/db_helper.dart';
import 'package:selective_chat/utils/widgets.dart';

class NotificationAdapter extends StatelessWidget {

  NotificationToDisplay notif;
  Function callback;
  NotificationAdapter({this.notif, this.callback});

  DbHelper db_helper = DbHelper();

  @override
  Widget build(BuildContext context) {
    double font_size = 14;
    if(notif.channel.length > 25){
      font_size = 13;
    }
    String notif_time = DateFormat("hh:mm a").format(DateTime.fromMillisecondsSinceEpoch(int.parse(notif.timestamp)));

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
      key: Key(notif.id),
      onDismissed: (direction) async{
        await db_helper.deleteNotification(notif);
        await callback();
      },
      child: Card(
        elevation: 5,
        borderOnForeground: false,
        child: Container(
          width: MediaQuery.of(context).size.width,
          margin: EdgeInsets.all(7),
          padding: EdgeInsets.all(7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text("notif.message hdebf duhd uhd d ddhu d dhdufduf dhfdu fhdj fdfd dh dufh dj df df dfhd ofhdofhdfhdofudhfoduhf fudhfodhfdfdf dfhd dfhdfhdofhdof dfdfoh fdhfdhfo dh",style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'aventa_black',
                    overflow: TextOverflow.clip
                )),
              ),
              Container(width: 10,),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notif.channel,
                    style: TextStyle(
                        fontSize: font_size,
                        fontFamily: 'aventa_black',
                    ),
                  ),
                  Text(notif_time, style: secondaryTextStyle(),),
                  Container(height: 2,),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
