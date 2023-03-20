import 'package:flutter/material.dart';
import 'package:readmore/readmore.dart';
import 'package:selective_chat/models/faq.dart';

class FAQAdapter extends StatefulWidget {

  FAQ question;
  FAQAdapter({this.question});

  @override
  State<FAQAdapter> createState() => _FAQAdapterState();

}

class _FAQAdapterState extends State<FAQAdapter> {

  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 10,
      color: Colors.white,
      child: Container(
        padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: (){
                    setState(() {
                      expanded = !expanded;
                    });
                  },
                  child: Container(
                    width: MediaQuery.of(context).size.width - 80,
                    child: Text("${widget.question.question}", style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.red,
                        fontFamily: 'aventa_black'
                    ),),
                  ),
                ),
                GestureDetector(
                    onTap: (){
                      setState(() {
                        expanded = !expanded;
                      });
                    },
                    child: Padding(
                        padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
                        child: Icon(expanded ? Icons.arrow_drop_up : Icons.arrow_drop_down, color: Colors.black, size: 24,)
                    )
                )
              ],
            ),
            expanded ? Container(
              margin: EdgeInsets.fromLTRB(0, 5, 0, 0),
              width: MediaQuery.of(context).size.width,
              child: ReadMoreText(
                "${widget.question.answer}\n",
                textAlign: TextAlign.left,
                trimLines: 2,
                colorClickableText: Colors.blue,
                trimMode: TrimMode.Line,
                trimCollapsedText: 'Show more',
                trimExpandedText: 'Show less',
                moreStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: Colors.blue),
                lessStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: Colors.blue),
              ),
            ) : Container(),
            Container(height: 5,),
          ],
        ),
      ),
    );
  }
}
