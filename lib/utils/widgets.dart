import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

  TextStyle secondaryTextStyle(){
    return TextStyle(
      fontSize: 16,
      color: Colors.black,
      fontFamily: 'aventa_light'
    );
  }

  TextStyle primaryTextstyle(){
    return TextStyle(
      fontSize: 16,
      color: Colors.black,
      fontFamily: 'aventa_black'
    );
  }

  Widget loadingPage(){
    return Center(
      child: CircularProgressIndicator(

      ),
    );
  }

  Widget noItem(String text, BuildContext context){
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: Center(
        child: Text(
          text,
          style: primaryTextstyle(),
        ),
      ),
    );
  }