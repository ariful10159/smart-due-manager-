import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';

class NotificationDetailScreen extends StatelessWidget {
  const NotificationDetailScreen({super.key, required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final dateFmt = DateFormat('d MMMM yyyy • hh:mm a');

    final title = (data['title'] as String? ?? '').trim();
    final message = (data['message'] as String? ?? '').trim();
    final arrivedAt = ((data['createdAt'] ?? data['updatedAt']) as Timestamp?)?.toDate();

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: AppBar(
        title: Text(
          l10n.noticeDetailTitle,
          style: TextStyle(fontWeight: FontWeight.w800, color: colors.textPrimary),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
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
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: colors.accent,
                    child: const Icon(Icons.campaign_outlined, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title.isNotEmpty ? title : l10n.noticeDetailTitle,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SelectableText(
                message,
                style: TextStyle(fontSize: 15, height: 1.6, color: colors.textPrimary),
              ),
              if (arrivedAt != null) ...[
                const SizedBox(height: 18),
                Text(
                  dateFmt.format(arrivedAt),
                  style: TextStyle(color: colors.hintColor, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
