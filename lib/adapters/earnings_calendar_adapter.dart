import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:selective_chat/models/earnings_calendar.dart';
import 'package:selective_chat/utils/widgets.dart';

class EarningsCalendarAdapter extends StatelessWidget {

  EarningsCalendar calendar;
  EarningsCalendarAdapter({this.calendar});

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
              Container(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Eps estimate: ${calendar.eps_estimate.toString()}${calendar.currency}",
                  style: primaryTextstyle(),
                ),
              ),
              Container(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Eps actual: ${calendar.eps_actual.toString()}${calendar.currency}",
                  style: primaryTextstyle(),
                ),
              ),
              Container(height: 8,),
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Difference: ${calendar.difference.toString()}${calendar.currency}",
                      style: primaryTextstyle(),
                    ),
                    Text(
                      "Surprise prc: ${calendar.surprise_pct}",
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
