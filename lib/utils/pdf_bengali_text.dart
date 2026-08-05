import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;

/// ✅ বাংলা টেক্সট কে PDF এর জন্য ছবি বানানো হচ্ছে — pdf প্যাকেজ বাংলার
/// যুক্তাক্ষর/matra ঠিকভাবে shape করতে পারে না, কিন্তু Flutter এর নিজস্ব
/// rendering engine পারে। তাই Flutter দিয়ে রেন্ডার করে ছবি বানিয়ে PDF এ বসানো হচ্ছে।
Future<pw.Widget> bengaliTextImage(
  String text, {
  double fontSize = 11,
  FontWeight fontWeight = FontWeight.normal,
  ui.Color color = const ui.Color(0xFF000000),
}) async {
  const scale = 3.0; // ক্রিস্প রেজোলিউশনের জন্য বড় করে রেন্ডার করা হচ্ছে

  final textPainter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: 'NotoSerifBengali',
        fontSize: fontSize * scale,
        fontWeight: fontWeight,
        color: color,
      ),
    ),
    textDirection: ui.TextDirection.ltr,
  );
  textPainter.layout();

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  textPainter.paint(canvas, Offset.zero);
  final picture = recorder.endRecording();
  final image = await picture.toImage(
    textPainter.width.ceil().clamp(1, 5000),
    textPainter.height.ceil().clamp(1, 500),
  );
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  final bytes = byteData!.buffer.asUint8List();

  return pw.Image(
    pw.MemoryImage(bytes),
    width: textPainter.width / scale,
    height: textPainter.height / scale,
  );
}
