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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: AppConfigService.watch(),
      builder: (context, snapshot) {
        final config = snapshot.data ?? {};

        if (config['maintenanceEnabled'] == true) {
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
