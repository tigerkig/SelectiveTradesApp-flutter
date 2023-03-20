import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:selective_chat/utils/methods.dart';

class ViewImageAttachment extends StatefulWidget {

  String image_url;

  ViewImageAttachment({this.image_url});

  @override
  _ViewImageAttachmentState createState() => _ViewImageAttachmentState();
}

class _ViewImageAttachmentState extends State<ViewImageAttachment> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
            title: Text("Image attachment")
        ),
        body: Container(
            child: InteractiveViewer(
              panEnabled: true,
              boundaryMargin: EdgeInsets.all(1),
              child: Image.network(widget.image_url, height: MediaQuery.of(context).size.height,),
            )
        )
    );
  }

}
