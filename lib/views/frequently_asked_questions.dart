import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:selective_chat/adapters/faq_adapter.dart';
import 'package:selective_chat/models/faq.dart';
import 'package:selective_chat/utils/constants.dart';
import 'package:selective_chat/utils/db_helper.dart';
import 'package:selective_chat/utils/methods.dart';
import 'package:selective_chat/utils/widgets.dart';
import 'package:http/http.dart' as http;

class FrequentlyAskedQuestions extends StatefulWidget {

  @override
  State<FrequentlyAskedQuestions> createState() => _FrequentlyAskedQuestionsState();
}

class _FrequentlyAskedQuestionsState extends State<FrequentlyAskedQuestions> {

  Icon custom_icon = const Icon(Icons.search);
  Widget title_text;
  bool is_searching = false;
  bool is_loading = false;

  TextEditingController search_controller = new TextEditingController();

  List<FAQ> questions_list = [];
  List<FAQ> search_list = [];

  double font_size = 16;

  DbHelper db_helper = new DbHelper();

  @override
  Widget build(BuildContext context) {
    if(is_searching){
      title_text = TextField(
        onTap: (){
          setState(() {
            is_searching = true;
          });
        },
        autofocus: true,
        focusNode: FocusNode(),
        autocorrect: false,
        controller: search_controller,
        onSubmitted: (String value){
          filterQuestions();
        },
        decoration: InputDecoration(
          hintText: 'Search for question',
          hintStyle: TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontFamily: 'aventa_light'
          ),
          border: InputBorder.none,
        ),
        style: TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontFamily: 'aventa_black'
        ),
      );
    }
    else{
      title_text =  Container(
          width: 150,
          child: Text("FAQ", style: TextStyle(fontSize: font_size),)
      );
    }
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: title_text,
          actions: [
            Container(width: 10,),
            searchIcon()
          ],
        ),
        resizeToAvoidBottomInset: true,
        body: is_loading ? loadingPage() : mainPage()
    );
  }

  Future<void> filterQuestions() async {
    String search_string = search_controller.text.toString().toLowerCase().trim();
    search_list = [];
    for(var i = 0; i<questions_list.length; i++){
      FAQ q = questions_list[i];
      if(q.question.toLowerCase().contains(search_string)){
        search_list.add(q);
      }
    }
    if(search_list.isNotEmpty){
      setState(() {
        is_searching = true;
      });
    }
    else{
      setState(() {
        is_searching = true;
      });
    }
  }

  Future<void> getNewQuestions() async {
    bool is_connected = await checkConnection();
    if(is_connected){
      if(questions_list.isEmpty){
        setState(() {
          is_loading = true;
        });
      }
      int last_id = 0;
      if(questions_list.isNotEmpty){
        last_id = questions_list[questions_list.length-1].id;
      }
      Map<String, dynamic> params = {
        "last_id": last_id.toString()
      };
      try{
        var url = Uri.https(Constants.server_get_url, '/selective_app/SelectiveTradesApp/getFAQs.php', params);
        var response = await http.get(url);
        if(response.body != "failure"){
          try{
            var json = jsonDecode(response.body.toString());
            List<dynamic> faqs = json;
            for(var i = 0; i < faqs.length; i++){
              FAQ f = new FAQ(
                question: faqs[i]["question"],
                answer: faqs[i]["answer"],
                date: faqs[i]["date"],
                id: int.parse(faqs[i]["id"].toString()),
              );
              await db_helper.saveFAQ(f);
              questions_list.add(f);
            }
            setState(() {
              is_loading = false;
            });
          }
          catch(e){
            print("frequently_asked_questions.getNewQuestions exception: ${e.toString}");
            setState(() {
              is_loading = false;
            });
          }
        }
        else{
          setState(() {
            is_loading = false;
          });
        }
      }
      catch(e){
        print("frequently_asked_questions.getNewQuestions: ${e.toString()}");
        setState(() {
          is_loading = false;
        });
      }
    }
  }

  Future<void> getQuestions() async {
    setState(() {
      is_loading = true;
    });
    questions_list = await db_helper.getFAQs();
    setState(() {
      is_loading = false;
    });
    if(questions_list.isEmpty){
      await getNewQuestions();
    }
  }

  Future<void> init() async {
    getQuestions();
  }

  @override
  void initState(){
    init();
    super.initState();
  }

  Widget mainPage(){
    return RefreshIndicator(
      onRefresh: getQuestions,
      child: Stack(
        children: [
          Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height - 140,
            child: questionsList(),
          ),
          questions_list.isEmpty ? noItem("No FAQs yet", context) : Container()
        ],
      ),
    );
  }

  void resetSearch(){
    search_controller.text = "";
    setState(() {
      is_searching = false;
    });
  }

  Widget searchIcon(){
    return IconButton(
      onPressed: (){
        is_searching ? resetSearch() : filterQuestions();
      },
      icon: is_searching ? Icon(Icons.close) : Icon(Icons.search),
    );
  }

  Widget questionsList(){
    if(is_searching){
      search_list.sort((a, b) {
        return a.compareTo(b);
      });
      return ListView.builder(
        controller: new ScrollController(),
        itemCount: search_list.length,
        shrinkWrap: false,
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        itemBuilder: (context, index){
          FAQ m = search_list[index];
          return FAQAdapter(question: m,);
        },
      );
    }
    else{
      questions_list.sort((a, b) {
        return a.compareTo(b);
      });
      return ListView.builder(
        controller: new ScrollController(),
        itemCount: questions_list.length,
        shrinkWrap: false,
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        itemBuilder: (context, index){
          FAQ m = questions_list[index];
          return FAQAdapter(question: m,);
        },
      );
    }
  }

}
