import 'package:flutter/material.dart';
import '../core/theme/colors.dart';

/// Custom SM58-style microphone icon widget
/// Inspired by the iconic Shure SM58 professional microphone
class MicrophoneIcon extends StatelessWidget {
  final double size;
  final Color? color;
  final Color? accentColor;
  final bool isActive;
  final bool showGlow;

  const MicrophoneIcon({
    super.key,
    this.size = 120,
    this.color,
    this.accentColor,
    this.isActive = false,
    this.showGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = color ?? AppColors.primaryDark;
    final highlightColor = accentColor ?? AppColors.primary;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: size,
      height: size * 1.8,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glow effect when active
          if (isActive && showGlow)
            Positioned.fill(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: highlightColor.withValues(alpha: 0.4),
                      blurRadius: size * 0.3,
                      spreadRadius: size * 0.1,
                    ),
                  ],
                ),
              ),
            ),
          
          // Microphone body
          CustomPaint(
            size: Size(size, size * 1.8),
            painter: _SM58Painter(
              bodyColor: primaryColor,
              grillColor: highlightColor,
              isActive: isActive,
            ),
          ),
        ],
      ),
    );
  }
}

class _SM58Painter extends CustomPainter {
  final Color bodyColor;
  final Color grillColor;
  final bool isActive;

  _SM58Painter({
    required this.bodyColor,
    required this.grillColor,
    required this.isActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Proportions based on SM58 design
    final grillWidth = size.width * 0.8;
    final grillHeight = size.height * 0.35;
    final bodyWidth = size.width * 0.5;
    final bodyHeight = size.height * 0.55;
    
    // Paint for the grill (top spherical part)
    final grillPaint = Paint()
      ..color = grillColor
      ..style = PaintingStyle.fill;
    
    // Paint for the body (handle)
    final bodyPaint = Paint()
      ..color = bodyColor
      ..style = PaintingStyle.fill;
    
    // Shadow paint
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    
    // Draw shadow
    final shadowPath = Path();
    shadowPath.addOval(Rect.fromCenter(
      center: Offset(center.dx + 4, size.height * 0.25 + 4),
      width: grillWidth,
      height: grillHeight,
    ));
    canvas.drawPath(shadowPath, shadowPaint);
    
    // Draw the grill (ball grille part) - oval shape
    final grillRect = Rect.fromCenter(
      center: Offset(center.dx, size.height * 0.25),
      width: grillWidth,
      height: grillHeight,
    );
    
    // Draw grill base
    canvas.drawOval(grillRect, grillPaint);
    
    // Draw grill mesh pattern
    final meshPaint = Paint()
      ..color = bodyColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    // Horizontal mesh lines
    for (int i = 0; i < 8; i++) {
      final y = grillRect.top + (grillRect.height / 9) * (i + 1);
      final lineWidth = _getLineWidthAtY(grillRect, y);
      canvas.drawLine(
        Offset(center.dx - lineWidth / 2, y),
        Offset(center.dx + lineWidth / 2, y),
        meshPaint,
      );
    }
    
    // Vertical mesh lines
    for (int i = 0; i < 6; i++) {
      final x = grillRect.left + (grillRect.width / 7) * (i + 1);
      final lineHeight = _getLineHeightAtX(grillRect, x);
      canvas.drawLine(
        Offset(x, grillRect.center.dy - lineHeight / 2),
        Offset(x, grillRect.center.dy + lineHeight / 2),
        meshPaint,
      );
    }
    
    // Draw ring between grill and body
    final ringPaint = Paint()
      ..color = grillColor
      ..style = PaintingStyle.fill;
    
    final ringRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx, grillRect.bottom + 8),
        width: bodyWidth * 1.2,
        height: 16,
      ),
      const Radius.circular(4),
    );
    canvas.drawRRect(ringRect, ringPaint);
    
    // Draw the body (handle)
    final bodyRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(
        center.dx - bodyWidth / 2,
        ringRect.bottom - 4,
        bodyWidth,
        bodyHeight,
      ),
      bottomLeft: Radius.circular(bodyWidth / 2),
      bottomRight: Radius.circular(bodyWidth / 2),
    );
    canvas.drawRRect(bodyRect, bodyPaint);
    
    // Draw body gradient/highlight
    final highlightPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.white.withValues(alpha: 0.1),
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.15),
        ],
      ).createShader(bodyRect.outerRect);
    canvas.drawRRect(bodyRect, highlightPaint);
    
    // Draw active indicator light
    if (isActive) {
      final indicatorPaint = Paint()
        ..color = Colors.red
        ..style = PaintingStyle.fill;
      
      final glowPaint = Paint()
        ..color = Colors.red.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      
      final indicatorCenter = Offset(center.dx, ringRect.center.dy);
      canvas.drawCircle(indicatorCenter, 4, glowPaint);
      canvas.drawCircle(indicatorCenter, 3, indicatorPaint);
    }
  }
  
  double _getLineWidthAtY(Rect oval, double y) {
    final normalizedY = (y - oval.center.dy) / (oval.height / 2);
    final width = oval.width * (1 - normalizedY * normalizedY).clamp(0.0, 1.0);
    return width * 0.9;
  }
  
  double _getLineHeightAtX(Rect oval, double x) {
    final normalizedX = (x - oval.center.dx) / (oval.width / 2);
    final height = oval.height * (1 - normalizedX * normalizedX).clamp(0.0, 1.0);
    return height * 0.9;
  }

  @override
  bool shouldRepaint(covariant _SM58Painter oldDelegate) {
    return oldDelegate.isActive != isActive ||
           oldDelegate.bodyColor != bodyColor ||
           oldDelegate.grillColor != grillColor;
  }
}

/// Animated microphone with pulsing effect when streaming
class AnimatedMicrophoneIcon extends StatefulWidget {
  final double size;
  final bool isStreaming;
  final bool isMuted;

  const AnimatedMicrophoneIcon({
    super.key,
    this.size = 120,
    this.isStreaming = false,
    this.isMuted = false,
  });

  @override
  State<AnimatedMicrophoneIcon> createState() => _AnimatedMicrophoneIconState();
}

class _AnimatedMicrophoneIconState extends State<AnimatedMicrophoneIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    if (widget.isStreaming && !widget.isMuted) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(AnimatedMicrophoneIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isStreaming && !widget.isMuted) {
      if (!_controller.isAnimating) {
        _controller.repeat(reverse: true);
      }
    } else {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isStreaming ? _scaleAnimation.value : 1.0,
          child: Stack(
            alignment: Alignment.center,
            children: [
              MicrophoneIcon(
                size: widget.size,
                isActive: widget.isStreaming && !widget.isMuted,
                color: widget.isMuted ? Colors.grey : null,
                accentColor: widget.isMuted ? Colors.grey.shade400 : null,
              ),
              
              // Mute overlay
              if (widget.isMuted)
                Positioned(
                  top: widget.size * 0.3,
                  child: Container(
                    width: widget.size * 0.8,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    transform: Matrix4.rotationZ(-0.5),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
