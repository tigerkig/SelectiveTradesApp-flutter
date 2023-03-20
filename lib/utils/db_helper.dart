import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:selective_chat/models/app_user.dart';
import 'package:path/path.dart';
import 'package:selective_chat/models/channel.dart';
import 'package:selective_chat/models/chat_message.dart';
import 'package:selective_chat/models/earnings_calendar.dart';
import 'package:selective_chat/models/faq.dart';
import 'package:selective_chat/models/ipo_calendar.dart';
import 'package:selective_chat/models/live_option.dart';
import 'package:selective_chat/models/message.dart';
import 'package:selective_chat/models/notification_to_display.dart';
import 'package:selective_chat/models/portfolio.dart';
import 'package:selective_chat/models/watchlist.dart';
import 'package:selective_chat/utils/constants.dart';
import 'package:sqflite/sqflite.dart';
import 'methods.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:http/http.dart' as http;

//This class handles all database operations, both locally(sqflite) and online at hnitrade.com
// Some functions have replicas with the same name in the backend as php files for handling backend actions
class DbHelper{

  DbHelper._createInstance();

  String db_name = "selective_app.db";

  static Database _database;
  static DbHelper helper;

  String col_portfolio_id = "id";
  String col_portfolio_symbol = "symbol";
  String col_portfolio_buy_price = "buy_price";
  String col_portfolio_buy_date = "buy_date";
  String col_portfolio_quantity = "quantity";
  String col_portfolio_current_price = "current_price";
  String col_portfolio_net_pct_change = "net_pct_change";
  String col_portfolio_net_change = "net_change";
  String col_portfolio_total_value = "total_value";

  String col_watchlist_id = "id";
  String col_watchlist_symbol = "symbol";
  String col_watchlist_buy_price = "buy_price";
  String col_watchlist_buy_date = "buy_date";
  String col_watchlist_live_price = "live_price";
  String col_watchlist_price_change_24hr = "price_change_24hr";
  String col_watchlist_pct_change_24hr = "pct_change_24hr";
  String col_watchlist_net_change = "net_change";
  String col_watchlist_net_pct_change = "net_pct_change";

  String channels_table = "channels_table";
  String col_channel_id = "id";
  String col_channel_name = "channel_name";
  String col_channel_image = "channel_image";
  String col_number_of_members = "number_of_members";
  String col_members = "members";
  String col_channel_position = "position";

  String channel_messages_table = "channel_messages_table";
  String col_message_id = "id";
  String col_message = "message";
  String col_message_channel = "channel";
  String col_message_timestamp = "message_timestamp";
  String col_attachment = "attachment";
  String col_attachment_type = "attachment_type";
  String col_unread_messages = "unread_messages";
  String col_status = "status";
  String col_secondary_status = "secondary_status";
  String col_secondary_status_color = "secondary_status_color";
  String col_secondary_status_timestamp = "secondary_status_timestamp";
  String col_message_color = "message_color";

  String chat_messages_table = "chat_messages_table";
  String col_chat_message_id = "id";
  String col_chat_sender_id = "sender_id";
  String col_chat_sender_name = "sender_name";
  String col_chat_timestamp = "message_timestamp";
  String col_chat_status = "status";
  String col_chat_attachment_url = "attachment_url";
  String col_chat_message = "message";

  String app_user_table = "app_user_table";
  String user_table = "user_table";
  String col_user_id = "id";
  String col_stripe_id = "stripe_id";
  String col_username = "username";
  String col_email = "email";
  String col_last_login = "last_login";
  String col_phone_number = "phone_number";
  String col_date_registered = "date_registered";
  String col_expiry_date = "expiry_date";
  String col_firebase_token = "firebase_token";
  String col_user_password = "user_password";
  String col_logged_in = "logged_in";
  String col_active = "active";
  String col_app_version_ios = "app_version_ios";
  String col_app_version_android = "app_version_android";
  String col_device = "device";
  String col_ip_address = "ip_address";
  String col_profile_image_url = "profile_image_url";
  String col_user_hash = "hash";
  String col_email_notif = "email_notif";
  String col_sms_notif = "sms_notif";
  String col_sub_type = "sub_type";
  String col_subscription_id = "subscription_id";
  String col_subscription_tier = "tier";

  String earnings_calendar_table = "earnings_calendar_table";
  String col_earnings_calendar_id = "id";
  String col_earnings_calendar_symbol = "symbol";
  String col_earnings_calendar_name = "name";
  String col_earnings_calendar_currency = "currency";
  String col_earnings_calendar_time = "time";
  String col_earnings_calendar_eps_estimate = "eps_estimate";
  String col_earnings_calendar_eps_actual = "eps_actual";
  String col_earnings_calendar_difference = "difference";
  String col_earnings_calendar_surprise_pct = "surprise_pct";
  String col_earnings_calendar_date = "date";

  String ipo_calendar_table = "ipo_calendar_table";
  String col_ipo_calendar_id = "id";
  String col_ipo_calendar_symbol = "symbol";
  String col_ipo_calendar_name = "name";
  String col_ipo_calendar_exchange = "exchange";
  String col_ipo_calendar_price_range_low = "price_range_low";
  String col_ipo_calendar_price_range_high = "price_range_high";
  String col_ipo_calendar_offer_price = "offer_price";
  String col_ipo_calendar_shares = "shares";
  String col_ipo_calendar_currency = "currency";
  String col_ipo_calendar_date = "date";

  String live_option_table = "live_option_table";
  String col_live_option_id = "id";
  String col_live_option_tracker = "tracker";
  String col_live_option_live_price = "live_price";
  String col_live_option_pct_change = "pct_change";
  String col_live_option_timestamp = "timestamp";
  String col_live_option_status = "status";
  String col_live_option_channel = "channel";

  String notification_table = "notification_table";
  String col_notification_id = "id";
  String col_notification_screen = "screen";
  String col_notification_title = "title";
  String col_notification_message = "message";
  String col_notification_channel = "channel";
  String col_notification_timestamp = "timestamp";

  String faq_table = "faq_table";
  String col_question = "question";
  String col_answer = "answer";
  String col_faq_date = "date";
  String col_faq_id = "id";

  factory DbHelper(){
    if(helper == null){
      helper = DbHelper._createInstance();
    }
    return helper;
  }

  Future<Database> get database async {
    if(_database == null){
      _database = await initializeDatabase();
    }
    return _database;
  }

