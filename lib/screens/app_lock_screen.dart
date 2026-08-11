import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import '../l10n/app_localizations.dart';
import '../services/pin_lockout_service.dart';
import '../services/pin_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_settings_scope.dart';

enum AppLockMode { setup, unlock, confirmChange }

class AppLockScreen extends StatefulWidget {
  const AppLockScreen({
    super.key,
    required this.mode,
    this.onUnlocked,
  });

  final AppLockMode mode;
  final VoidCallback? onUnlocked;

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  String _enteredPin = '';
  String? _firstPin; // setup মোডে প্রথমবার দেওয়া PIN, confirm করার জন্য
  String? _errorText;
  bool _checkingBiometric = false;

  DateTime? _lockoutUntil;
  Duration _lockoutRemaining = Duration.zero;
  Timer? _lockoutTicker;

  final LocalAuthentication _localAuth = LocalAuthentication();

  bool get _isLockedOut => _lockoutRemaining > Duration.zero;

  @override
  void initState() {
    super.initState();
    if (widget.mode == AppLockMode.unlock) {
      _refreshLockoutState().then((_) {
        if (mounted && !_isLockedOut) _tryBiometricUnlock();
      });
    }
  }

  @override
  void dispose() {
    _lockoutTicker?.cancel();
    super.dispose();
  }

  Future<void> _refreshLockoutState() async {
    final until = await PinLockoutService.getLockoutUntil();
    _lockoutUntil = until;
    _updateLockoutRemaining();
    if (until != null) _startLockoutTicker();
  }

  void _updateLockoutRemaining() {
    final until = _lockoutUntil;
    final remaining = until == null
        ? Duration.zero
        : until.difference(DateTime.now());
    if (mounted) {
      setState(() {
        _lockoutRemaining = remaining.isNegative ? Duration.zero : remaining;
      });
    }
  }

