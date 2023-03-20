class NotificationToDisplay{
  String title;
  String message;
  String channel;
  String timestamp;
  String date;
  String id;
  String screen;

  NotificationToDisplay({
    this.title,
    this.message,
    this.channel,
    this.timestamp,
    this.id,
    this.screen,
    this.date
  });

  @override
  int compareTo(other) {
    var b = this;
    var a = other;
    var a0 = -1;
    var b0 = -1;
    if(a.timestamp == ""){
      a0 = 0;
    }
    else{
      a0 = int.parse(a.timestamp);
    }

    if(b.timestamp == ""){
      b0 = 0;
    }
    else{
      b0 = int.parse(b.timestamp);
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