  Future createDb(Database db, int version) async {

    String create_faq_table = "create table $faq_table ("
        "$col_faq_id integer primary key,"
        "$col_question text,"
        "$col_answer text,"
        "$col_faq_date text)";

    String create_notification_table = "create table $notification_table ("
        "$col_notification_id integer primary key autoincrement,"
        "$col_notification_channel varchar(100),"
        "$col_notification_message varchar(200),"
        "$col_notification_timestamp varchar(100),"
        "$col_notification_title varchar(100),"
        "$col_notification_screen varchar(100))";

    String create_live_option_table = "create table $live_option_table ("
        "$col_live_option_id integer primary key autoincrement,"
        "$col_live_option_live_price double,"
        "$col_live_option_pct_change double,"
        "$col_live_option_tracker varchar(200),"
        "$col_live_option_timestamp varchar(200),"
        "$col_live_option_channel varchar(100),"
        "$col_live_option_status varchar(100))";

    String create_ipo_calendar_table = "create table $ipo_calendar_table ("
        "$col_ipo_calendar_id integer primary key autoincrement,"
        "$col_ipo_calendar_symbol varchar(100),"
        "$col_ipo_calendar_name text,"
        "$col_ipo_calendar_exchange varchar(100),"
        "$col_ipo_calendar_price_range_low double,"
        "$col_ipo_calendar_price_range_high double,"
        "$col_ipo_calendar_offer_price double,"
        "$col_ipo_calendar_shares double,"
        "$col_ipo_calendar_date varchar(100),"
        "$col_ipo_calendar_currency varchar(100))";

    String create_earnings_calendar_table = "create table $earnings_calendar_table ("
        "$col_earnings_calendar_id integer primary key autoincrement,"
        "$col_earnings_calendar_symbol varchar(100),"
        "$col_earnings_calendar_name text,"
        "$col_earnings_calendar_currency varchar(100),"
        "$col_earnings_calendar_time varchar(255),"
        "$col_earnings_calendar_eps_estimate double,"
        "$col_earnings_calendar_eps_actual double,"
        "$col_earnings_calendar_difference double,"
        "$col_earnings_calendar_date varchar(100),"
        "$col_earnings_calendar_surprise_pct double)";

    String create_app_user_table = "create table $app_user_table ("
        "$col_user_id integer primary key, "
        "$col_stripe_id text,"
        "$col_profile_image_url text,"
        "$col_ip_address text,"
        "$col_device varchar(200),"
        "$col_app_version_ios varchar(200),"
        "$col_app_version_android varchar(200),"
        "$col_active varchar(200),"
        "$col_logged_in varchar(200),"
        "$col_last_login varchar(100),"
        "$col_user_password varchar(200),"
        "$col_firebase_token text,"
        "$col_expiry_date varchar(200),"
        "$col_date_registered varchar(200),"
        "$col_phone_number varchar(200),"
        "$col_username varchar(200),"
        "$col_user_hash varchar(500),"
        "$col_email varchar(200),"
        "$col_email_notif varchar(12),"
        "$col_sms_notif varchar(12),"
        "$col_sub_type varchar(10),"
        "$col_subscription_id text,"
        "$col_subscription_tier text)";

    String create_user_table = "create table $user_table ("
        "$col_user_id integer primary key, "
        "$col_profile_image_url text,"
        "$col_ip_address text,"
        "$col_device varchar(200),"
        "$col_app_version_ios varchar(200),"
        "$col_app_version_android varchar(200),"
        "$col_active varchar(200),"
        "$col_logged_in varchar(200),"
        "$col_user_password varchar(200),"
        "$col_firebase_token text,"
        "$col_expiry_date varchar(200),"
        "$col_date_registered varchar(200),"
        "$col_phone_number varchar(200),"
        "$col_username varchar(200),"
        "$col_user_hash varchar(500),"
        "$col_email varchar(200),"
        "$col_sms_notif varchar(12),"
        "$col_email_notif varchar(12))";

    String create_crypto_portfolio_table = "create table ${Constants.crypto_portfolio} ("
        "$col_portfolio_id integer primary key,"
        "$col_portfolio_symbol varchar(80),"
        "$col_portfolio_buy_price double,"
        "$col_portfolio_quantity double,"
        "$col_portfolio_current_price double,"
        "$col_portfolio_net_change double,"
        "$col_portfolio_net_pct_change double,"
        "$col_portfolio_total_value double,"
        "$col_portfolio_buy_date varchar(80))";

    String create_stock_portfolio_table = "create table ${Constants.stock_portfolio} ("
        "$col_portfolio_id integer primary key,"
        "$col_portfolio_symbol varchar(80),"
        "$col_portfolio_buy_price double,"
        "$col_portfolio_quantity double,"
        "$col_portfolio_current_price double,"
        "$col_portfolio_net_change double,"
        "$col_portfolio_net_pct_change double,"
        "$col_portfolio_total_value double,"
        "$col_portfolio_buy_date varchar(80))";

    String create_crypto_watchlist_table = "create table ${Constants.crypto_watchlist} ("
        "$col_watchlist_id integer primary key,"
        "$col_watchlist_symbol varchar(80),"
        "$col_watchlist_buy_date varchar(80),"
        "$col_watchlist_live_price double,"
        "$col_watchlist_pct_change_24hr double,"
        "$col_watchlist_net_pct_change double,"
        "$col_watchlist_price_change_24hr double,"
        "$col_watchlist_net_change double,"
        "$col_watchlist_buy_price double)";

    String create_stock_watchlist_table = "create table ${Constants.stock_watchlist} ("
        "$col_watchlist_id integer primary key,"
        "$col_watchlist_symbol varchar(80),"
        "$col_watchlist_buy_date varchar(80),"
        "$col_watchlist_live_price double,"
        "$col_watchlist_pct_change_24hr double,"
        "$col_watchlist_net_pct_change double,"
        "$col_watchlist_price_change_24hr double,"
        "$col_watchlist_net_change double,"
        "$col_watchlist_buy_price double)";

    String create_channel_messages_table = "create table $channel_messages_table ("
        "$col_message_id integer primary key, "
        "$col_message text, "
        "$col_message_channel varchar(100),"
        "$col_message_timestamp integer, "
        "$col_attachment text, "
        "$col_attachment_type varchar(20),"
        "$col_secondary_status text,"
        "$col_secondary_status_color varchar(20),"
        "$col_secondary_status_timestamp integer,"
        "$col_status varchar(10),"
        "$col_message_color varchar(10))";

    String create_channels_table = "create table $channels_table ("
        "$col_channel_id integer primary key, "
        "$col_channel_name text, "
        "$col_channel_image text,"
        "$col_number_of_members integer,"
        "$col_unread_messages integer,"
        "$col_channel_position integer,"
        "$col_members text)";

    String create_chat_messages_table = "create table $chat_messages_table ("
        "$col_chat_message_id integer primary key autoincrement, "
        "$col_chat_sender_id integer,"
        "$col_chat_sender_name varchar(100),"
        "$col_chat_timestamp varchar(100),"
        "$col_chat_status varchar(100),"
        "$col_chat_attachment_url text,"
        "$col_chat_message text)";

    await db.execute(create_faq_table);
    await db.execute(create_chat_messages_table);
    await db.execute(create_app_user_table);
    await db.execute(create_live_option_table);
    await db.execute(create_ipo_calendar_table);
    await db.execute(create_earnings_calendar_table);
    await db.execute(create_crypto_portfolio_table);
    await db.execute(create_stock_portfolio_table);
    await db.execute(create_stock_watchlist_table);
    await db.execute(create_crypto_watchlist_table);
    await db.execute(create_user_table);
    await db.execute(create_channel_messages_table);
    await db.execute(create_channels_table);
    await db.execute(create_notification_table);
  }

  Future<void> clearChannelNotificationCount(String channel_name) async {
    Database db = await this.database;
    String query = "update $channels_table set $col_unread_messages = 0 where $col_channel_name = '$channel_name'";
    await db.execute(query);
  }

  Future<void> clearPortfolioTable(String from) async {
    Database db = await this.database;
    String query = "delete from ${from}";
    await db.execute(query);
  }

  Future<void> clearWatchlistTable(String from) async {
    Database db = await this.database;
    String query = "delete from ${from}";
    await db.execute(query);
  }

  Future<void> deleteChannel(Channel channel) async {
    Database db = await this.database;
    String query = "delete from $channels_table where $col_channel_id='${channel.channel_id}' and $col_channel_name='${channel.channel_name}'";
    await db.execute(query);
  }

  Future<void> deleteChannelTable() async {
    Database db = await this.database;
    String query = "delete from $channels_table";
    await db.execute(query);
  }

  Future<void> deleteChatTextMessage(types.TextMessage message) async {
    Database db = await this.database;
    String query = "delete from $chat_messages_table where $col_chat_timestamp='${message.createdAt}' and $col_chat_message='${message.text}'";
    await db.execute(query);
  }

  Future<void> deleteDatabase() async {
    Database db = await this.database;
    String delete_user_table = "delete from $user_table";
    String delete_app_user_table = "delete from $app_user_table";
    String delete_crypto_portfolio = "delete from ${Constants.crypto_portfolio}";
    String delete_stock_portfolio = "delete from ${Constants.stock_portfolio}";
    String delete_crypto_watchlist = "delete from ${Constants.crypto_watchlist}";
    String delete_stock_watchlist = "delete from ${Constants.stock_watchlist}";
    String delete_ipo = "delete from $ipo_calendar_table";
    String delete_earnings = "delete from $earnings_calendar_table";
    String delete_channels = "delete from $channels_table";
    String delete_channel_messages = "delete from $channel_messages_table";
    String delete_live_options = "delete from $live_option_table";
    String delete_faq = "delete from $faq_table";

    await db.execute(delete_faq);
    await db.execute(delete_live_options);
    await db.execute(delete_app_user_table);
    await db.execute(delete_channel_messages);
    await db.execute(delete_channels);
    await db.execute(delete_earnings);
    await db.execute(delete_ipo);
    await db.execute(delete_crypto_watchlist);
    await db.execute(delete_stock_watchlist);
    await db.execute(delete_stock_portfolio);
    await db.execute(delete_crypto_portfolio);
    await db.execute(delete_user_table);
  }

  Future<void> deleteEarningsCalendar(String date) async {
    Database db = await this.database;
    String query = "delete from $earnings_calendar_table where $col_earnings_calendar_date=$date";
    await db.execute(query);
  }

  Future<void> deleteFAQ(int id) async {
    Database db = await this.database;
    String query = "delete from $faq_table where $col_faq_id=$id";
    await db.execute(query);
  }

  Future<void> deleteIPOCalendar(String date) async {
    Database db = await this.database;
    String query = "delete from $ipo_calendar_table where $col_ipo_calendar_date='$date'";
    await db.execute(query);
  }

  Future<void> deleteLiveOptions() async {
    Database db = await this.database;
    String query = "delete from $live_option_table";
    await db.execute(query);
  }

  Future<void> deleteMessage(Message message) async {
    Database db = await this.database;
    String query = "delete from $channel_messages_table where $col_message_id=${message.message_id} and $col_message='${message.message}'";
    await db.execute(query);
  }

  Future<void> deleteNotification(NotificationToDisplay notif) async {
    Database db = await this.database;
    String query = "delete from $notification_table where $col_notification_id=${int.parse(notif.id)}";
    await db.execute(query);
  }

