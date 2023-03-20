import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:selective_chat/utils/push_notification_service.dart';


GetIt locator = GetIt.instance;

void setupLocator() {
  locator.registerLazySingleton(() => PushNotificationService());
}