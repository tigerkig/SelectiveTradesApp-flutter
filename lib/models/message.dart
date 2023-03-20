class Message {
  String message_id;
  String message;
  String channel;
  String timestamp;
  String attachment;
  String attachment_type;
  String status;
  String secondary_status;
  String secondary_status_color;
  String secondary_status_timestamp;
  String message_color;

  Message({
    this.message_id,
    this.message,
    this.channel,
    this.timestamp,
    this.attachment,
    this.attachment_type,
    this.status,
    this.secondary_status,
    this.secondary_status_color,
    this.secondary_status_timestamp,
    this.message_color
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