  void _startLockoutTicker() {
    _lockoutTicker?.cancel();
    _lockoutTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateLockoutRemaining();
      if (!_isLockedOut) _lockoutTicker?.cancel();
    });
  }

  Future<void> _tryBiometricUnlock() async {
    final unlockReason = AppLocalizations.of(context)!.unlockToVerify;
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      if (!canCheck || !isSupported) return;

      setState(() => _checkingBiometric = true);
      final didAuth = await _localAuth.authenticate(
        localizedReason: unlockReason,
        options: const AuthenticationOptions(biometricOnly: true),
      );
      if (didAuth && mounted) {
        widget.onUnlocked?.call();
      }
    } catch (_) {
      // biometric না থাকলে/ব্যর্থ হলে PIN দিয়ে চালিয়ে যাবে
    } finally {
      if (mounted) setState(() => _checkingBiometric = false);
    }
  }

  void _onDigit(String digit) {
    if (_isLockedOut) return;
    if (_enteredPin.length >= 4) return;
    HapticFeedback.lightImpact();
    setState(() {
      _enteredPin += digit;
      _errorText = null;
    });

    if (_enteredPin.length == 4) {
      _handleComplete();
    }
  }

  void _onBackspace() {
    if (_enteredPin.isEmpty) return;
    setState(() {
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
    });
  }

  Future<void> _handleComplete() async {
    final controller = AppSettingsScope.of(context);
    final settings = controller.settings;
    final l10n = AppLocalizations.of(context)!;

    if (widget.mode == AppLockMode.unlock) {
      final storedHash = settings.appLockPinHash;
      if (storedHash != null && PinService.verifyPin(_enteredPin, storedHash)) {
        await PinLockoutService.reset();
        // ✅ পুরনো ফরম্যাটের হ্যাশ হলে, সঠিক PIN verify হওয়ার পরই নিরাপদে নতুন
        // (salted + PBKDF2) ফরম্যাটে migrate করে দেওয়া হচ্ছে। ব্যাকগ্রাউন্ডে সেভ হয়
        // বলে unlock experience-এ কোনো বাড়তি দেরি হয় না।
        if (PinService.isLegacyFormat(storedHash)) {
          final upgradedHash = PinService.hashPin(_enteredPin);
          unawaited(
            controller.update(settings.copyWith(appLockPinHash: upgradedHash)),
          );
        }
        widget.onUnlocked?.call();
      } else {
        final lockoutUntil = await PinLockoutService.recordFailedAttempt();
        if (!mounted) return;
        _lockoutUntil = lockoutUntil;
        _updateLockoutRemaining();
        if (lockoutUntil != null) _startLockoutTicker();
        setState(() {
          _errorText = lockoutUntil != null
              ? l10n.tooManyFailedPinAttempts
              : l10n.wrongPinTryAgain;
          _enteredPin = '';
        });
      }
      return;
    }

    // ✅ Setup মোড — দুইবার একই PIN কনফার্ম করাতে হবে
    if (_firstPin == null) {
      setState(() {
        _firstPin = _enteredPin;
        _enteredPin = '';
      });
      return;
    }

    if (_firstPin == _enteredPin) {
      final hash = PinService.hashPin(_enteredPin);
      await controller.update(
        settings.copyWith(appLockEnabled: true, appLockPinHash: hash),
      );
      if (mounted) Navigator.pop(context, true);
    } else {
      setState(() {
        _errorText = l10n.pinMismatchTryAgain;
        _firstPin = null;
        _enteredPin = '';
      });
    }
  }

  String _formatLockoutRemaining() {
    final l10n = AppLocalizations.of(context)!;
    final total = _lockoutRemaining.inSeconds;
    if (total < 60) return l10n.lockoutSeconds(total);
    final minutes = total ~/ 60;
    final seconds = total % 60;
    return seconds == 0
        ? l10n.lockoutMinutes(minutes)
        : l10n.lockoutMinutesSeconds(minutes, seconds);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isSetup = widget.mode == AppLockMode.setup;
    final title = isSetup
        ? (_firstPin == null ? l10n.setNewPinTitle : l10n.reEnterPinTitle)
        : l10n.unlockWithPinTitle;

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [colors.accent, colors.accentAlt]),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_rounded, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 24),

              // ✅ PIN dots indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  final filled = i < _enteredPin.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled ? colors.accent : colors.surfaceAlt,
                      border: Border.all(color: colors.borderColor),
                    ),
                  );
                }),
              ),

              if (_isLockedOut) ...[
                const SizedBox(height: 14),
                Text(
                  l10n.tooManyAttemptsCountdown(_formatLockoutRemaining()),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.due, fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
              ] else if (_errorText != null) ...[
                const SizedBox(height: 14),
                Text(_errorText!, style: TextStyle(color: colors.due, fontSize: 12.5, fontWeight: FontWeight.w600)),
              ],

              if (_checkingBiometric) ...[
                const SizedBox(height: 14),
                CircularProgressIndicator(color: colors.accent, strokeWidth: 2),
              ],

              const Spacer(),

              // ✅ Numeric keypad — লকআউট চলাকালীন disabled
              IgnorePointer(
                ignoring: _isLockedOut,
                child: Opacity(
                  opacity: _isLockedOut ? 0.4 : 1,
                  child: _NumPad(
                    colors: colors,
                    onDigit: _onDigit,
                    onBackspace: _onBackspace,
                  ),
                ),
              ),

              if (!isSetup) ...[
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: _checkingBiometric ? null : _tryBiometricUnlock,
                  icon: Icon(Icons.fingerprint_rounded, color: colors.accent),
                  label: Text(l10n.tryFingerprint, style: TextStyle(color: colors.accent, fontWeight: FontWeight.w700)),
                ),
              ],

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _NumPad extends StatelessWidget {
  const _NumPad({required this.colors, required this.onDigit, required this.onBackspace});

  final dynamic colors;
  final void Function(String) onDigit;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    final keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', '⌫'];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: keys.map((key) {
        if (key.isEmpty) return const SizedBox();
        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: key == '⌫' ? onBackspace : () => onDigit(key),
          child: Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.borderColor),
            ),
            alignment: Alignment.center,
            child: key == '⌫'
                ? Icon(Icons.backspace_outlined, color: colors.textPrimary, size: 20)
                : Text(key, style: TextStyle(color: colors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
          ),
        );
      }).toList(),
    );
  }
}