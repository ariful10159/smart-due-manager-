/// ✅ HTML এ ব্যবহারের জন্য বিশেষ ক্যারেক্টার escape করা (& < > " ইত্যাদি) —
/// কাস্টমারের নাম/ফোন এর মতো user-input যখন সরাসরি HTML string এ বসানো হয়
/// (PDF জেনারেশনের জন্য), তখন malformed/injected markup ঠেকাতে ব্যবহার করা হয়।
String escapeHtml(String input) {
  return input
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;');
}