  Future<void> deleteNotificationToDisplay() async {
    Database db = await this.database;
    String query = "delete from $notification_table";
    await db.execute(query);
  }

  Future<void> deletePortfolio(Portfolio p, String from) async {
    Database db = await this.database;
    String query = "delete from $from where $col_portfolio_id=${int.parse(p.id)}";
    await db.execute(query);
  }

  Future<void> deleteWatchlist(Watchlist w, String from) async {
    Database db = await this.database;
    String query = "delete from $from where $col_watchlist_id=${int.parse(w.id)}";
    await db.execute(query);
  }

  Future<List<Message>> getAllMessagesSQLite(String channel_name) async {
    List<Message> list = [];
    Database db = await this.database;
    String query = "select * from $channel_messages_table where $col_message_channel='$channel_name'";
    List<Map<String, Object>> result = await db.rawQuery(query);
    for(var i = 0; i<result.length; i++){
      list.add(Message(
          message_id: result[i]["$col_message_id"].toString(),
          message: result[i]["$col_message"],
          timestamp: result[i]["$col_message_timestamp"].toString(),
          channel: result[i]["$col_message_channel"],
          attachment: result[i]["$col_attachment"],
          attachment_type: result[i]["$col_attachment_type"],
          status: result[i]["$col_status"],
          secondary_status: result[i]["$col_secondary_status"],
          secondary_status_color: result[i]["$col_secondary_status_color"],
          secondary_status_timestamp: result[i]["$col_secondary_status_timestamp"].toString(),
          message_color: result[i]["$col_message_color"]
      ));
    }
    return list;
  }

  Future<void> getAndSaveNewUsers() async {
    Database db = await this.database;
    String get_max_timestamp = "select max($col_date_registered) as m from $user_table";
    List<Map<String, Object>> result = await db.rawQuery(get_max_timestamp);
    String max_timestamp = result[0]["m"].toString();
    if(max_timestamp == null || max_timestamp == ""){
      max_timestamp = "0";
    }

    Map<String, String> params = {"max_timestamp":"$max_timestamp"};
    var url = Uri.https(Constants.server_get_url, '/selective_app/SelectiveTradesApp/getNewUsers.php', params);
    var response = await http.get(url);
    if(response.body != "failure"){
      var json = jsonDecode(response.body);
      List<dynamic> l = json;
      for(var i = 0; i<l.length; i++){
        AppUser a = AppUser(
            id: l[i]["$col_user_id"],
            username: l[i]["$col_username"],
            email: l[i]["$col_email"],
            phone_number: l[i]["$col_phone_number"],
            date_registered:l[i]["$col_date_registered"],
            expiry_date: l[i]["$col_expiry_date"],
            firebase_tokens: l[i]["firebase_tokens"],
            user_password: l[i]["$col_user_password"],
            logged_in: l[i]["$col_logged_in"],
            active: l[i]["$col_active"],
            app_version_ios: l[i]["$col_app_version_ios"],
            app_version_android: l[i]["$col_app_version_android"],
            device: l[i]["$col_device"],
            ip_address: l[i]["$col_ip_address"],
            profile_image_url: l[i]["$col_profile_image_url"],
            hash: l[i]["$col_user_hash"],
            email_notif: l[i]["$col_email_notif"],
            sms_notif: l[i]["$col_sms_notif"],
        );
        try{
          await saveUserSQLite(a);
        }
        catch(e){
          print("db_helper.getAndSaveNewUsers exception ${e.toString()}");
        }
      }
    }
  }

  Future<void> getAndSaveExpiryDates() async {
    var url = Uri.http(Constants.server_get_url, '/selective_app/SelectiveTradesApp/getExpiryDates.php');
    var response = await http.get(url);
    if(response.body != 'failure'){
      var json = jsonDecode(response.body);
      List<dynamic> l = json;
      List<AppUser> user_list = [];
      for(var i = 0; i<l.length; i++){
        AppUser a = AppUser(
          email: l[i]["email"].toString(),
          expiry_date: l[i]["expiry_date"].toString(),
        );
        user_list.add(a);
      }
      await updateExpiryDates(user_list);
    }
  }

  Future<void> getAndSaveFirebaseTokens() async {
    print("db_helper.getAndSaveFirebaseTokens");
    var url = Uri.http(Constants.server_get_url, '/selective_appSelectiveTradesApp/getFirebaseTokens.php');
    var response = await http.get(url);
    if(response.body != 'failure'){
      var json = jsonDecode(response.body);
      List<dynamic> l = json;
      List<AppUser> user_list = [];
      for(var i = 0; i<l.length; i++){
        AppUser a = AppUser(
          email: l[i]["email"].toString(),
          firebase_tokens: l[i]["firebase_tokens"].toString(),
        );
        user_list.add(a);
      }
      await updateFirebaseTokens(user_list);
    }
  }

  Future<List<Channel>> getChannelsSQLite() async {
    AppUser user = await getAppUserSQLite();
    List<Channel> list = [];
    Database db = await this.database;
    String query = "select * from $channels_table";
    List<Map<String, Object>> result = await db.rawQuery(query);
    for(var i = 0; i<result.length; i++){
      Channel c = Channel(
          channel_name: result[i]["$col_channel_name"],
          channel_id: result[i]["$col_channel_id"],
          number_of_members: result[i]["$col_number_of_members"].toString(),
          members: result[i]["$col_members"],
          channel_image: result[i]["$col_channel_image"],
          unread_messages: result[i]["$col_unread_messages"].toString(),
          position: result[i]["$col_channel_position"]
      );
      list.add(c);
    }
    if(user.tier == "tier1"){
      list.removeWhere((element){
        if(element.channel_name.toLowerCase().trim() == "futures signals"){
          return true;
        }
        return false;
      });
    }
    else if(user.tier == "tier2"){
      list.removeWhere((element){
        if(element.channel_name.toLowerCase().trim() == "options - 100k target"){
          return true;
        }
        return false;
      });

      list.removeWhere((element){
        if(element.channel_name.toLowerCase().trim() == "option signals"){
          return true;
        }
        return false;
      });

      list.removeWhere((element){
        if(element.channel_name.toLowerCase().trim() == "option leap signals"){
          return true;
        }
        return false;
      });

    }
    return list;
  }

  Future<int> getChannelUnreadMessagesCount(String channel_name) async {
    int unread_count= 0;
    Database db = await this.database;
    String query = "select $col_unread_messages from $channels_table where $col_channel_name='$channel_name'";
    List<Map<String, Object>> result = await db.rawQuery(query);
    unread_count = result[0]["$col_unread_messages"];
    if(unread_count == null)
      return 0;
    return unread_count;
  }

  Future<List<ChatMessage>> getChatMessages() async {
    List<ChatMessage> list = [];
    Database db = await this.database;
    String query = "select * from $chat_messages_table";
    List<Map<String, Object>> result = await db.rawQuery(query);
    for(var i = 0; i<result.length; i++){
      list.add(ChatMessage(
        sender_id: result[i][col_chat_sender_id],
        sender_name: result[i][col_chat_sender_name],
        status: result[i][col_chat_status],
        attachment_url: result[i][col_chat_attachment_url],
        timestamp: result[i][col_chat_timestamp],
        message: result[i][col_chat_message],
      ));
    }
    return list;
  }

  Future<List<ChatMessage>> getChatMessagesForNewUser(String date_registered) async {
    List<ChatMessage> list = [];
    final params = {
      "date_registered": date_registered
    };
    var url = Uri.https(Constants.server_get_url, '/selective_app/SelectiveTradesApp/getChatMessagesForNewUser.php', params);
    var response = await http.get(url);
    if(response.statusCode == 200){
      if(response.body != 'failure'){
        //print("db_helper.getChatMessagesForNewUser response ${response.body}");
        var json = jsonDecode(response.body);
        List<dynamic> l = json;
        for(var i = 0; i<l.length; i++){
          ChatMessage m = ChatMessage(
              message_id: l[i][col_chat_message_id],
              message: l[i][col_chat_message],
              timestamp: l[i][col_chat_timestamp],
              attachment_url: l[i][col_chat_attachment_url],
              status: l[i][col_chat_status],
              sender_name: l[i][col_chat_sender_name],
              sender_id: l[i][col_chat_sender_id]
          );
          await saveChatMessageSQLite(m);
          list.add(m);
        }
      }
    }
    else{
      print("DbHelper.getChatMessagesForNewUser response exception : ${response.body}");
    }
    return list;
  }

