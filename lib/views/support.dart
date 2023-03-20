import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:selective_chat/models/app_user.dart';
import 'package:selective_chat/utils/constants.dart';
import 'package:selective_chat/utils/db_helper.dart';
import 'package:selective_chat/utils/methods.dart';
import 'package:selective_chat/utils/widgets.dart';

class ContactSupportScreen extends StatefulWidget {

  @override
  _ContactSupportScreenState createState() => _ContactSupportScreenState();
}

class _ContactSupportScreenState extends State<ContactSupportScreen> {

  bool is_loading = false;

  TextEditingController message_controller = new TextEditingController();
  File attachment;
  final picker = ImagePicker();

  int last_timestamp = 0;

  AppUser user;
  DbHelper db_helper = new DbHelper();

  Widget bottomSheet(){
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
    return Scaffold(
        backgroundColor: Colors.white,
        bottomSheet: bottomSheet(),
        appBar: AppBar(
            title: Container(
                alignment: Alignment.centerLeft,
                width: MediaQuery.of(context).size.width,
                child: Text("Contact support")
            )
        ),
        resizeToAvoidBottomInset: true,
        body: is_loading ? loadingPage() : mainPage()
    );
  }

  Future<void> init() async{
    user = await db_helper.getAppUserSQLite();
    setState(() {

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
        child: Text("Kindly inform us of any issues or bugs via this channel and we be in touch within 24 hours", style: primaryTextstyle(),),
      ),
    );
  }

  Future selectAttachment() async {
    final selected_image = await picker.pickImage(source: ImageSource.gallery);
    if (selected_image == null)
      return;

    var cropped_image = await ImageCropper().cropImage(
        sourcePath: selected_image.path,
        aspectRatio: CropAspectRatio(ratioX: 1, ratioY: 1));
    if (cropped_image == null)
      return;
    cropped_image = await compressImage(cropped_image.path, 80);

    setState(() {
      attachment = File(cropped_image.path);
      print("support.selectAttachment selected image ${attachment.path}");
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
          is_loading = true;
        });
        String message = message_controller.text.toString().trim();
        String attachment_url = "";
        if(attachment != null){
          attachment_url = await uploadImageToFirebase(context, attachment);
          message += "\nAttachment URL: $attachment_url";
        }
        message += " \nEmail id: ${user.email}\nPhone number: ${user.phone_number}";
        final params = {
          "message": message,
          "user":"${user.username}",
        };
        var url = Uri.https(Constants.server_get_url,'/selective_app/SelectiveTradesApp/contactSupport.php', params);
        var response = await http.get(url);
        print("support.sendMessage response ${response.body.toString()}");
        setState(() {
          message_controller.text = "";
          showToast("Your message was received");
          Navigator.pop(context);
        });
      }
    }
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
    TaskSnapshot snapshot = await FirebaseStorage.instance.ref("support_images").child("$filename").child("message_$timestamp").putFile(file);
    String image_url = await snapshot.ref.getDownloadURL();
    print("create_channel.uploadImageToFirebase image url: $image_url");
    return image_url;
  }

}
