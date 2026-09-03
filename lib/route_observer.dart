import 'package:flutter/material.dart';

// ✅ HomeScreen (ও ভবিষ্যতে অন্য যেকোনো স্ক্রিন) কোনো পুশ করা স্ক্রিন থেকে ফিরে
// এলে সেটা জানার জন্য — যেমন Customer Detail স্ক্রিনে গিয়ে payment যোগ করে
// back করলে Home এর Today's/Week's Collection কার্ড নিজে থেকে রিফ্রেশ হবে।
final RouteObserver<PageRoute> appRouteObserver = RouteObserver<PageRoute>();

// ✅ FCM push notification ট্যাপ করলে (app background/killed অবস্থায় থাকার সময়)
// কোনো BuildContext ছাড়াই একটা নতুন স্ক্রিন push করতে হয় — সেজন্য এই global key,
// MaterialApp এ navigatorKey হিসেবে বসানো হয়েছে (দেখুন lib/main.dart)।
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