  Future<List<Portfolio>> getCryptoPortfolioSQLite() async {
    List<Portfolio> list = [];
    Database db = await this.database;
    String query = "select * from ${Constants.crypto_portfolio}";
    List<Map<String, Object>> result = await db.rawQuery(query);
    for(var i = 0; i<result.length; i++){
      list.add(Portfolio(
          id: result[i]["$col_portfolio_id"].toString(),
          symbol: result[i]["$col_portfolio_symbol"],
          buy_price: result[i]["$col_portfolio_buy_price"],
          buy_date: result[i]["$col_portfolio_buy_date"],
          quantity: result[i]["$col_portfolio_quantity"],
          net_change: result[i]["$col_portfolio_net_change"],
          total_value: result[i]["$col_portfolio_total_value"],
          net_pct_change: result[i]["$col_portfolio_net_pct_change"],
          current_price: result[i]["$col_portfolio_current_price"]
      ));
    }
    return list;
  }

  Future<List<Watchlist>> getCryptoWatchlistSQLite() async {
    List<Watchlist> list = [];
    Database db = await this.database;
    String query = "select * from ${Constants.crypto_watchlist}";
    List<Map<String, Object>> result = await db.rawQuery(query);
    for(var i = 0; i<result.length; i++){
      list.add(Watchlist(
          id: result[i]["$col_watchlist_id"].toString(),
          symbol: result[i]["$col_watchlist_symbol"],
          buy_price: result[i]["$col_watchlist_buy_price"],
          buy_date: result[i]["$col_watchlist_buy_date"],
          net_pct_change: result[i]["$col_watchlist_net_pct_change"],
          net_change: result[i]["$col_watchlist_net_change"],
          pct_change_24hr: result[i]["$col_watchlist_pct_change_24hr"],
          price_change_24hr: result[i]["$col_watchlist_price_change_24hr"],
          live_price: result[i]["$col_watchlist_live_price"]
      ));
    }
    return list;
  }

  Future<void> getDeletedChannels() async {
    var url = Uri.https(Constants.server_get_url, '/selective_app/SelectiveTradesApp/getDeletedChannels.php');
    var response = await http.get(url);
    if(response.statusCode == 200){
      if(response.body != 'failure'){
        var json = jsonDecode(response.body);
        List<dynamic> channels = json;
        for(var i = 0; i<channels.length; i++){
          Channel c = new Channel(
              channel_id: int.parse(channels[i]["id"]),
              channel_name: channels[i]["channel_name"],
              number_of_members: channels[i]["number_of_members"],
              members: channels[i]["members"],
              channel_image: channels[i]["channel_image"]
          );
          await deleteChannel(c);
        }
      }
    }
    else{
      print("DbHelper.getDeletedChannels response exception : ${response.body}");
    }
  }

  Future<void> getDeletedMessages(String channel) async {
    final params = {
      "channel": channel
    };
    var url = Uri.https(Constants.server_get_url, '/selective_app/SelectiveTradesApp/getDeletedMessages.php', params);
    var response = await http.get(url);
    if(response.statusCode == 200){
      if(response.body != 'failure'){
        var json = jsonDecode(response.body);
        List<dynamic> l = json;
        for(var i = 0; i<l.length; i++){
          Message m = Message(
              message_id: l[i]["$col_message_id"],
              message: l[i]["$col_message"],
              channel: l[i]["$col_message_channel"],
              timestamp: l[i]["$col_message_timestamp"],
              attachment: l[i]["$col_attachment"],
              attachment_type: l[i]["$col_attachment_type"],
              status: l[i]["$col_status"],
              secondary_status: l[i]["$col_secondary_status"],
              secondary_status_color: l[i]["$col_secondary_status_color"],
              secondary_status_timestamp: l[i]["$col_secondary_status_timestamp"],
              message_color: l[i]["$col_message_color"],
          );
          await deleteMessage(m);
        }
      }
    }
    else{
      print("DbHelper.getDeletedMessages response exception : ${response.body}");
    }
  }

  Future<List<EarningsCalendar>> getEarningsCalendar(String date) async {
    List<EarningsCalendar> list = [];
    Database db = await this.database;
    String query = "select * from $earnings_calendar_table where $col_earnings_calendar_date='$date'";
    List<Map<String, Object>> result = await db.rawQuery(query);
    for(var i = 0; i<result.length; i++){
      list.add(EarningsCalendar(
        id: result[i]["$col_earnings_calendar_id"],
        symbol: result[i]["$col_earnings_calendar_symbol"],
        name: result[i]["$col_earnings_calendar_name"],
        surprise_pct: result[i]["$col_earnings_calendar_surprise_pct"],
        difference: result[i]["$col_earnings_calendar_difference"],
        eps_actual: result[i]["$col_earnings_calendar_eps_actual"],
        eps_estimate: result[i]["$col_earnings_calendar_eps_estimate"],
        time: result[i]["$col_earnings_calendar_time"],
        currency: result[i]["$col_earnings_calendar_currency"],
        date: result[i]["$col_earnings_calendar_date"]
      ));
    }
    return list;
  }

  Future<void> getEditedMessages(String channel_name) async {
    final params = {
      "channel": channel_name,
    };
    var url = Uri.https(Constants.server_get_url, '/selective_app/SelectiveTradesApp/getEditedMessages.php', params);
    var response = await http.get(url);
    if(response.statusCode == 200){
      if(response.body != 'failure'){
        var json = jsonDecode(response.body);
        List<dynamic> l = json;
        for(var i = 0; i<l.length; i++){
          Message m = Message(
              message_id: l[i]["$col_message_id"],
              message: l[i]["$col_message"],
              channel: l[i]["$col_message_channel"],
              timestamp: l[i]["$col_message_timestamp"],
              attachment: l[i]["$col_attachment"],
              attachment_type: l[i]["$col_attachment_type"],
              status: l[i]["$col_status"],
              secondary_status: l[i]["$col_secondary_status"],
              secondary_status_color: l[i]["$col_secondary_status_color"],
              secondary_status_timestamp: l[i]["$col_secondary_status_timestamp"],
              message_color: l[i]["$col_message_color"],
          );
          await updateMessage(m);
        }
      }
    }
    else{
      print("DbHelper.getEditedMessages response exception : ${response.body}");
    }
  }

  Future<List<String>> getFirebaseTokensSQLite() async {
    List<String> firebase_tokens = [];
    Database db = await this.database;
    String query = "select * from $user_table";
    List<Map<String, Object>> result = await db.rawQuery(query);
    for(var i =0;i<result.length; i++){
      int now = DateTime.now().millisecondsSinceEpoch;
      int expiry = int.parse(result[i]["$col_expiry_date"]);
      if(expiry > now){
        if(result[i]["$col_firebase_token"] != null && result[i]["$col_firebase_token"].toString().isNotEmpty){
          try{
            final json = jsonDecode(result[i]["$col_firebase_token"]);
            List<dynamic> l = json["firebase_tokens"];
            for(var i = 0; i<l.length; i++){
              firebase_tokens.add(l[i].toString());
            }
          }
          catch(e){
            print("db_helper.getFirebaseTokensSQLite exception for ${result[i]["$col_username"]} ${e.toString()}");
          }

        }
      }
    }
    print("db_helper.getFirebaseTokensSQLite sending notifications to ${firebase_tokens.length} users");
    return firebase_tokens;
  }

  Future<List<IPOCalendar>> getIPOCalendar(String date) async {
    List<IPOCalendar> list = [];
    Database db = await this.database;
    String query = "select * from $ipo_calendar_table where $col_ipo_calendar_date='$date'";
    List<Map<String, Object>> result = await db.rawQuery(query);
    for(var i = 0; i<result.length; i++){
      list.add(IPOCalendar(
        date: result[i]["$col_ipo_calendar_date"],
        name: result[i]["$col_ipo_calendar_name"],
        exchange: result[i]["$col_ipo_calendar_exchange"],
        symbol: result[i]["$col_ipo_calendar_symbol"],
        price_range_high: result[i]["$col_ipo_calendar_price_range_high"],
        price_range_low: result[i]["$col_ipo_calendar_price_range_low"],
        offer_price: result[i]["$col_ipo_calendar_offer_price"],
        currency: result[i]["$col_ipo_calendar_currency"],
        shares: result[i]["$col_ipo_calendar_shares"],
        id: result[i]["$col_ipo_calendar_id"],
      ));
    }
    return list;
  }

  Future<void> getLatestDeletedChatMessages(String last_login) async {
    final params = {
      "last_login": last_login
    };
    var url = Uri.https(Constants.server_get_url, '/selective_app/SelectiveTradesApp/getLatestDeletedChatMessages.php', params);
    var response = await http.get(url);
    if(response.statusCode == 200){
      if(response.statusCode == 200){
        if(response.body != 'failure'){
          //print("db_helper.getLatestDeletedChatMessages response ${response.body}");
          var json = jsonDecode(response.body);
          List<dynamic> l = json;
          for(var i = 0; i<l.length; i++){
            ChatMessage m = ChatMessage(
                message_id: int.parse(l[i][col_chat_message_id]),
                message: l[i][col_chat_message],
                timestamp: l[i][col_chat_timestamp],
            );
            types.TextMessage text_message = types.TextMessage(
              createdAt: int.parse(m.timestamp),
              text: m.message
            );
            await deleteChatTextMessage(text_message);
          }
        }
      }
    }
    else{
      print("DbHelper.getLatestDeletedChatMessages response exception : ${response.body}");
    }
  }

