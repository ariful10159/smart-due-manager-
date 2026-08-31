import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
        final colorScheme = Theme.of(context).colorScheme;

        return Material(
          color: colorScheme.primaryContainer,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.campaign_outlined, color: colorScheme.onPrimaryContainer),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (title.isNotEmpty)
                          Text(
                            title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        Text(
                          message,
                          style: TextStyle(color: colorScheme.onPrimaryContainer),
                        ),
                      ],
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
