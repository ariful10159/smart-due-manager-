import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../firebase_options.dart';
import '../route_observer.dart';
import '../screens/notifications_screen.dart';
import 'notification_service.dart';

// ✅ Admin panel থেকে পাঠানো targeted push notification গ্রহণ করার সার্ভিস।
// Token capture + foreground display এখানে, ব্যাকগ্রাউন্ড/killed অবস্থায় system tray
// notification Android নিজে থেকেই দেখায় (এখানে extra কিছু লেখার দরকার নেই)।
class FcmService {
  static Future<void> init() async {
    // ✅ runApp() এর আগে register করা বাধ্যতামূলক — নাহলে app killed অবস্থায়
    // background push এলে handler টা মিস হয়ে যেতে পারে।
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // ✅ App foreground এ থাকলে Android নিজে থেকে system tray তে notification
    // দেখায় না, তাই local notification দিয়ে ম্যানুয়ালি দেখানো হয়।
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;
      NotificationService.showPushNotification(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title: notification.title ?? '',
        body: notification.body ?? '',
        payload: jsonEncode(message.data),
      );
    });

    // ✅ FCM টোকেন মাঝেমধ্যে rotate হয় — নতুন টোকেন এলে সাথে সাথে Firestore এ আপডেট
    // করা হয়, নাহলে পুরনো (এখন আর কাজ না করা) টোকেনে push পাঠানো হতে থাকত।
    FirebaseMessaging.instance.onTokenRefresh.listen((_) => saveTokenForCurrentUser());

    // ✅ App background এ থাকা অবস্থায় (killed না) system tray notification ট্যাপ
    // করলে এটা ফায়ার হয় — সরাসরি Notifications screen এ নিয়ে যাওয়া হয়।
    FirebaseMessaging.onMessageOpenedApp.listen((_) => _openNotificationsScreen());
  }

  // ✅ App সম্পূর্ণ বন্ধ (killed) অবস্থায় push ট্যাপ করে খোলা হলে getInitialMessage()
  // দিয়ে সেটা জানা যায় — main() এর runApp() এর পরে কল করতে হয় (unawaited),
  // যাতে appNavigatorKey ততক্ষণে একটা mounted Navigator পায়।
  static Future<void> handleInitialMessageIfAny() async {
    final message = await FirebaseMessaging.instance.getInitialMessage();
    if (message != null) _openNotificationsScreen();
  }

  static void _openNotificationsScreen() {
    appNavigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  }

  // ✅ লগইন করা ইউজারের বর্তমান ডিভাইসের FCM টোকেন users/{uid}.fcmToken এ সেভ করে —
  // registration, login, ও persisted-session app relaunch — সব ক্ষেত্রেই AuthWrapper
  // এর auth-state-changed হ্যান্ডলার থেকে কল হয়, তাই auth_service.dart বদলাতে হয়নি।
  static Future<void> saveTokenForCurrentUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set({'fcmToken': token}, SetOptions(merge: true));
  }
}

// ✅ Top-level/static হতে হবে (Flutter background isolate এর প্রয়োজনীয়তা)। এখানে
// আলাদা করে notification দেখানোর দরকার নেই — app ব্যাকগ্রাউন্ড/killed অবস্থায় FCM
// notification payload Android নিজে থেকেই system tray তে দেখায়, এই handler শুধু
// registered থাকা দরকার যাতে plugin cold background delivery তে error না দেয়।
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}
