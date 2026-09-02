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

          final totalReminders = reminders.length;

          // ✅ createdAt অনুযায়ী নতুন-আগে সাজানো, তাই লিস্টের শেষ আইটেমটাই সবচেয়ে
          // পুরনো — অর্থাৎ প্রথম যেদিন এই কাস্টমারের জন্য reminder সেট করা হয়েছিল
          final oldestRaw = reminders.last['createdAt'];
          final oldestCreatedAt = oldestRaw is Timestamp
              ? oldestRaw.toDate()
              : oldestRaw is DateTime
                  ? oldestRaw
                  : DateTime.now();
          final daysSinceFirst = DateTime.now().difference(oldestCreatedAt).inDays;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _buildStatsCard(
                  colors: colors,
                  l10n: l10n,
                  totalReminders: totalReminders,
                  daysSinceFirst: daysSinceFirst,
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: reminders.length,
                  separatorBuilder: (_, __) => SizedBox(
                    height: 22,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 36,
                          child: Center(
                            child: Container(width: 2, height: 22, color: colors.borderColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                  itemBuilder: (context, index) {
                    final reminder = reminders[index];

              // ✅ আগে malformed/missing 'reminderDate' এ সরাসরি `as DateTime`
              // cast crash করত — createdAt এর মতোই এখন নিরাপদ fallback রাখা হলো
              final timestamp = reminder['reminderDate'];
              final dateTime = timestamp is Timestamp
                  ? timestamp.toDate()
                  : timestamp is DateTime
                      ? timestamp
                      : DateTime.now();
              final formattedDate =
                  DateFormat('d MMMM yyyy • hh:mm a').format(dateTime);

              final createdRaw = reminder['createdAt'];
              final createdAt = createdRaw is Timestamp
                  ? createdRaw.toDate()
                  : createdRaw is DateTime
                      ? createdRaw
                      : dateTime;
              final formattedSetOn =
                  DateFormat('d MMMM yyyy • hh:mm a').format(createdAt);

              // ✅ 'active' মানে এটাই কাস্টমারের বর্তমান reminder (নতুন কিছু সেট
              // করে replace হয়নি) — কিন্তু তারিখ পার হয়ে গেছে কিনা সেটা Firestore
              // এ ট্র্যাক করা হয় না, তাই সেটা এখানে সময়ের সাথে তুলনা করে বের করা হয়
              final reminderStatus = reminder['status'] as String? ?? 'active';
              final isActive = reminderStatus == 'active';
              final isCancelled = reminderStatus == 'cancelled';
              final now = DateTime.now();
              final isSameDay = dateTime.year == now.year &&
                  dateTime.month == now.month &&
                  dateTime.day == now.day;
              final isOverdue = !isSameDay && dateTime.isBefore(now);

              final String statusLabel;
              final Color statusColor;
              if (isCancelled) {
                // ✅ ইউজার নিজে reminder cancel করলে 'Replaced' (নতুন
                // reminder সেট করে superseded হওয়া) না দেখিয়ে এটা আলাদা
                // 'Cancelled' লেবেল দেখায়
                statusLabel = l10n.statusCancelled;
                statusColor = colors.textSecondary;
              } else if (!isActive) {
                statusLabel = l10n.statusReplaced;
                statusColor = colors.textSecondary;
              } else if (isOverdue) {
                statusLabel = l10n.statusOverdue;
                statusColor = colors.due;
              } else if (isSameDay) {
                statusLabel = l10n.statusDueToday;
                statusColor = colors.warn;
              } else {
                statusLabel = l10n.statusUpcoming;
                statusColor = colors.clear;
              }

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
                    SizedBox(
                      width: 36,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: statusColor,
                          child: Icon(
                            isActive ? Icons.alarm : Icons.alarm_off,
                            color: Colors.white,
                          ),
                        ),
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
                                  l10n.reminderSetOnLabel(formattedSetOn),
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
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.event_available_rounded, size: 13, color: colors.accent),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  l10n.reminderNextOnLabel(formattedDate),
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: colors.accent,
                                    fontWeight: FontWeight.w600,
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
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatsCard({
    required AppColors colors,
    required AppLocalizations l10n,
    required int totalReminders,
    required int daysSinceFirst,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.accent.withValues(alpha: 0.18), colors.accentAlt.withValues(alpha: 0.10)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderColor),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              colors: colors,
              icon: Icons.alarm_rounded,
              value: '$totalReminders',
              label: l10n.totalRemindersLabel,
            ),
          ),
          Container(width: 1, height: 40, color: colors.borderColor),
          Expanded(
            child: _buildStatItem(
              colors: colors,
              icon: Icons.calendar_month_rounded,
              value: '$daysSinceFirst',
              label: l10n.daysSinceFirstReminderLabel,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required AppColors colors,
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, size: 18, color: colors.accent),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }
}
