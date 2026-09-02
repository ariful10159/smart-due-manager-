import 'package:flutter/material.dart';

// ✅ HomeScreen (ও ভবিষ্যতে অন্য যেকোনো স্ক্রিন) কোনো পুশ করা স্ক্রিন থেকে ফিরে
// এলে সেটা জানার জন্য — যেমন Customer Detail স্ক্রিনে গিয়ে payment যোগ করে
// back করলে Home এর Today's/Week's Collection কার্ড নিজে থেকে রিফ্রেশ হবে।
final RouteObserver<PageRoute> appRouteObserver = RouteObserver<PageRoute>();