  Future<void> getLatestDeletedMessages(String last_login) async {
    final params = {
      "last_login": last_login,
    };
    var url = Uri.https(Constants.server_get_url, '/selective_app/SelectiveTradesApp/getLatestDeletedMessages.php', params);
    var response = await http.get(url);
    if(response.statusCode == 200){
      if(response.body != 'failure'){
        var json = jsonDecode(response.body);
        List<dynamic> l = json;
        for(var i = 0; i<l.length; i++){
          Message m = Message(
              message_id: l[i]["$col_message_id"],
              message: l[i]["$col_message"],
              channel: l[i]["$col_message_channel"],
              timestamp: l[i]["$col_message_timestamp"],
              attachment: l[i]["$col_attachment"],
              attachment_type: l[i]["$col_attachment_type"],
              status: l[i]["$col_status"],
              secondary_status: l[i]["$col_secondary_status"],
              secondary_status_color: l[i]["$col_secondary_status_color"],
              secondary_status_timestamp: l[i]["$col_secondary_status_timestamp"],
              message_color: l[i]["$col_message_color"],
          );
          await deleteMessage(m);
        }
      }
    }
    else{
      print("DbHelper.getLatestDeletedMessages response exception : ${response.body}");
    }
  }

  Future<void> getLatestEditedMessages(String last_login) async {
    final params = {
      "last_login": last_login,
    };
    var url = Uri.https(Constants.server_get_url, '/selective_app/SelectiveTradesApp/getLatestEditedMessages.php', params);
    var response = await http.get(url);
    if(response.statusCode == 200){
      if(response.body != 'failure'){
        var json = jsonDecode(response.body);
        List<dynamic> l = json;
        for(var i = 0; i<l.length; i++){
          Message m = Message(
            message_id: l[i]["$col_message_id"],
            message: l[i]["$col_message"],
            channel: l[i]["$col_message_channel"],
            timestamp: l[i]["$col_message_timestamp"],
            attachment: l[i]["$col_attachment"],
            attachment_type: l[i]["$col_attachment_type"],
            status: l[i]["$col_status"],
            secondary_status: l[i]["$col_secondary_status"],
            secondary_status_color: l[i]["$col_secondary_status_color"],
            secondary_status_timestamp: l[i]["$col_secondary_status_timestamp"],
            message_color: l[i]["$col_message_color"],
          );
          await updateMessage(m);
        }
      }
    }
    else{
      print("DbHelper.getLatestEditedMessages response exception : ${response.body}");
    }
  }

  Future<void> getLatestSecondaryStatus(String last_login) async {
    final params = {
      "last_login": last_login,
    };
    var url = Uri.https(Constants.server_get_url, '/selective_app/SelectiveTradesApp/getLatestSecondaryStatus.php', params);
    var response = await http.get(url);
    if(response.statusCode == 200){
      if(response.body != 'failure'){
        var json = jsonDecode(response.body);
        List<dynamic> l = json;
        for(var i = 0; i<l.length; i++){
          Message m = Message(
            message_id: l[i]["$col_message_id"],
            message: l[i]["$col_message"],
            channel: l[i]["$col_message_channel"],
            timestamp: l[i]["$col_message_timestamp"],
            attachment: l[i]["$col_attachment"],
            attachment_type: l[i]["$col_attachment_type"],
            status: l[i]["$col_status"],
            secondary_status: l[i]["$col_secondary_status"],
            secondary_status_color: l[i]["$col_secondary_status_color"],
            secondary_status_timestamp: l[i]["$col_secondary_status_timestamp"],
            message_color: l[i]["$col_message_color"],
          );
          await updateMessage(m);
        }
      }
    }
    else{
      print("DbHelper.getLatestSecondaryStatus response exception : ${response.body}");
    }
  }

  Future<List<LiveOption>> getLiveOptions() async {
    List<LiveOption> list = [];
    Database db = await this.database;
    String query = "select * from $live_option_table";
    List<Map<String, Object>> result = await db.rawQuery(query);
    for(var i = 0; i<result.length; i++){
      list.add(LiveOption(
        timestamp: result[i]["$col_live_option_timestamp"],
        tracker: result[i]["$col_live_option_tracker"],
        pct_change: result[i]["$col_live_option_pct_change"].toString(),
        live_price: result[i]["$col_live_option_live_price"].toString(),
        status: result[i]["$col_live_option_status"].toString(),
        channel: result[i]["$col_live_option_channel"].toString(),
      ));
    }
    return list;
  }

  Future<int> getMessagesCount() async {
    Database db = await this.database;
    String query = "select count(*) as total from $channel_messages_table";
    List<Map<String, Object>> result = await db.rawQuery(query);
    return result[0]["total"];
  }

  Future<List<Message>> getMessagesSQLite(String channel_name) async{
    List<Message> list = [];
    Database db = await this.database;
    String query = "select * from $channel_messages_table where $col_message_channel='$channel_name' order by $col_message_id desc limit 17";
    List<Map<String, Object>> result = await db.rawQuery(query);
    for(var i = 0; i<result.length; i++){
      list.add(Message(
          message_id: result[i]["$col_message_id"].toString(),
          message: result[i]["$col_message"],
          timestamp: result[i]["$col_message_timestamp"].toString(),
          channel: result[i]["$col_message_channel"],
          attachment: result[i]["$col_attachment"],
          attachment_type: result[i]["$col_attachment_type"],
          status: result[i]["$col_status"],
          secondary_status: result[i]["$col_secondary_status"],
          secondary_status_color: result[i]["$col_secondary_status_color"],
          secondary_status_timestamp: result[i]["$col_secondary_status_timestamp"].toString(),
          message_color: result[i]["$col_message_color"],
      ));
    }
    return list;
  }

  Future<List<Message>> getMoreMessages(String channel_name, int id) async {
    List<Message> list = [];
    Database db = await this.database;
    String query = "select * from $channel_messages_table where $col_message_channel='$channel_name' and $col_message_id<$id order by id desc limit 17";
    List<Map<String, Object>> result = await db.rawQuery(query);
    for(var i = 0; i<result.length; i++){
      list.add(Message(
          message_id: result[i]["$col_message_id"].toString(),
          message: result[i]["$col_message"],
          timestamp: result[i]["$col_message_timestamp"].toString(),
          channel: result[i]["$col_message_channel"],
          attachment: result[i]["$col_attachment"],
          attachment_type: result[i]["$col_attachment_type"],
          status: result[i]["$col_status"],
          secondary_status: result[i]["$col_secondary_status"],
          secondary_status_color: result[i]["$col_secondary_status_color"],
          secondary_status_timestamp: result[i]["$col_secondary_status_timestamp"].toString(),
          message_color: result[i]["$col_message_color"],
      ));
    }
    return list;
  }

  Future<List<ChatMessage>> getNewChatMessages(int last_timestamp) async {
    List<ChatMessage> list = [];
    final params = {
      "last_timestamp": last_timestamp.toString()
    };
    var url = Uri.https(Constants.server_get_url, '/selective_app/SelectiveTradesApp/getNewChatMessages.php', params);
    var response = await http.get(url);
    if(response.statusCode == 200){
      //print("db_helper.getNewChatMessages response is ${response.body}");
      if(response.body != 'failure'){
        var json = jsonDecode(response.body);
        List<dynamic> l = json;
        for(var i = 0; i<l.length; i++){
          ChatMessage m = ChatMessage(
              message_id: int.parse(l[i][col_chat_message_id]),
              message: l[i][col_chat_message],
              timestamp: l[i][col_chat_timestamp],
              attachment_url: l[i][col_chat_attachment_url],
              status: l[i][col_chat_status],
              sender_name: l[i][col_chat_sender_name],
              sender_id: int.parse(l[i][col_chat_sender_id])
          );
          await saveChatMessageSQLite(m);
          list.add(m);
        }
      }
    }
    else{
      print("DbHelper.getNewChatMessages response exception : ${response.body}");
    }
    return list;
  }

