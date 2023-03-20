class Channel{
  String channel_name;
  int channel_id;
  int position;
  String number_of_members;
  String members;
  String channel_image;
  String unread_messages;

  Channel({this.channel_name, this.channel_id, this.number_of_members, this.members, this.channel_image, this.unread_messages, this.position});

  @override
  int compareTo(other) {
    var a = this;
    var b = other;
    var a0 = a.position;
    var b0 = b.position;

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