import 'package:flutter/material.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:selective_chat/adapters/notification_adapter.dart';
import 'package:selective_chat/models/notification_to_display.dart';
import 'package:selective_chat/utils/push_notification_service.dart';
import 'package:selective_chat/utils/widgets.dart';

class NotificationsScreen extends StatefulWidget {

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {

  bool is_loading = false;

  List<NotificationToDisplay> notif_list = [];

  Widget title_text;

  @override
  Widget build(BuildContext context) {
    String channel_name = "Notifications";
    title_text =  Text("$channel_name");
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: title_text,
      ),
      resizeToAvoidBottomInset: false,
      body: is_loading ? loadingPage() : mainPage(),
    );
  }

  void callback() async {
    await init();
  }

  Future<void> getNotifications() async {
    notif_list = await db_helper.getNotificationsToDisplay();
    setState(() {

    });
  }

  Future<void> init() async {
    await getNotifications();
  }

  @override
  void initState(){
    init();
    super.initState();
  }

  Widget mainPage(){
    return Stack(
      children: [
        Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: notificationList(),
        ),
        notif_list.isEmpty ? noItem("Notifications will appear here", context) : Container()
      ],
    );
  }

  Widget notificationList(){
    notif_list.sort((a,b){
      return a.compareTo(b);
    });
    return GroupedListView<dynamic, String>(
      elements: notif_list,
      groupBy: (element) => element.date,
      groupSeparatorBuilder: (String groupByValue) => Text(groupByValue),
      itemBuilder: (context, dynamic element) => NotificationAdapter(notif: element, ),
      itemComparator: (item1, item2) => item1.date.compareTo(item2.date), // optional
      useStickyGroupSeparators: true, // optional
      floatingHeader: true, // optional
      order: GroupedListOrder.ASC, // optional
      groupHeaderBuilder: (dynamic element) => Container(
        height: 40,
        child: Align(
          child: Container(
            width: 120,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius:
              const BorderRadius.all(Radius.circular(10.0)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                '${element.date}',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontFamily: 'aventa_light'
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

}