  Future<List<Message>> getNewMessages(int last_id, String channel) async{
    Map<String,dynamic> params = {
      "last_id": last_id.toString(),
      "channel": channel
    };
    var url = Uri.https(Constants.server_get_url, '/selective_app/SelectiveTradesApp/getNewMessages.php', params);
    var response = await http.get(url);
    if(response.statusCode == 200){
      if(response.body != 'failure'){
        var json = jsonDecode(response.body);
        List<dynamic> l = json;
        for(var i = 0; i<l.length; i++){
          Message m = Message(
              message_id: l[i]["$col_message_id"],
              message: l[i]["$col_message"],
              channel: l[i]["$col_message_channel"],
              timestamp: l[i]["$col_message_timestamp"],
              attachment: l[i]["$col_attachment"],
              attachment_type: l[i]["$col_attachment_type"],
              status: l[i]["$col_status"],
              secondary_status: l[i]["$col_secondary_status"],
              secondary_status_color: l[i]["$col_secondary_status_color"],
              secondary_status_timestamp: l[i]["$col_secondary_status_timestamp"],
              message_color: l[i]["$col_message_color"],
          );
          await saveMessageSQLite(m);
        }
      }
    }
    else{
      print("DbHelper.getNewMessages response exception : ${response.body}");
    }
  }

  Future<List<NotificationToDisplay>> getNotificationsToDisplay() async {
    List<NotificationToDisplay> list = [];
    Database db = await this.database;
    String query = "select * from $notification_table";
    List<Map<String, Object>> result = await db.rawQuery(query);
    if(result.isNotEmpty){
      for(var i = 0; i<result.length; i++){
        print("db_helper.getNotificationsToDisplay timestamp is ${result[i][col_notification_timestamp]} and list is ${result.length}");
        NotificationToDisplay n = NotificationToDisplay(
          channel: result[i]["$col_notification_channel"],
          message: result[i]["$col_notification_message"],
          timestamp: result[i]["$col_notification_timestamp"],
          title: result[i]["$col_notification_title"],
          id: result[i]["$col_notification_id"].toString(),
          //date: DateFormat("M w, y").format(DateTime.fromMillisecondsSinceEpoch(1642746424033))
          date: DateFormat("MMM d, yyyy").format(DateTime.fromMillisecondsSinceEpoch(int.parse(result[i]["$col_notification_timestamp"])))

        );
        list.add(n);
      }
    }
    return list;
  }

  Future<NotificationToDisplay> getNotificationToDisplay() async {
    Database db = await this.database;
    String query = "select * from $notification_table";
    List<Map<String, Object>> result = await db.rawQuery(query);
    if(result.isEmpty)
      return null;
    else{
      NotificationToDisplay n = NotificationToDisplay(
        channel: result[0]["$col_notification_channel"],
        message: result[0]["$col_notification_message"],
        timestamp: result[0]["$col_notification_timestamp"],
        title: result[0]["$col_notification_title"],
      );
      return n;
    }
  }

  Future<List<Portfolio>> getStockPortfolioSQLite() async {
    List<Portfolio> list = [];
    Database db = await this.database;
    String query = "select * from ${Constants.stock_portfolio}";
    List<Map<String, Object>> result = await db.rawQuery(query);
    for(var i = 0; i<result.length; i++){
      list.add(Portfolio(
          id: result[i]["$col_portfolio_id"].toString(),
          symbol: result[i]["$col_portfolio_symbol"],
          buy_price: result[i]["$col_portfolio_buy_price"],
          buy_date: result[i]["$col_portfolio_buy_date"],
          quantity: result[i]["$col_portfolio_quantity"],
          net_change: result[i]["$col_portfolio_net_change"],
          total_value: result[i]["$col_portfolio_total_value"],
          net_pct_change: result[i]["$col_portfolio_net_pct_change"],
          current_price: result[i]["$col_portfolio_current_price"]
      ));
    }
    return list;
  }

  Future<List<Watchlist>> getStockWatchlistSQLite() async {
    List<Watchlist> list = [];
    Database db = await this.database;
    String query = "select * from ${Constants.stock_watchlist}";
    List<Map<String, Object>> result = await db.rawQuery(query);
    for(var i = 0; i<result.length; i++){
      list.add(Watchlist(
          id: result[i]["$col_watchlist_id"].toString(),
          symbol: result[i]["$col_watchlist_symbol"],
          buy_price: result[i]["$col_watchlist_buy_price"],
          buy_date: result[i]["$col_watchlist_buy_date"],
          net_pct_change: result[i]["$col_watchlist_net_pct_change"],
          net_change: result[i]["$col_watchlist_net_change"],
          pct_change_24hr: result[i]["$col_watchlist_pct_change_24hr"],
          price_change_24hr: result[i]["$col_watchlist_price_change_24hr"],
          live_price: result[i]["$col_watchlist_live_price"]
      ));
    }
    return list;
  }

  Future<AppUser> getUserByEmail(String email, {String user_hash}) async{
    AppUser user = null;
    final params  = {
      "email": email,
      "hash": user_hash
    };
    var url = Uri.https(Constants.server_get_url, '/selective_app/SelectiveTradesApp/getUserByEmail.php', params);
    var response = await http.get(url);
    if(response.statusCode == 200){
      if(response.body != "failure"){
        var json = jsonDecode(response.body);
        user = new AppUser(
          id: json[0]["$col_user_id"],
          stripe_id: json[0]["$col_stripe_id"],
          username: json[0]["$col_username"],
          email: json[0]["$col_email"],
          phone_number: json[0]["$col_phone_number"],
          date_registered: json[0]["$col_date_registered"],
          expiry_date: json[0]["$col_expiry_date"],
          firebase_tokens: json[0]["firebase_tokens"],
          user_password: json[0]["$col_user_password"],
          logged_in: json[0]["$col_logged_in"],
          active: json[0]["$col_active"],
          app_version_ios: json[0]["$col_app_version_ios"],
          app_version_android: json[0]["$col_app_version_android"],
          device: json[0]["$col_device"],
          ip_address: json[0]["$col_ip_address"],
          profile_image_url: json[0]["$col_profile_image_url"],
          hash: json[0]["$col_user_hash"],
          last_login: json[0]["$col_last_login"],
          email_notif: json[0]["$col_email_notif"],
          sms_notif: json[0]["$col_sms_notif"],
          sub_type: json[0]["$col_sub_type"],
          subscription_id: json[0]["$col_subscription_id"],
          tier: json[0]["$col_subscription_tier"]
        );
      }
    }
    else{
      print("DbHelper.getUserByEmail response error: ${response.body}");
    }
    return user;
  }

  Future<AppUser> getAppUserSQLite() async {
    AppUser user = null;
    Database db = await this.database;
    String query = "select * from $app_user_table";
    List<Map<String, Object>> result = await db.rawQuery(query);
    for(var i = 0; i<result.length; i++){
      user = new AppUser(
        id: result[i]["$col_user_id"].toString(),
        stripe_id: result[i]["$col_stripe_id"],
        username: result[i]["$col_username"],
        email: result[i]["$col_email"],
        phone_number: result[i]["$col_phone_number"],
        date_registered: result[i]["$col_date_registered"],
        expiry_date: result[i]["$col_expiry_date"],
        firebase_tokens: result[i]["$col_firebase_token"],
        user_password: result[i]["$col_user_password"],
        logged_in: result[i]["$col_logged_in"],
        active: result[i]["$col_active"],
        app_version_ios: result[i]["$col_app_version_ios"],
        app_version_android: result[i]["$col_app_version_android"],
        device: result[i]["$col_device"],
        ip_address: result[i]["$col_ip_address"],
        profile_image_url: result[i]["$col_profile_image_url"],
        hash: result[i]["$col_user_hash"],
        last_login: result[i]["$col_last_login"],
        email_notif: result[i]["$col_email_notif"],
        sms_notif: result[i]["$col_sms_notif"],
        sub_type: result[i]["$col_sub_type"],
        subscription_id: result[i]["$col_subscription_id"],
        tier: result[i]["$col_subscription_tier"]
      );
    }
    return user;
  }

  Future<List<FAQ>> getFAQs() async {
    List<FAQ> list = [];
    Database db = await this.database;
    String query = "select * from $faq_table";
    List<Map<String, Object>> result = await db.rawQuery(query);
    for(var i = 0; i<result.length; i++){
      list.add(FAQ(
          id: result[i][col_faq_id],
          question: result[i][col_question],
          answer: result[i][col_answer],
          date: result[i][col_faq_date]
      ));
    }
    return list;
  }

  Future<Database> initializeDatabase() async{
    final db_path = await getDatabasesPath();
    final path = join(db_path, db_name);
    return await openDatabase(path, version: 1, onCreate: createDb);
  }

  Future<bool> isCorrectPassword(String email, String password) async{
    final params = {
      "email": email,
      "password": password
    };
    var uri = Uri.https(Constants.server_get_url, '/selective_app/SelectiveTradesApp/isCorrectPassword.php', params);
    var response = await http.get(uri, headers: null);
    if(response.statusCode == 200){
      try{
        var json = jsonDecode(response.body.toString());
        String user_password = json[0]["user_password"].toString();
        if(user_password == password){
          return true;
        }
        else{
          return false;
        }
      }
      catch(e){
        print("DbHelper.isCorrectPassword exception: ${e.toString()}");
        return false;
      }
    }
    else{
      print("DbHelper.isCorrectPassword failed with code: ${response.statusCode}");
      return false;
    }
  }

