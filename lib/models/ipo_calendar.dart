class IPOCalendar {
  int id;
  String symbol;
  String name;
  String exchange;
  num price_range_low;
  num price_range_high;
  num offer_price;
  String currency;
  num shares;
  String date;

  IPOCalendar({
    this.id,
    this.symbol,
    this.name,
    this.exchange,
    this.price_range_low,
    this.price_range_high,
    this.offer_price,
    this.currency,
    this.shares,
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