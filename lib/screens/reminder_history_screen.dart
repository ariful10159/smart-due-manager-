import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../l10n/app_localizations.dart';
import '../models/customer_repository.dart';
import '../theme/app_colors.dart';

class ReminderHistoryScreen extends StatelessWidget {
  final String customerId;

  const ReminderHistoryScreen({
    super.key,
    required this.customerId,
  });

  @override
  Widget build(BuildContext context) {
    final repo = CustomerRepository();
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: AppBar(
        title: Text(
          l10n.reminderHistoryTitle,
          style: TextStyle(fontWeight: FontWeight.w800, color: colors.textPrimary),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: repo.streamReminderHistory(customerId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(color: colors.accent),
            );
          }

          final reminders = snapshot.data!;

          if (reminders.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history_toggle_off, size: 48, color: colors.textSecondary),
                  const SizedBox(height: 12),
                  Text(
                    l10n.noReminderHistory,
                    style: TextStyle(color: colors.textSecondary),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: reminders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final reminder = reminders[index];

              final timestamp = reminder['reminderDate'];
              final dateTime = timestamp is Timestamp
                  ? timestamp.toDate()
                  : timestamp as DateTime;

              final formattedDate =
                  DateFormat('d MMMM yyyy • hh:mm a').format(dateTime);

              final rawStatus = reminder['status'];
              final isActive = rawStatus == 'active';
              final isExpired = rawStatus == 'expired';

              final statusLabel = isActive
                  ? l10n.statusActive
                  : isExpired
                      ? l10n.statusExpired
                      : rawStatus.toString();

              final statusColor = isActive
                  ? colors.clear
                  : isExpired
                      ? colors.textSecondary
                      : colors.warn;

              final note = (reminder['note'] as String?)?.trim() ?? '';
              final isRecurring = reminder['isRecurring'] == true;
              final recurrenceType = reminder['recurrenceType']?.toString();
              final recurrenceLabel = switch (recurrenceType) {
                'weekly' => l10n.recurrenceWeekly,
                'biweekly' => l10n.recurrenceBiweeklyShort,
                'monthly' => l10n.recurrenceMonthlyShort,
                _ => null,
              };

              return Container(
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
                      backgroundColor: statusColor,
                      child: Icon(
                        isActive ? Icons.alarm : Icons.alarm_off,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  formattedDate,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: colors.textPrimary,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  statusLabel,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (isRecurring && recurrenceLabel != null) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.repeat_rounded, size: 13, color: colors.accent),
                                const SizedBox(width: 4),
                                Text(
                                  l10n.recurringLabel(recurrenceLabel),
                                  style: TextStyle(fontSize: 11.5, color: colors.accent, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ],
                          if (note.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: colors.scaffoldBg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: colors.borderColor),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.sticky_note_2_outlined,
                                      size: 16, color: colors.textSecondary),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      note,
                                      style: TextStyle(color: colors.textSecondary),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