  Future<bool> isEmailExist(String email) async{
    final params = {
      "email": email
    };
    var uri = Uri.https(Constants.server_get_url, '/selective_app/SelectiveTradesApp/isEmailExist.php', params);
    var response = await http.get(uri, headers: null);
    if(response.statusCode == 200){
      if(response.body == 'true'){
        return true;
      }
      else{
        return false;
      }
    }
    else{
      print("DbHelper.isEmailExist failed with code: ${response.statusCode}");
      return false;
    }
  }

  Future<bool> isPhoneExist(String phone_number) async{
    final params = {
      "phone_number": phone_number
    };
    var uri = Uri.https(Constants.server_get_url, '/selective_app/SelectiveTradesApp/isPhoneNumberExist.php', params);
    var response = await http.get(uri, headers: null);
    if(response.statusCode == 200){
      if(response.body == 'true'){
        return true;
      }
      else{
        return false;
      }
    }
    else{
      print("DbHelper.isPhoneEsixt failed with code: ${response.statusCode}");
      return false;
    }
  }

  Future<void> saveAppUserSQLite(AppUser user) async {
    Database db = await this.database;
    String query = "insert into $app_user_table ($col_username, $col_email, $col_phone_number,"
        " $col_date_registered, $col_expiry_date, $col_firebase_token, $col_user_password,"
        " $col_logged_in, $col_active, $col_app_version_ios, $col_app_version_android, $col_device,"
        " $col_ip_address, $col_profile_image_url, $col_user_hash, $col_email_notif,"
        " $col_sms_notif, $col_sub_type, $col_subscription_id, $col_stripe_id, $col_subscription_tier) values ('${user.username}', '${user.email}',"
        " '${user.phone_number}', '${user.date_registered}', '${user.expiry_date}',"
        " '${user.firebase_tokens}', '${user.user_password}', '${user.logged_in}', "
        "'${user.active}', '${user.app_version_ios}', '${user.app_version_android}',"
        " '${user.device}', '${user.ip_address}', '${user.profile_image_url}',"
        " '${user.hash}', '${user.email_notif}', '${user.sms_notif}', '${user.sub_type}', '${user.subscription_id}', '${user.stripe_id}', '${user.tier}')";
    print("db_helper.saveAppUserSQLite user tier: ${user.tier}");
    await db.execute(query);
  }

  Future<void> saveChannelNotificationCount(String channel_name, int count) async {
    Database db = await this.database;
    String query = "update $channels_table set $col_unread_messages = $count where $col_channel_name = '$channel_name'";
    print("db_helper.saveChannelNotificationCount query $query");
    await db.execute(query);
  }

  Future<void> saveChannelSQLite(Channel channel) async{
    Database db = await this.database;
    String query = "insert into $channels_table ("
        "$col_channel_id,"
        " $col_channel_name,"
        " $col_channel_image,"
        " $col_number_of_members,"
        " $col_members,"
        " $col_channel_position) values (${channel.channel_id}, "
        "'${channel.channel_name}', "
        "'${channel.channel_image}', "
        "'${channel.number_of_members}', "
        "'${channel.members}',"
        " ${channel.position})";
    try{
      await db.execute(query);
    }
    catch(e){
      print("db_helper.saveChannelSQLite: ${e.toString()}");
    }
  }

  Future<void> saveChatMessageSQLite(ChatMessage message) async {
    Database db = await this.database;
    String query = "insert into $chat_messages_table ("
        "$col_chat_sender_id,"
        "$col_chat_sender_name,"
        "$col_chat_status,"
        "$col_chat_attachment_url,"
        "$col_chat_timestamp,"
        "$col_chat_message) values ("
        "${message.sender_id},"
        "'${message.sender_name}',"
        "'${message.status}',"
        "'${message.attachment_url}',"
        "${message.timestamp},"
        "'${message.message}')";
    await db.execute(query);
  }

  Future<void> saveCryptoPortfolioSQLite(Portfolio portfolio) async{
    Database db = await this.database;
    String query = "insert into ${Constants.crypto_portfolio} ("
        "$col_portfolio_id,"
        "$col_portfolio_current_price,"
        "$col_portfolio_net_pct_change,"
        "$col_portfolio_total_value,"
        "$col_portfolio_net_change,"
        "$col_portfolio_quantity,"
        "$col_portfolio_buy_date,"
        "$col_portfolio_buy_price,"
        "$col_portfolio_symbol) values ("
        "${int.parse(portfolio.id)},"
        "${portfolio.current_price},"
        "${portfolio.net_pct_change},"
        "${portfolio.total_value},"
        "${portfolio.net_change},"
        "${portfolio.quantity},"
        "'${portfolio.buy_date}',"
        "${portfolio.buy_price},"
        "'${portfolio.symbol}')";
    await db.execute(query);
  }

  Future<void> saveCryptoWatchlistSQLite(Watchlist watchlist) async {
    Database db = await this.database;
    String query = "insert into ${Constants.crypto_watchlist} ("
        "$col_watchlist_id,"
        "$col_watchlist_price_change_24hr,"
        "$col_watchlist_net_change,"
        "$col_watchlist_net_pct_change,"
        "$col_watchlist_live_price,"
        "$col_watchlist_buy_date,"
        "$col_watchlist_buy_price,"
        "$col_watchlist_symbol,"
        "$col_watchlist_pct_change_24hr) values ("
        "${int.parse(watchlist.id)},"
        "${watchlist.price_change_24hr},"
        "${watchlist.net_change},"
        "${watchlist.net_pct_change},"
        "${watchlist.live_price},"
        "'${watchlist.buy_date}',"
        "${watchlist.buy_price},"
        "'${watchlist.symbol}',"
        "${watchlist.pct_change_24hr})";
    await db.execute(query);
  }

  Future<void> saveEarningsCalendar(EarningsCalendar calendar) async {
    Database db = await this.database;
    String query = "insert into $earnings_calendar_table ("
        "$col_earnings_calendar_date,"
        "$col_earnings_calendar_surprise_pct,"
        "$col_earnings_calendar_difference,"
        "$col_earnings_calendar_eps_actual,"
        "$col_earnings_calendar_eps_estimate,"
        "$col_earnings_calendar_time,"
        "$col_earnings_calendar_currency,"
        "$col_earnings_calendar_name,"
        "$col_earnings_calendar_symbol) values ("
        "'${calendar.date}',"
        "${calendar.surprise_pct},"
        "${calendar.difference},"
        "${calendar.eps_actual},"
        "${calendar.eps_estimate},"
        "'${calendar.time}',"
        "'${calendar.currency}',"
        "'${calendar.name.toString()}',"
        "'${calendar.symbol}')";
    await db.execute(query);
  }

  Future<void> saveFAQ(FAQ faq) async {
    Database db = await this.database;
    String query = "insert into $faq_table ($col_faq_id, $col_question, $col_answer, $col_faq_date) values "
        "(${faq.id}, '${faq.question}', '${faq.answer}', '${faq.date}')";
    await db.execute(query);
  }

  Future<void> saveIPOCalendar(IPOCalendar calendar) async{
    Database db = await this.database;
    String query = "insert into $ipo_calendar_table ("
        "$col_ipo_calendar_date,"
        "$col_ipo_calendar_currency,"
        "$col_ipo_calendar_shares,"
        "$col_ipo_calendar_offer_price,"
        "$col_ipo_calendar_price_range_high,"
        "$col_ipo_calendar_price_range_low,"
        "$col_ipo_calendar_exchange,"
        "$col_ipo_calendar_name,"
        "$col_ipo_calendar_symbol) values ("
        "'${calendar.date}',"
        "'${calendar.currency}',"
        "${calendar.shares},"
        "${calendar.offer_price},"
        "${calendar.price_range_high},"
        "${calendar.price_range_low},"
        "'${calendar.exchange}',"
        "'${calendar.name}',"
        "'${calendar.symbol}')";
    await db.execute(query);
  }

  Future<void> saveLiveOption(LiveOption option) async {
    Database db = await this.database;
    String query = "insert into $live_option_table ("
        "$col_live_option_live_price,"
        "$col_live_option_tracker,"
        "$col_live_option_timestamp,"
        "$col_live_option_pct_change,"
        "$col_live_option_status,"
        "$col_live_option_channel) values ("
        "'${double.parse(option.live_price)}',"
        "'${option.tracker}',"
        "'${option.timestamp}',"
        "'${double.parse(option.pct_change)}',"
        "'${option.status}',"
        "'${option.channel}')";
    await db.execute(query);
  }

