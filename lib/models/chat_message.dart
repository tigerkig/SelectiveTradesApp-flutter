class ChatMessage{
  int message_id;
  int sender_id;
  String sender_name;
  String status;
  String attachment_url;
  String timestamp;
  String message;

  ChatMessage({
    this.message_id,
    this.sender_id,
    this.sender_name,
    this.timestamp,
    this.status,
    this.attachment_url,
    this.message
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