import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:selective_chat/models/ipo_calendar.dart';
import 'package:selective_chat/utils/widgets.dart';

class IPOCalendarAdapter extends StatelessWidget {

  IPOCalendar calendar;
  IPOCalendarAdapter({this.calendar});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        width: MediaQuery.of(context).size.width,
        margin: EdgeInsets.all(8),
        padding: EdgeInsets.all(10),
        child: Column(
          children: [
            Container(
              alignment: Alignment.centerLeft,
              child: Text(
                "${calendar.symbol} - ${calendar.name}",
                style: primaryTextstyle(),
              ),
            ),
            Container(height: 8,),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Price low: ${calendar.price_range_low.toString()}${calendar.currency}",
                  style: primaryTextstyle(),
                ),
                Text(
                  "Price high: ${calendar.price_range_high.toString()}${calendar.currency}",
                  style: primaryTextstyle(),
                ),
              ]
            ),
            Container(height: 8,),
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Offer price: ${calendar.offer_price.toString()}${calendar.currency}",
                    style: primaryTextstyle(),
                  ),
                  Text(
                    "Shares: ${calendar.shares}",
                    style: primaryTextstyle(),
                  ),
                ]
            ),
          ],
        )
      ),
    );
  }
}