  Future<void> saveMessageSQLite(Message message) async{
    Database db = await this.database;
    String query = "insert into $channel_messages_table ("
        "$col_message_id, "
        "$col_message, "
        "$col_message_channel, "
        "$col_message_timestamp, "
        "$col_attachment, "
        "$col_attachment_type, "
        "$col_status, "
        "$col_secondary_status, "
        "$col_secondary_status_color, "
        "$col_secondary_status_timestamp,"
        "$col_message_color) values ("
        "${message.message_id}, "
        "'${message.message}', "
        "'${message.channel}', "
        "${int.parse(message.timestamp)}, "
        "'${message.attachment}', "
        "'${message.attachment_type}', "
        "'${message.status}', "
        "'${message.secondary_status}', "
        "'${message.secondary_status_color}',"
        "'${int.parse(message.secondary_status_timestamp)}',"
        "'${message.message_color}')";
    await db.execute(query);
  }

  Future<void> saveNotificationToDisplay(NotificationToDisplay notif) async {
    Database db = await this.database;
    String insert_query = "insert into $notification_table ($col_notification_title,$col_notification_screen,$col_notification_timestamp,$col_notification_message,"
        "$col_notification_channel) values ('${notif.title}','${notif.screen}','${notif.timestamp}','${notif.message}','${notif.channel}')";
    await db.execute(insert_query);
  }

  Future<void> saveStockPortfolioSQLite(Portfolio portfolio) async{
    Database db = await this.database;
    String query = "insert into ${Constants.stock_portfolio} ("
        "$col_portfolio_current_price,"
        "$col_portfolio_net_pct_change,"
        "$col_portfolio_total_value,"
        "$col_portfolio_net_change,"
        "$col_portfolio_quantity,"
        "$col_portfolio_buy_date,"
        "$col_portfolio_buy_price,"
        "$col_portfolio_symbol) values ("
        "${portfolio.current_price},"
        "${portfolio.net_pct_change},"
        "${portfolio.total_value},"
        "${portfolio.net_change},"
        "${portfolio.quantity},"
        "'${portfolio.buy_date}',"
        "${portfolio.buy_price},"
        "'${portfolio.symbol}')";
    await db.execute(query);
  }

  Future<void> saveStockWatchlistSQLite(Watchlist watchlist) async {
    Database db = await this.database;
    String query = "insert into ${Constants.stock_watchlist} ("
        "$col_watchlist_price_change_24hr,"
        "$col_watchlist_net_change,"
        "$col_watchlist_net_pct_change,"
        "$col_watchlist_live_price,"
        "$col_watchlist_buy_date,"
        "$col_watchlist_buy_price,"
        "$col_watchlist_symbol,"
        "$col_watchlist_pct_change_24hr) values ("
        "${watchlist.price_change_24hr},"
        "${watchlist.net_change},"
        "${watchlist.net_pct_change},"
        "${watchlist.live_price},"
        "'${watchlist.buy_date}',"
        "'${watchlist.buy_price}',"
        "'${watchlist.symbol}',"
        "${watchlist.pct_change_24hr})";
    await db.execute(query);
  }

  Future<void> saveUserSQLite(AppUser user) async {
      Database db = await this.database;
      String query = "insert into $user_table ($col_username, $col_email, $col_phone_number,"
          " $col_date_registered, $col_expiry_date, $col_firebase_token, $col_user_password,"
          " $col_logged_in, $col_active, $col_app_version_ios, $col_app_version_android, $col_device,"
          " $col_ip_address, $col_profile_image_url, $col_user_hash, $col_email_notif, $col_sms_notif, $col_sub_type, $col_subscription_id) values ('${user.username}', '${user.email}',"
          " '${user.phone_number}', '${user.date_registered}', '${user.expiry_date}',"
          " '${user.firebase_tokens}', '${user.user_password}', '${user.logged_in}', "
          "'${user.active}', '${user.app_version_ios}', '${user.app_version_android}',"
          " '${user.device}', '${user.ip_address}', '${user.profile_image_url}', '${user.hash}', '${user.email_notif}', '${user.sms_notif}', '${user.sub_type}', '${user.subscription_id}')";
      await db.execute(query);
  }

  Future<void> updateExpiryDates(List<AppUser> users) async {
    Database db = await this.database;
    String query;
    for(var i = 0; i<users.length; i++){
      query = "update $user_table set $col_expiry_date='${users[i].expiry_date}' where $col_email='${users[i].email}'";
      db.execute(query);
    }
  }

  Future<void> updateFirebaseTokens(List<AppUser> users) async {
    Database db = await this.database;
    String query;
    for(var i = 0; i<users.length; i++){
      query = "update $user_table set $col_firebase_token='${users[i].firebase_tokens}' where $col_email='${users[i].email}'";
      db.execute(query);
    }
  }

  Future<void> updateMessage(Message message) async{
    Database db = await this.database;
    if(message.secondary_status_timestamp == null || message.secondary_status_timestamp == ""){
      message.secondary_status_timestamp = "0";
    }
    String query = "update $channel_messages_table set $col_message_channel='${message.channel}', "
        "$col_message='${message.message}', "
        "$col_status='${message.status}', "
        "$col_attachment='${message.attachment}', "
        "$col_secondary_status='${message.secondary_status}', "
        "$col_secondary_status_color='${message.secondary_status_color}', "
        "$col_secondary_status_timestamp='${int.parse(message.secondary_status_timestamp)}'"
        "where $col_message_id='${message.message_id}'";
    await db.execute(query);
  }

  Future<bool> updateUser(AppUser user) async {
    Map<String, dynamic> params = {
      "username": user.username,
      "stripe_id": user.stripe_id,
      "email": user.email,
      "phone_number": user.phone_number,
      "date_registered": user.date_registered,
      "expiry_date": user.expiry_date,
      "firebase_tokens": user.firebase_tokens,
      "password": user.user_password,
      "logged_in": user.logged_in,
      "active": user.active,
      Platform.isIOS ? "app_version_ios" : "app_version_android" : Platform.isIOS ? Constants.ios_app_version : Constants.android_app_version,
      "device": user.device,
      "ip_address": user.ip_address,
      "profile_image_url": user.profile_image_url,
      "hash": user.hash,
      "last_login": user.last_login,
      "email_notif": user.email_notif,
      "sms_notif": user.sms_notif,
      "sub_type": user.sub_type,
    };
    try{
      var uri = Uri.parse("${Constants.server_url}/selective_app/SelectiveTradesApp/updateUser.php");
      var response = await http.post(uri, body: params);
      print("db_helper.updateUser response: ${response.body.toString()}");
      if(response.body == 'success'){
        return true;
      }
      else{
        showToast(response.body);
        return false;
      }
    }
    catch(e){
      print("dbHelper.updateUser: ${e.toString()}");
      return false;
    }
  }

  Future<void> updateAppUserSQLite(AppUser user) async {
    Database db = await this.database;
    String query = "update $app_user_table set $col_username='${user.username}',"
        "$col_email='${user.email}', $col_stripe_id='${user.stripe_id}', $col_phone_number='${user.phone_number}',"
        "$col_date_registered='${user.date_registered}',$col_expiry_date='${user.expiry_date}',$col_firebase_token='${user.firebase_tokens}',"
        "$col_user_password='${user.user_password}',$col_logged_in='${user.logged_in}',$col_last_login='${user.last_login}',$col_active='${user.active}',"
        "$col_app_version_android='${user.app_version_android}',$col_app_version_ios='${user.app_version_ios}',$col_device='${user.device}',"
        "$col_ip_address='${user.ip_address}',$col_profile_image_url='${user.profile_image_url}', $col_user_hash='${user.hash}', "
        "$col_email_notif='${user.email_notif}', $col_sms_notif='${user.sms_notif}',"
        "$col_sub_type='${user.sub_type}', $col_subscription_id='${user.subscription_id}', $col_subscription_tier='${user.tier}' where email='${user.email}'";
    await db.execute(query);
  }

  Future<bool> uploadUser(AppUser user) async {
    Map<String, dynamic> params = {
      "stripe_id": user.stripe_id,
      "username": user.username,
      "email": user.email,
      "phone_number": user.phone_number,
      "date_registered": user.date_registered,
      "expiry_date": user.expiry_date,
      "firebase_tokens": user.firebase_tokens,
      "password": user.user_password,
      "logged_in": user.logged_in,
      "active": user.active,
      Platform.isIOS ? "app_version_ios" : "app_version_android" : Platform.isIOS ? Constants.ios_app_version : Constants.android_app_version,
      "device": user.device,
      "ip_address": user.ip_address,
      "profile_image_url": user.profile_image_url,
      "hash": user.hash,
      "last_login": user.last_login,
      "email_notif": "",
      "sms_notif": "",
    };
    try{
      var uri = Uri.parse("${Constants.server_url}/selective_app/SelectiveTradesApp/uploadUser.php");
      var response = await http.post(uri, body: params);
      if(response.body == 'success'){
        return true;
      }
      else{
        showToast(response.body);
        return false;
      }
    }
    catch(e){
      print("dbHelper.uploadUser: ${e.toString()}");
      return false;
    }
  }

}
