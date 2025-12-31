import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme/colors.dart';

/// WiFiPort logo widget
/// Combines WiFi signal arcs with audio wave elements
class WiFiPortLogo extends StatelessWidget {
  final double size;
  final bool animated;

  const WiFiPortLogo({
    super.key,
    this.size = 120,
    this.animated = false,
  });

  @override
  Widget build(BuildContext context) {
    if (animated) {
      return _AnimatedLogo(size: size);
    }
    
    return CustomPaint(
      size: Size(size, size),
      painter: _LogoPainter(),
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.65);
    final maxRadius = size.width * 0.4;
    
    // Draw WiFi arcs
    final arcPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.06
      ..strokeCap = StrokeCap.round;
    
    // Draw 3 arcs representing WiFi signal
    for (int i = 0; i < 3; i++) {
      final radius = maxRadius * (0.4 + (i * 0.3));
      final rect = Rect.fromCenter(
        center: center,
        width: radius * 2,
        height: radius * 2,
      );
      
      // Fade outer arcs slightly
      arcPaint.color = AppColors.primary.withValues(alpha: 1.0 - (i * 0.2));
      
      canvas.drawArc(
        rect,
        -2.35, // ~135 degrees
        1.57, // ~90 degrees sweep
        false,
        arcPaint,
      );
    }
    
    // Draw center dot (audio source)
    final dotPaint = Paint()
      ..color = AppColors.primaryDark
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, size.width * 0.08, dotPaint);
    
    // Draw sound wave lines emanating from center
    final wavePaint = Paint()
      ..color = AppColors.primaryDark.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.025
      ..strokeCap = StrokeCap.round;
    
    // Small wave lines on the sides
    for (int i = 0; i < 2; i++) {
      final waveRadius = size.width * (0.15 + (i * 0.08));
      final waveCenter = Offset(center.dx, center.dy);
      
      // Left wave
      canvas.drawArc(
        Rect.fromCenter(
          center: waveCenter,
          width: waveRadius * 2,
          height: waveRadius * 1.5,
        ),
        2.8,
        0.6,
        false,
        wavePaint,
      );
      
      // Right wave
      canvas.drawArc(
        Rect.fromCenter(
          center: waveCenter,
          width: waveRadius * 2,
          height: waveRadius * 1.5,
        ),
        -0.3,
        0.6,
        false,
        wavePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AnimatedLogo extends StatefulWidget {
  final double size;

  const _AnimatedLogo({required this.size});

  @override
  State<_AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<_AnimatedLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _AnimatedLogoPainter(
            progress: _controller.value,
          ),
        );
      },
    );
  }
}

class _AnimatedLogoPainter extends CustomPainter {
  final double progress;

  _AnimatedLogoPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.65);
    final maxRadius = size.width * 0.4;
    
    // Draw WiFi arcs with staggered animation
    for (int i = 0; i < 3; i++) {
      final radius = maxRadius * (0.4 + (i * 0.3));
      final rect = Rect.fromCenter(
        center: center,
        width: radius * 2,
        height: radius * 2,
      );
      
      // Stagger the animation for each arc
      final arcProgress = ((progress + (i * 0.15)) % 1.0);
      final opacity = (1.0 - (i * 0.2)) * (0.5 + (0.5 * (1 - arcProgress)));
      
      final arcPaint = Paint()
        ..color = AppColors.primary.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.06
        ..strokeCap = StrokeCap.round;
      
      canvas.drawArc(
        rect,
        -2.35,
        1.57,
        false,
        arcPaint,
      );
    }
    
    // Draw pulsing center dot
    final dotScale = 1.0 + (0.2 * (0.5 + 0.5 * math.sin(progress * 2 * math.pi)));
    final dotPaint = Paint()
      ..color = AppColors.primaryDark
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, size.width * 0.08 * dotScale, dotPaint);
    
    // Animated sound waves
    final wavePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.025
      ..strokeCap = StrokeCap.round;
    
    for (int i = 0; i < 2; i++) {
      final waveProgress = ((progress + (i * 0.3)) % 1.0);
      final waveOpacity = 0.6 * (1 - waveProgress);
      final waveRadius = size.width * (0.15 + (i * 0.08) + (waveProgress * 0.05));
      
      wavePaint.color = AppColors.primaryDark.withValues(alpha: waveOpacity);
      
      // Left wave
      canvas.drawArc(
        Rect.fromCenter(
          center: center,
          width: waveRadius * 2,
          height: waveRadius * 1.5,
        ),
        2.8,
        0.6,
        false,
        wavePaint,
      );
      
      // Right wave
      canvas.drawArc(
        Rect.fromCenter(
          center: center,
          width: waveRadius * 2,
          height: waveRadius * 1.5,
        ),
        -0.3,
        0.6,
        false,
        wavePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AnimatedLogoPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// WiFiPort text logo
class WiFiPortTextLogo extends StatelessWidget {
  final double fontSize;
  final bool dark;

  const WiFiPortTextLogo({
    super.key,
    this.fontSize = 32,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          fontFamily: 'Montserrat',
        ),
        children: [
          TextSpan(
            text: 'WiFi',
            style: TextStyle(
              color: dark ? AppColors.white : AppColors.primaryDark,
            ),
          ),
          TextSpan(
            text: 'Port',
            style: TextStyle(
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
