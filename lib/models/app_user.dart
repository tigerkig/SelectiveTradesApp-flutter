class AppUser{
  String id;
  String stripe_id;
  String username;
  String email;
  String last_login;
  String phone_number;
  String date_registered;
  String expiry_date;
  dynamic firebase_tokens;
  String user_password;
  String logged_in;
  String active;
  String app_version_ios;
  String app_version_android;
  String device;
  String ip_address;
  String profile_image_url;
  String hash;
  String email_notif;
  String sms_notif;
  String sub_type;
  String subscription_id;
  String tier;

  AppUser({
      this.hash,
      this.id,
      this.stripe_id,
      this.username,
      this.email,
      this.phone_number,
      this.date_registered,
      this.expiry_date,
      this.firebase_tokens,
      this.user_password,
      this.active,
      this.app_version_ios,
      this.app_version_android,
      this.device,
      this.ip_address,
      this.logged_in,
      this.last_login,
      this.profile_image_url,
      this.email_notif,
      this.sms_notif,
      this.sub_type,
      this.subscription_id,
      this.tier});
}