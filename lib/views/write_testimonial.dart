import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:selective_chat/models/app_user.dart';
import 'package:selective_chat/utils/constants.dart';
import 'package:selective_chat/utils/db_helper.dart';
import 'package:selective_chat/utils/methods.dart';
import 'package:selective_chat/utils/widgets.dart';
import 'package:http/http.dart' as http;

class WriteTestimonial extends StatefulWidget {

  @override
  _WriteTestimonialState createState() => _WriteTestimonialState();
}

class _WriteTestimonialState extends State<WriteTestimonial> {

  bool is_loading = false;

  TextEditingController message_controller = new TextEditingController();

  DbHelper db_helper = new DbHelper();
  AppUser user;

  Widget bottomSheet(){
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 50,
      child: Row(
        children: [
          Expanded(
            child: Container(
              child: TextField(
                autofocus: true,
                focusNode: FocusNode(),
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
            )
          ),
          GestureDetector(
            onTap: (){
              sendTestimonial();
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
    return Scaffold(
        appBar: AppBar(
            title: Container(
                alignment: Alignment.centerLeft,
                width: MediaQuery.of(context).size.width,
                child: Text("Write a testimonial")
            )
        ),
        backgroundColor: Colors.white,
        bottomSheet: bottomSheet(),
        resizeToAvoidBottomInset: true,
        body: is_loading ? loadingPage() : mainPage()
    );
  }

  Future<void> init() async {
    setState(() {
      is_loading = true;
    });
    user = await db_helper.getAppUserSQLite();
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
    return Container(
      margin: EdgeInsets.all(10),
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height - 140,
      child: Container(
        child: Text("Hi ${user.username},\n\nWe are very excited to know your testimonial on signals and app access. Please take a moment to write a testimonial\n\nMany thanks!", style: primaryTextstyle(),),
      ),
    );
  }

  Future sendTestimonial() async {
    bool is_connected = await checkConnection();
    if(is_connected){
      if(message_controller.text.isEmpty){
        showToast("Message required");
      }
      else{
        setState(() {
          is_loading = true;
        });
        var message = message_controller.text.toString().trim();
        message += " \nEmail id: ${user.email}\nPhone number: ${user.phone_number}";
        final params = {
          "message": message,
          "user":"${user.username}",
        };
        var url = Uri.https(Constants.server_get_url,'/selective_app/SelectiveTradesApp/sendTestimonial.php', params);
        var response = await http.get(url);
        if(response.body == 'success'){
          setState(() {
            message_controller.text = "";
            showToast("Your message was received");
            Navigator.pop(context);
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
