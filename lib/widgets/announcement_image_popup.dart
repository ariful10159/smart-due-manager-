import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

// ✅ 'popup' টাইপ announcement-এর জন্য — একটা fullscreen-ish image dialog,
// উপরে ডানদিকে একটা ছোট close বাটন।
// imageUrl হয় একটা সাধারণ http(s) URL, নয়তো একটা base64 data URI
// (admin panel থেকে ছবি Firestore-এ inline base64 হিসেবে সেভ করা হয়)।
class AnnouncementImagePopup extends StatelessWidget {
  const AnnouncementImagePopup({super.key, required this.imageUrl, this.title, this.caption});

  final String imageUrl;
  final String? title;
  final String? caption;

  static Uint8List? _decodeDataUrl(String url) {
    if (!url.startsWith('data:')) return null;
    final commaIndex = url.indexOf(',');
    if (commaIndex == -1) return null;
    try {
      return base64Decode(url.substring(commaIndex + 1));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasCaption = (title != null && title!.trim().isNotEmpty) || (caption != null && caption!.trim().isNotEmpty);
    final imageBytes = _decodeDataUrl(imageUrl);

    Widget imageWidget;
    if (imageBytes != null) {
      imageWidget = Image.memory(
        imageBytes,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stack) => const Padding(
          padding: EdgeInsets.all(40),
          child: Icon(Icons.broken_image_outlined, size: 48),
        ),
      );
    } else {
      imageWidget = Image.network(
        imageUrl,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Padding(
            padding: EdgeInsets.all(40),
            child: CircularProgressIndicator(),
          );
        },
        errorBuilder: (context, error, stack) => const Padding(
          padding: EdgeInsets.all(40),
          child: Icon(Icons.broken_image_outlined, size: 48),
        ),
      );
    }

    // ✅ স্ক্রিনের বেশিরভাগ জায়গা জুড়ে দেখানোর জন্য — screen size এর সাপেক্ষে
    // width/height নির্ধারণ করা হয়, fixed pixel value এর বদলে।
    final screenSize = MediaQuery.sizeOf(context);
    final dialogWidth = screenSize.width * 0.94;
    final dialogMaxHeight = screenSize.height * 0.82;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: screenSize.width * 0.03,
        vertical: screenSize.height * 0.06,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: dialogWidth,
              constraints: BoxConstraints(maxHeight: dialogMaxHeight),
              color: Theme.of(context).colorScheme.surface,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(child: imageWidget),
                  if (hasCaption)
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (title != null && title!.trim().isNotEmpty)
                            Text(
                              title!.trim(),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          if (caption != null && caption!.trim().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(caption!.trim()),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            top: -12,
            right: -12,
            child: Material(
              color: Colors.black87,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => Navigator.of(context).pop(),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.close, color: Colors.white, size: 18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
