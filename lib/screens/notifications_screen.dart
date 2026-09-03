import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import 'notification_detail_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final dateFmt = DateFormat('d MMM yyyy');

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: AppBar(
        title: Text(
          l10n.notificationsTitle,
          style: TextStyle(fontWeight: FontWeight.w800, color: colors.textPrimary),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('announcements')
            .orderBy('updatedAt', descending: true)
            .snapshots(),
        builder: (context, announcementSnap) {
          // ✅ admin push notification গুলো একটা আলাদা collection এ (userNotifications,
          // recipientUid দিয়ে ফিল্টার করা) — নিচে announcement এর সাথে merge করে
          // একই সময়ানুক্রমিক লিস্টে দেখানো হয়। orderBy ইচ্ছাকৃতভাবে বাদ দেওয়া হয়েছে
          // (composite index এড়াতে) — merge করার সময় client-side এ sort করা হয়।
          final uid = FirebaseAuth.instance.currentUser!.uid;
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('userNotifications')
                .where('recipientUid', isEqualTo: uid)
                .snapshots(),
            builder: (context, pushSnap) {
              if (!announcementSnap.hasData || !pushSnap.hasData) {
                return Center(child: CircularProgressIndicator(color: colors.accent));
              }

              // ✅ শুধু message-type announcement এখানে দেখানো হয় — popup-type
              // announcement আলাদাভাবে অ্যাপ খোলার সময় দেখানো হয়, history তে না।
              final announcementItems = announcementSnap.data!.docs.where((doc) {
                final type = (doc.data()['type'] as String?) ?? 'message';
                return type == 'message';
              }).map((d) => d.data());

              final pushItems = pushSnap.data!.docs.map((d) => d.data());

              final items = [...announcementItems, ...pushItems].toList()
                ..sort((a, b) {
                  final at = ((a['createdAt'] ?? a['updatedAt']) as Timestamp?)?.toDate() ?? DateTime(0);
                  final bt = ((b['createdAt'] ?? b['updatedAt']) as Timestamp?)?.toDate() ?? DateTime(0);
                  return bt.compareTo(at);
                });

              if (items.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.notifications_off_outlined, size: 48, color: colors.textSecondary),
                      const SizedBox(height: 12),
                      Text(l10n.noNotifications, style: TextStyle(color: colors.textSecondary)),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final data = items[index];
                  final title = (data['title'] as String? ?? '').trim();
                  final message = (data['message'] as String? ?? '').trim();
                  final arrivedAt = ((data['createdAt'] ?? data['updatedAt']) as Timestamp?)?.toDate();

                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => NotificationDetailScreen(data: data)),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [colors.surface, colors.surfaceAlt],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colors.borderColor),
                      ),
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundColor: colors.accent,
                            child: const Icon(Icons.campaign_outlined, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title.isNotEmpty ? title : l10n.noticeDetailTitle,
                                  style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  message,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: colors.textSecondary),
                                ),
                                if (arrivedAt != null) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    dateFmt.format(arrivedAt),
                                    style: TextStyle(color: colors.hintColor, fontSize: 11),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, color: colors.hintColor),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
