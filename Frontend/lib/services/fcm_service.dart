import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../calls/notification.call.dart';
import 'package:flutter/foundation.dart';

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> init() async {
    // Request permissions for iOS and Android 13+
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (kDebugMode) {
        print('User granted permission');
      }
      
      // Get the token
      String? token = await _fcm.getToken();
      if (token != null) {
        await _registerToken(token);
      }

      // Listen for token refreshes
      _fcm.onTokenRefresh.listen(_registerToken);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (kDebugMode) {
          print('Got a message whilst in the foreground!');
          print('Message data: ${message.data}');
        }

        if (message.notification != null) {
          if (kDebugMode) {
            print('Message also contained a notification: ${message.notification}');
          }
          // You could show a local notification here if needed
        }
      });
    } else {
      if (kDebugMode) {
        print('User declined or has not accepted permission');
      }
    }
  }

  Future<void> _registerToken(String token) async {
    if (kDebugMode) {
      print('FCM Token: $token');
    }
    
    await saveFcmToken(
      token: token,
      plataforma: Platform.isAndroid ? 'android' : 'ios',
      onSuccess: () => debugPrint('Token registered successfully'),
      onError: (err) => debugPrint('Error registering token: $err'),
    );
  }
}
