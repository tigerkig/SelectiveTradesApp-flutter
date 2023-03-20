import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_credit_card/credit_card_brand.dart';
import 'package:flutter_credit_card/flutter_credit_card.dart';
import 'package:selective_chat/models/app_user.dart';
import 'package:selective_chat/utils/constants.dart';
import 'package:selective_chat/utils/db_helper.dart';
import 'package:selective_chat/utils/methods.dart';
import 'package:selective_chat/utils/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:selective_chat/views/splash_screen.dart';

class CardPage extends StatefulWidget {

  String subcription_tier;
  CardPage({this.subcription_tier});

  @override
  State<CardPage> createState() => _CardPageState();
}

class _CardPageState extends State<CardPage> {

  String cardNumber = '';
  String expiryDate = '';
  String expiryMonth = '';
  String expiryYear = '';
  String cardHolderName = '';
  String cvvCode = '';
  bool isCvvFocused = false;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  AppUser user;
  DbHelper db_helper = DbHelper();

  bool is_loading = false;

  Future<void> attachPaymentMethod(String paymentMethodId, String customerId) async {
    Map<String, String> headers = {
      'Authorization': 'Bearer ${Constants.stripe_secret_key}',
      'Content-Type': 'application/x-www-form-urlencoded'
    };
    final String url = 'https://api.stripe.com/v1/payment_methods/$paymentMethodId/attach';
    print("card_page.attachPaymentMethod customer id: $customerId");
    var response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: {
        'customer': customerId,
      },
    );
    if (response.statusCode == 200) {
      print("card_page.attachPaymentMethod response: ${response.body.toString()}");
    } else {
      print("card_page.attachPaymentMethod: an error occurred: ${response.body.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          leading: IconButton(
            icon:Icon(Icons.arrow_back),
            onPressed:(){
              Navigator.pop(context);
            },),
          title: Container(
              child: Text("Subscription")
          )
      ),
      resizeToAvoidBottomInset: false,
      body: is_loading ? loadingPage() : mainPage(),
    );
  }

  Future<void> cancelStripeSubscription() async {
    setState(() {
      is_loading = true;
    });

    var sub_id = user.subscription_id;
    final String url = 'https://api.stripe.com/v1/subscriptions/$sub_id';
    print("subscriptions.cancelStripeSubscription url is $url");
    Map<String, String> headers = {
      'Authorization': 'Bearer ${Constants.stripe_secret_key}',
      'Content-Type': 'application/x-www-form-urlencoded'
    };
    var response = await http.delete(
      Uri.parse(url),
      headers: headers,
    );
    if (response.statusCode == 200) {
      var json = jsonDecode(response.body.toString());
      try{
        var status = json["status"];
        if(status == "canceled"){
          setState(() {
            //is_loading = false;
          });
          AppUser temp = await db_helper.getUserByEmail(user.email);
          user.sub_type = "store";
          var firebase_token = user.firebase_tokens;
          user.firebase_tokens = temp.firebase_tokens;
          await db_helper.updateUser(user);
          user.firebase_tokens = firebase_token;
          await db_helper.updateAppUserSQLite(user);
          //showToast("Stripe subscription cancelled");
        }
        else{
          setState(() {
            is_loading = false;
          });
          showToast("An error occurred, try again");
        }
      }
      catch(e){
        setState(() {
          is_loading = false;
        });
        showToast("An error occurred, try again");
      }
    } else {
      setState(() {
        is_loading = false;
      });
      print("subscriptions.payWithStripe: an error occurred: ${response.body.toString()}");
    }
  }

  Future<String> createPaymentMethod() async {
    String payment_method_id = "";
    List<String> dates = expiryDate.split("/");
    var expiryMonth = dates[0];
    var expiryYear = dates[1];
    final params = {
      'type': 'card',
      'card[number]': cardNumber,
      'card[exp_month]': expiryMonth,
      'card[exp_year]': expiryYear,
      'card[cvc]': cvvCode,
    };
    Map<String, String> headers = {
      'Authorization': 'Bearer ${Constants.stripe_secret_key}',
      'Content-Type': 'application/x-www-form-urlencoded'
    };
    final String url = 'https://api.stripe.com/v1/payment_methods';
    var response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: params,
    );
    if (response.statusCode == 200) {
      if(response.body != ""){
        var json = jsonDecode(response.body.toString());
        payment_method_id = json["id"];
      }
    }
    else {
      print("card_page.createPaymentMethod an error occurred: ${response.body.toString()}");
    }
    return payment_method_id;
  }

  Future<void> init() async {
    setState(() {
      is_loading = true;
    });
    user = await db_helper.getAppUserSQLite();
    setState(() {
      is_loading = false;
    });
  }

  @override
  void initState(){
    init();
    super.initState();
  }

  Widget mainPage(){
    return  SingleChildScrollView(
      child: Container(
        height: MediaQuery.of(context).size.height,
        margin: EdgeInsets.fromLTRB(0, 0, 0, 30),
        color: Colors.white,
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              CreditCardWidget(
                  cardBgColor: Colors.redAccent[200],
                  cardNumber: cardNumber,
                  expiryDate: expiryDate,
                  cardHolderName: cardHolderName,
                  cvvCode: cvvCode,
                  showBackView: isCvvFocused,
                  obscureCardNumber: true,
                  obscureCardCvv: true,
                  onCreditCardWidgetChange: (CreditCardBrand card) {
                },
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      CreditCardForm(
                        formKey: formKey,
                        onCreditCardModelChange: onCreditCardModelChange,
                        obscureCvv: true,
                        obscureNumber: true,
                        cardNumberDecoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Number',
                          hintText: 'XXXX XXXX XXXX XXXX',
                        ),
                        expiryDateDecoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Expiry date',
                          hintText: 'XX/XX',
                        ),
                        cvvCodeDecoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'CVV',
                          hintText: 'XXX',
                        ),
                        cardHolderDecoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Card Holder Name',
                        ),
                        cvvCode: cvvCode,
                        cardHolderName: cardHolderName,
                        themeColor: Colors.white,
                        expiryDate: expiryDate,
                        cardNumber: cardNumber,
                      ),
                      SizedBox(height: 20,),
                      ElevatedButton(
                        child: Container(
                          margin: const EdgeInsets.all(8),
                          child: const Text(
                            'Pay with Stripe',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          primary: Color(0xff1b447b),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        onPressed: () async {
                          if (formKey.currentState.validate()) {
                            if(user.tier == "tier1" && widget.subcription_tier == Constants.tier2_subscription_price_id){
                              if(user.subscription_id.isNotEmpty){
                                await cancelStripeSubscription();
                              }
                            }
                            else if(user.tier == "tier2" && widget.subcription_tier == Constants.subscription_price_id){
                              if(user.subscription_id.isNotEmpty){
                                await cancelStripeSubscription();
                              }
                            }
                            setState(() {
                              is_loading = true;
                            });
                            String payment_method_id = await createPaymentMethod();
                            await attachPaymentMethod(payment_method_id, user.stripe_id);
                            await updateCustomer(payment_method_id, user.stripe_id);
                            await payWithStripe(user.stripe_id);
                            setState(() {
                              is_loading = false;
                            });
                            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => SplashScreen()));
                          } else {

                          }
                        },
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void onCreditCardModelChange(CreditCardModel creditCardModel) {
    setState(() {
      cardNumber = creditCardModel.cardNumber;
      expiryDate = creditCardModel.expiryDate;
      cardHolderName = creditCardModel.cardHolderName;
      cvvCode = creditCardModel.cvvCode;
      isCvvFocused = creditCardModel.isCvvFocused;
    });
  }

  Future<void> payWithStripe(String customer_id) async {
    final String url = 'https://api.stripe.com/v1/subscriptions';
    Map<String, String> headers = {
      'Authorization': 'Bearer ${Constants.stripe_secret_key}',
      'Content-Type': 'application/x-www-form-urlencoded'
    };
    var response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: {
        'customer': customer_id,
        'items[0][price]': widget.subcription_tier
      },
    );
    if (response.statusCode == 200) {
    } else {
      print("card_page.payWithStripe: an error occurred: ${response.body.toString()}");
    }
  }

  Future<void> updateCustomer(String payment_method_id, String customer_id) async {
    final String url = 'https://api.stripe.com/v1/customers/$customer_id';
    Map<String, String> headers = {
      'Authorization': 'Bearer ${Constants.stripe_secret_key}',
      'Content-Type': 'application/x-www-form-urlencoded'
    };
    var response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: {
        'invoice_settings[default_payment_method]': payment_method_id,
      },
    );
    if (response.statusCode == 200) {
    } else {
      print("card_page.updateCustomer: an error occurred: ${response.body.toString()}");
    }
  }

}
