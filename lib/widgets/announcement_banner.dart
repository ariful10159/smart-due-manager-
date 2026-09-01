import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../screens/notification_detail_screen.dart';

// ✅ Admin panel থেকে announcements কালেকশনে লেখা announcement গুলোর মধ্যে
// active এবং (থাকলে) start/end window এর মধ্যে পড়া সবচেয়ে সাম্প্রতিক আপডেট
// হওয়া announcement টা দেখায়। Dismiss শুধু in-memory (state, per-announcement-id),
// অ্যাপ আবার খুললে আবার দেখাবে।
class AnnouncementBanner extends StatefulWidget {
  const AnnouncementBanner({super.key});

  @override
  State<AnnouncementBanner> createState() => _AnnouncementBannerState();
}

class _AnnouncementBannerState extends State<AnnouncementBanner> {
  String? _dismissedId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('announcements')
          .where('active', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final now = DateTime.now();

        QueryDocumentSnapshot<Map<String, dynamic>>? best;
        DateTime? bestUpdatedAt;

        for (final candidate in docs) {
          final data = candidate.data();
          // ✅ 'type' ফিল্ড না থাকলে (পুরনো announcement) 'message' ধরে নেওয়া হয় —
          // popup-type announcement এখানে (ticker banner) দেখানো হয় না।
          final type = (data['type'] as String?) ?? 'message';
          if (type != 'message') continue;
          final startAt = (data['startAt'] as Timestamp?)?.toDate();
          final endAt = (data['endAt'] as Timestamp?)?.toDate();
          if (startAt != null && now.isBefore(startAt)) continue;
          if (endAt != null && now.isAfter(endAt)) continue;
          if ((data['message'] as String? ?? '').trim().isEmpty) continue;

          final updatedAt = (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime(0);
          if (best == null || updatedAt.isAfter(bestUpdatedAt!)) {
            best = candidate;
            bestUpdatedAt = updatedAt;
          }
        }

        if (best == null || best.id == _dismissedId) {
          return const SizedBox.shrink();
        }

        final data = best.data();
        final title = (data['title'] as String? ?? '').trim();
        final message = (data['message'] as String? ?? '').trim();
        final tickerText = title.isNotEmpty ? '$title — $message' : message;
        final colorScheme = Theme.of(context).colorScheme;
        final textStyle = TextStyle(
          color: colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w600,
        );

        return Material(
          color: colorScheme.primaryContainer,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.campaign_outlined, color: colorScheme.onPrimaryContainer),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => NotificationDetailScreen(data: data)),
                        );
                      },
                      child: SizedBox(
                        height: 22,
                        child: _Marquee(text: tickerText, style: textStyle),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: colorScheme.onPrimaryContainer, size: 20),
                    onPressed: () => setState(() => _dismissedId = best!.id),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ✅ কোনো এক্সটার্নাল প্যাকেজ ছাড়াই — TextPainter দিয়ে টেক্সটের প্রকৃত width মেপে,
// একটা AnimationController দিয়ে ডানদিক থেকে বামে অবিরাম (seamless loop) স্ক্রল করানো হয়।
// টেক্সট দুইবার পরপর বসানো হয়েছে যাতে প্রথমটা পুরো বেরিয়ে যাওয়ার সাথে সাথে
// দ্বিতীয়টা ঠিক তার জায়গায় চলে আসে — কোনো ফাঁক/জাম্প চোখে পড়ে না।
class _Marquee extends StatefulWidget {
  const _Marquee({required this.text, required this.style});

  final String text;
  final TextStyle style;

  static const double _gap = 60;
  static const double _pixelsPerSecond = 55;

  @override
  State<_Marquee> createState() => _MarqueeState();
}

class _MarqueeState extends State<_Marquee> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _textWidth = 0;

  @override
  void initState() {
    super.initState();
    _textWidth = _measureTextWidth(widget.text, widget.style);
    _controller = AnimationController(vsync: this, duration: _durationFor(_textWidth))..repeat();
  }

  Duration _durationFor(double textWidth) {
    final millis = ((textWidth + _Marquee._gap) / _Marquee._pixelsPerSecond * 1000).round();
    return Duration(milliseconds: millis.clamp(3000, 60000));
  }

  double _measureTextWidth(String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    return painter.width;
  }

  @override
  void didUpdateWidget(covariant _Marquee oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _textWidth = _measureTextWidth(widget.text, widget.style);
      _controller.duration = _durationFor(_textWidth);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: OverflowBox(
        maxWidth: double.infinity,
        alignment: Alignment.centerLeft,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final dx = -(_controller.value * (_textWidth + _Marquee._gap));
            return Transform.translate(
              offset: Offset(dx, 0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.text, style: widget.style, maxLines: 1, softWrap: false),
                  SizedBox(width: _Marquee._gap),
                  Text(widget.text, style: widget.style, maxLines: 1, softWrap: false),
                  SizedBox(width: _Marquee._gap),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
