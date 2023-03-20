class EarningsCalendar {
  int id;
  String symbol;
  String name;
  String currency;
  String time;
  num eps_estimate;
  num eps_actual;
  num difference;
  num surprise_pct;
  String date;

  EarningsCalendar({
    this.id,
    this.symbol,
    this.name,
    this.currency,
    this.time,
    this.eps_estimate,
    this.eps_actual,
    this.difference,
    this.surprise_pct,
    this.date
  });

  @override
  int compareTo(other) {
    var a = this;
    var b = other;
    var a0 = -1;
    var b0 = -1;
    if(a.id == null){
      a0 = 0;
    }
    else{
      a0 = a.id;
    }

    if(b.id == null){
      b0 = 0;
    }
    else{
      b0 = b.id;
    }

    if(a0 > b0){
      return 1;
    }
    else if(a0 == b0){
      return 0;
    }
    else{
      return -1;
    }
  }
}