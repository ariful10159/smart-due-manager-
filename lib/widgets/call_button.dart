import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// ✅ শুধু icon না, একটা labeled pill button — "Call" লেখা থাকায় এটা যে একটা
/// tap-able action সেটা স্পষ্ট বোঝা যায়। কার্ডের ভেতরে টাইট জায়গায় বসাতে
/// [compact] ব্যবহার করুন (ছোট padding/font, "Call" লেবেল); বেশি জায়গা থাকলে
/// default (বড়, "Call Now" লেবেল)।
class CallButton extends StatelessWidget {
  const CallButton({
    super.key,
    required this.onTap,
    required this.colors,
    this.compact = false,
  });

  final VoidCallback onTap;
  final AppColors colors;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 9 : 14,
            vertical: compact ? 6 : 9,
          ),
          decoration: BoxDecoration(
            color: colors.clear.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.clear.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.call_rounded, color: colors.clear, size: compact ? 13 : 16),
              SizedBox(width: compact ? 4 : 6),
              Text(
                compact ? "Call" : "Call Now",
                style: TextStyle(
                  color: colors.clear,
                  fontWeight: FontWeight.w700,
                  fontSize: compact ? 11 : 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
