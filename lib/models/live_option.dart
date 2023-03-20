class LiveOption implements Comparable<LiveOption>{
  String tracker;
  String live_price;
  String pct_change;
  String timestamp;
  String status;
  String channel;

  LiveOption({
    this.tracker,
    this.live_price,
    this.pct_change,
    this.timestamp,
    this.status,
    this.channel
  });

  @override
  int compareTo(other) {
    var timestamp1 = int.parse(this.timestamp);
    var timestamp2 = int.parse(other.timestamp);
    if(timestamp1 == timestamp2){
      return 0;
    }
    else if(timestamp1 < timestamp2){
      return 1;
    }
    else if(timestamp1 > timestamp2){
      return -1;
    }
    else{
      return 0;
    }
  }

}