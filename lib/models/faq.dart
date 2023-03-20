class FAQ {
  int id;
  String question;
  String answer;
  String date;

  FAQ({
    this.id,
    this.question,
    this.answer,
    this.date
  });

  @override
  int compareTo(other) {
    var b = this;
    var a = other;
    var a0 = a.id;
    var b0 = b.id;

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