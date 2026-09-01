import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../screens/force_update_screen.dart';
import '../screens/maintenance_screen.dart';
import '../services/app_config_service.dart';

// ✅ MaterialApp এর সবচেয়ে বাইরের gate — login এর আগেও maintenance/force-update
// চেক করে, যাতে কেউ maintenance চলাকালীন লগইন করতে না পারে। Config fetch ফেইল
// করলে (নেটওয়ার্ক ইস্যু ইত্যাদি) fail-open — অ্যাপ ব্লক না করে চলতে দেওয়া হয়,
// কারণ এই ফিচার non-critical।
class AppConfigGate extends StatefulWidget {
  const AppConfigGate({super.key, required this.child});

  final Widget child;

  @override
  State<AppConfigGate> createState() => _AppConfigGateState();
}

class _AppConfigGateState extends State<AppConfigGate> {
  String? _installedVersion;
  Timer? _maintenanceExpiryTimer;

  @override
  void initState() {
    super.initState();
    _loadInstalledVersion();
  }

  Future<void> _loadInstalledVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _installedVersion = info.version);
    } catch (_) {
      // ✅ ফেইল হলে installed version অজানা থাকবে — force-update চেক স্কিপ হবে (fail-open)
    }
  }

  // ✅ maintenanceUntil পার হয়ে গেলে maintenance আর active থাকে না — অ্যাডমিন প্যানেলে
  // toggle ম্যানুয়ালি off না করলেও app নিজে থেকে আনব্লক হয়ে যায়।
  bool _isMaintenanceActive(Map<String, dynamic> config) {
    if (config['maintenanceEnabled'] != true) return false;
    final until = config['maintenanceUntil'] as Timestamp?;
    if (until == null) return true;
    return until.toDate().isAfter(DateTime.now());
  }

  // ✅ ETA-র মুহূর্তেই স্ক্রিন সরাতে একটা one-shot টাইমার সেট করা — নাহলে app খোলা
  // অবস্থায় বসে থাকলে, নতুন কোনো Firestore আপডেট না আসা পর্যন্ত rebuild না হয়ে
  // maintenance স্ক্রিন সময় পার হয়ে যাওয়ার পরও দেখাতে থাকতে পারত।
  void _scheduleExpiryRebuild(Timestamp? until) {
    _maintenanceExpiryTimer?.cancel();
    _maintenanceExpiryTimer = null;
    if (until == null) return;
    final remaining = until.toDate().difference(DateTime.now());
    if (remaining.isNegative) return;
    _maintenanceExpiryTimer = Timer(remaining, () {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _maintenanceExpiryTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: AppConfigService.watch(),
      builder: (context, snapshot) {
        final config = snapshot.data ?? {};

        if (_isMaintenanceActive(config)) {
          _scheduleExpiryRebuild(config['maintenanceUntil'] as Timestamp?);
          return MaintenanceScreen(
            message: config['maintenanceMessage'] as String?,
            until: config['maintenanceUntil'] as Timestamp?,
          );
        }

        final minRequiredVersion = (config['minRequiredVersion'] as String? ?? '').trim();
        if (config['forceUpdateEnabled'] == true &&
            minRequiredVersion.isNotEmpty &&
            _installedVersion != null &&
            AppConfigService.isBelowMinVersion(_installedVersion!, minRequiredVersion)) {
          return ForceUpdateScreen(
            minRequiredVersion: minRequiredVersion,
            playStoreUrl: config['playStoreUrl'] as String?,
          );
        }

        return widget.child;
      },
    );
  }
}
