# Release APK Black Screen — সমস্যা ও সমাধান

## সমস্যা

Release APK ইনস্টল করার পর অ্যাপ ওপেন করলে শুধু **কালো স্ক্রিন** দেখাত — কোনো লোডিং ইন্ডিকেটর না, কোনো এরর মেসেজ না, ক্র্যাশও না। অ্যাপ চিরতরে ওই কালো স্ক্রিনেই আটকে থাকত।

- Debug build (`flutter run`) এবং Profile build — দুটোই ঠিকভাবে চলত।
- শুধু **Release build**-এই এই সমস্যা হতো।

## আসল কারণ (Root Cause)

Flutter release APK বিল্ড করার সময় Android-এর **R8** টুল ডিফল্টভাবে কোড "মিনিফাই" করে (অপ্রয়োজনীয় ক্লাস/মেথড মুছে APK-র সাইজ কমায়)।

প্রজেক্টে `android/app/proguard-rules.pro` নামে কোনো keep-rules ফাইল ছিল না, অথচ `android/app/build.gradle.kts`-এ R8 মিনিফিকেশন চালু ছিল। ফলে R8 বুঝতে পারেনি যে Firebase, `permission_handler`, `flutter_local_notifications`-এর মতো প্লাগইনগুলোর কিছু ক্লাস **রানটাইমে reflection দিয়ে ব্যবহার হয়** — তাই সেগুলো "unused" ভেবে মুছে ফেলছিল।

এর প্রভাব পড়েছিল অ্যাপ চালু হওয়ার (`main()`) সময়:

1. `main()` ফাংশনে `runApp()` কল করার **আগে** এই কাজগুলো `await` করা হতো:
   - `NotificationService.init()` → notification ও exact-alarm permission রিকোয়েস্ট
   - `AppSettingsController.init()` → Firestore থেকে সেটিংস fetch (কোনো timeout ছাড়া)
2. R8-এর স্ট্রিপিং-এর কারণে এই কলগুলোর কোনো একটা **নিঃশব্দে hang** করে যাচ্ছিল — কোনো exception throw হচ্ছিল না, তাই `try/catch`-ও ধরতে পারছিল না।
3. যেহেতু এই `await` কখনো শেষ হচ্ছিল না, `runApp()` কখনোই কল হচ্ছিল না — ফলে Flutter-এর প্রথম frame কখনো আঁকা হতো না, আর ব্যবহারকারী শুধু নেটিভ Android splash background (কালো স্ক্রিন) দেখতেন।

**কীভাবে ধরা পড়ল:** Debug ও Profile বিল্ডে R8 মিনিফিকেশন থাকে না — আর ওই দুই বিল্ড একদম ঠিকভাবে চলছিল। শুধু Release বিল্ডেই সমস্যা — এই তুলনা থেকেই R8-কে সন্দেহ করে `build/app/outputs/mapping/release/mapping.txt` ফাইলের উপস্থিতি যাচাই করে নিশ্চিত হওয়া গেছে (এই mapping ফাইল শুধু তখনই তৈরি হয় যখন R8 minification চলে)।

## সমাধান

### ১. R8 Minification বন্ধ করা (মূল ফিক্স)

**ফাইল:** `android/app/build.gradle.kts`

```kotlin
buildTypes {
    release {
        signingConfig = ...
        isMinifyEnabled = false
        isShrinkResources = false
    }
}
```

সঠিক keep-rules লিখে মিনিফিকেশন চালু রাখা সম্ভব, কিন্তু প্রজেক্টে ব্যবহৃত প্রতিটি প্লাগইনের (Firebase, permission_handler, flutter_local_notifications, local_auth, image_picker, ইত্যাদি) জন্য নির্ভুল rules লেখা সময়সাপেক্ষ ও ঝুঁকিপূর্ণ। তাই দ্রুত ও নিরাপদ সমাধান হিসেবে মিনিফিকেশন সম্পূর্ণ বন্ধ রাখা হয়েছে। এর একমাত্র প্রভাব — APK-র সাইজ কিছুটা বড় হয়েছে (~75MB → ~81MB)।

### ২. Startup-কে non-blocking করা (Defense in depth)

যদিও মূল কারণ R8 ছিল, `main()`-এ থাকা এই দুটো ব্লকিং `await`-ও একটা প্রকৃত ডিজাইন সমস্যা ছিল — নেটওয়ার্ক স্লো/অনুপলব্ধ হলে এগুলো একইভাবে অ্যাপকে আটকে দিতে পারত। তাই এগুলোও ঠিক করা হয়েছে:

**ফাইল:** `lib/services/notification_service.dart`
- `init()` থেকে permission request আলাদা করে নতুন `requestPermissions()` মেথডে সরানো হয়েছে।

**ফাইল:** `lib/main.dart`
- `requestPermissions()` এখন `runApp()`-এর **পরে**, `unawaited()` দিয়ে ব্যাকগ্রাউন্ডে কল হয়।

**ফাইল:** `lib/providers/app_settings_controller.dart`
- Firestore থেকে সেটিংস sync করা (`loadFromFirestore`) আর await করা হয় না — local cache load করেই `runApp()` এগিয়ে যেতে পারে, Firestore sync ব্যাকগ্রাউন্ডে `notifyListeners()` দিয়ে UI আপডেট করে।

**ফাইল:** `lib/services/settings_service.dart`
- `loadFromFirestore()`-এর Firestore `.get()` কলে `.timeout(Duration(seconds: 15))` যোগ করা হয়েছে, যাতে নেটওয়ার্ক কল কখনো অনির্দিষ্টকালের জন্য ঝুলে না থাকে।

## ফলাফল

নতুন release APK বিল্ড করে ডিভাইসে ইনস্টল করে cold-launch টেস্ট করা হয়েছে — অ্যাপ এখন সরাসরি Home Screen দেখায় (Dashboard, কালেকশন স্ট্যাটস, Top Due Customers সহ), কোনো কালো স্ক্রিন আটকানো ছাড়াই।
