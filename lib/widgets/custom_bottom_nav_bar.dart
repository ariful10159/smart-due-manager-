import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../screens/home_screen.dart';
import '../screens/add_customer_screen.dart';
import '../screens/all_customers_screen.dart';
import '../screens/reminder_screen.dart';

class CustomBottomNavBar extends StatefulWidget {
  final int selectedIndex;
  final bool isDisabled;

  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    this.isDisabled = false,
  });

  @override
  State<CustomBottomNavBar> createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _positionAnim;
  late Animation<double> _scaleAnim;

  static const List<IconData> _selectedIcons = [
    Icons.home_rounded,
    Icons.person_add_alt_1_rounded,
    Icons.people_rounded,
    Icons.notifications_rounded,
  ];

  static const List<IconData> _unselectedIcons = [
    Icons.home_outlined,
    Icons.person_add_alt_1_outlined,
    Icons.people_outline_rounded,
    Icons.notifications_outlined,
  ];

  static const List<String> _labels = [
    'Home',
    'Add Customer',
    'All Customers',
    'Reminders',
  ];

  static const double _barHeight = 64;
  static const double _bubbleSize = 52;
  static const double _bubblePokeAbove = 6;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );

    final start = widget.selectedIndex.toDouble();
    _positionAnim = Tween<double>(begin: start, end: start).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.0).animate(_controller);

    _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(covariant CustomBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      final from = _positionAnim.value;
      final to = widget.selectedIndex.toDouble();

      _positionAnim = Tween<double>(begin: from, end: to).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _scaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
      );

      _controller
        ..value = 0
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTap(BuildContext context, int index) {
    if (widget.isDisabled || index == widget.selectedIndex) return;
    HapticFeedback.selectionClick();

    switch (index) {
      case 0:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AddCustomerScreen()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AllCustomersScreen()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ReminderScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    final double sinkDepth = _bubbleSize - _bubblePokeAbove;
    final double stackExtraHeight = _bubblePokeAbove + 4;

    return IgnorePointer(
      ignoring: widget.isDisabled,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final barWidth = constraints.maxWidth;
              final itemWidth = barWidth / _labels.length;

              return AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final animatedIndex = _positionAnim.value;
                  final notchCenterX =
                      itemWidth * animatedIndex + itemWidth / 2;
                  final bubbleLeft = notchCenterX - _bubbleSize / 2;

                  return SizedBox(
                    height: _barHeight + stackExtraHeight,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.bottomCenter,
                      children: [
                        // ---------- Notched floating bar ----------
                        CustomPaint(
                          size: Size(barWidth, _barHeight),
                          painter: _NotchedBarPainter(
                            notchCenterX: notchCenterX,
                            notchRadius: _bubbleSize / 2 + 6,
                            color: colors.surface,
                            borderColor: colors.borderColor,
                          ),
                          child: SizedBox(
                            height: _barHeight,
                            width: barWidth,
                            child: Row(
                              children: List.generate(_labels.length, (index) {
                                final distance =
                                    (animatedIndex - index).abs();
                                final opacity = distance.clamp(0.0, 1.0);

                                return Expanded(
                                  child: _NavItem(
                                    icon: _unselectedIcons[index],
                                    label: _labels[index],
                                    opacity: opacity,
                                    color: colors.textSecondary,
                                    onTap: () => _onTap(context, index),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),

                        // ---------- Floating animated bubble ----------
                        Positioned(
                          left: bubbleLeft,
                          bottom: _barHeight - sinkDepth,
                          child: Transform.scale(
                            scale: _scaleAnim.value,
                            child: GestureDetector(
                              onTap: () =>
                                  _onTap(context, widget.selectedIndex),
                              child: Container(
                                width: _bubbleSize,
                                height: _bubbleSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [colors.accent, colors.accentAlt],
                                  ),
                                  border: Border.all(
                                    color: colors.scaffoldBg,
                                    width: 3.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: colors.accent.withOpacity(0.45),
                                      blurRadius: 14,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: AnimatedSwitcher(
                                    duration:
                                        const Duration(milliseconds: 250),
                                    transitionBuilder: (child, anim) =>
                                        ScaleTransition(
                                      scale: anim,
                                      child: RotationTransition(
                                        turns: Tween<double>(
                                          begin: 0.75,
                                          end: 1.0,
                                        ).animate(anim),
                                        child: child,
                                      ),
                                    ),
                                    child: Icon(
                                      _selectedIcons[widget.selectedIndex],
                                      key: ValueKey<int>(widget.selectedIndex),
                                      color: Colors.white,
                                      size: 23,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Individual nav item with press-scale feedback
// ============================================================

class _NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final double opacity;
  final Color color;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.opacity,
    required this.color,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _scale = 0.86),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: widget.opacity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: widget.color, size: 22),
              const SizedBox(height: 3),
              Text(
                widget.label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: widget.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Painter: bar with a SMOOTH bezier-curve notch (wave dip),
// instead of a sharp circle-difference cut — merges seamlessly
// into the bar's top edge like premium nav bar designs.
// ============================================================

class _NotchedBarPainter extends CustomPainter {
  final double notchCenterX;
  final double notchRadius;
  final Color color;
  final Color borderColor;

  _NotchedBarPainter({
    required this.notchCenterX,
    required this.notchRadius,
    required this.color,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = _buildNotchedPath(size);

    // soft blurred drop shadow beneath the whole bar
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.20)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawPath(path.shift(const Offset(0, 6)), shadowPaint);

    // bar fill
    canvas.drawPath(path, Paint()..color = color);

    // subtle border outline
    canvas.drawPath(
      path,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  Path _buildNotchedPath(Size size) {
    const double cornerRadius = 32;
    // কতটুকু চওড়া জায়গা জুড়ে স্মুথ ওয়েভ curve টা ছড়াবে —
    // এটাই মূলত rough/sharp জোড়াকে সুন্দর smooth transition বানায়
    final double notchMargin = notchRadius * 0.55;

    final double leftDip = notchCenterX - notchRadius - notchMargin;
    final double rightDip = notchCenterX + notchRadius + notchMargin;
    final double dipDepth = notchRadius + 6;

    final path = Path();

    // top-left rounded corner
    path.moveTo(0, cornerRadius);
    path.quadraticBezierTo(0, 0, cornerRadius, 0);

    // flat section before the wave
    path.lineTo(leftDip, 0);

    // ✅ smooth S-curve going down into the notch (bezier, tangent-matched)
    path.cubicTo(
      leftDip + notchMargin * 0.65, 0,
      notchCenterX - notchRadius * 1.05, dipDepth * 0.92,
      notchCenterX, dipDepth,
    );

    // ✅ smooth S-curve coming back up out of the notch
    path.cubicTo(
      notchCenterX + notchRadius * 1.05, dipDepth * 0.92,
      rightDip - notchMargin * 0.65, 0,
      rightDip, 0,
    );

    // flat section after the wave
    path.lineTo(size.width - cornerRadius, 0);
    path.quadraticBezierTo(size.width, 0, size.width, cornerRadius);

    // right edge
    path.lineTo(size.width, size.height - cornerRadius);
    path.quadraticBezierTo(
      size.width,
      size.height,
      size.width - cornerRadius,
      size.height,
    );

    // bottom edge
    path.lineTo(cornerRadius, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - cornerRadius);

    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _NotchedBarPainter oldDelegate) {
    return oldDelegate.notchCenterX != notchCenterX ||
        oldDelegate.notchRadius != notchRadius ||
        oldDelegate.color != color ||
        oldDelegate.borderColor != borderColor;
  }
}