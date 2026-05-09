import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import '../config/theme.dart';

class EmergencyButton extends StatefulWidget {
  final VoidCallback? onActivate;
  final VoidCallback? onCancel;

  const EmergencyButton({
    super.key,
    this.onActivate,
    this.onCancel,
  });

  @override
  State<EmergencyButton> createState() => _EmergencyButtonState();
}

class _EmergencyButtonState extends State<EmergencyButton>
    with SingleTickerProviderStateMixin {
  bool isPressed = false;
  double progress = 0.0;
  Timer? timer;
  late AnimationController _pulseController;

  static const int holdDuration = 3000; // 3 seconds

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startHold() {
    setState(() {
      isPressed = true;
      progress = 0.0;
    });

    const updateInterval = 50; // Update every 50ms
    const increment = updateInterval / holdDuration;

    timer = Timer.periodic(const Duration(milliseconds: updateInterval), (t) {
      setState(() {
        progress += increment;
        if (progress >= 1.0) {
          progress = 1.0;
          _handleActivate();
        }
      });
    });
  }

  void _cancelHold() {
    timer?.cancel();
    setState(() {
      isPressed = false;
      progress = 0.0;
    });
    widget.onCancel?.call();
  }

  void _handleActivate() {
    timer?.cancel();
    setState(() {
      isPressed = false;
      progress = 0.0;
    });
    widget.onActivate?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _startHold(),
      onTapUp: (_) => _cancelHold(),
      onTapCancel: _cancelHold,
      child: SizedBox(
        width: 160,
        height: 160,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Animated ripple effects
            if (isPressed) ...[
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 160 + (_pulseController.value * 100),
                    height: 160 + (_pulseController.value * 100),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accent.withOpacity(
                        0.3 * (1 - _pulseController.value),
                      ),
                    ),
                  );
                },
              ),
            ],

            // Main button
            AnimatedScale(
              scale: isPressed ? 0.95 : 1.0,
              duration: const Duration(milliseconds: 100),
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.accent,
                      Color(0xFFFF6B00),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isPressed
                          ? AppColors.accent.withOpacity(0.6)
                          : Colors.black.withOpacity(0.3),
                      blurRadius: isPressed ? 40 : 20,
                      spreadRadius: isPressed ? 5 : 0,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Progress ring
                    CustomPaint(
                      size: const Size(160, 160),
                      painter: _ProgressRingPainter(progress),
                    ),

                    // Icon and text
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: const Icon(
                            Icons.warning_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'HOLD',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;

  _ProgressRingPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    // Background ring
    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress ring
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;

      final sweepAngle = 2 * math.pi * progress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

