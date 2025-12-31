import 'package:flutter/material.dart';
import '../core/theme/colors.dart';

enum ConnectionQuality { excellent, good, fair, poor, disconnected }

/// Animated connection quality indicator
class ConnectionIndicator extends StatefulWidget {
  final ConnectionQuality quality;
  final bool showLabel;
  final double size;

  const ConnectionIndicator({
    super.key,
    this.quality = ConnectionQuality.disconnected,
    this.showLabel = true,
    this.size = 24,
  });

  @override
  State<ConnectionIndicator> createState() => _ConnectionIndicatorState();
}

class _ConnectionIndicatorState extends State<ConnectionIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    
    if (widget.quality == ConnectionQuality.poor) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(ConnectionIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.quality == ConnectionQuality.poor) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildBars(),
        if (widget.showLabel) ...[
          const SizedBox(width: 8),
          Text(
            _getLabel(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: _getColor(),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBars() {
    final activeBars = _getActiveBars();
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(4, (index) {
            final isActive = index < activeBars;
            final height = widget.size * (0.4 + (index * 0.2));
            
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              width: widget.size * 0.15,
              height: height,
              decoration: BoxDecoration(
                color: isActive 
                    ? _getColor().withValues(
                        alpha: widget.quality == ConnectionQuality.poor
                            ? 0.5 + (_controller.value * 0.5)
                            : 1,
                      )
                    : _getColor().withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }

  int _getActiveBars() {
    switch (widget.quality) {
      case ConnectionQuality.excellent:
        return 4;
      case ConnectionQuality.good:
        return 3;
      case ConnectionQuality.fair:
        return 2;
      case ConnectionQuality.poor:
        return 1;
      case ConnectionQuality.disconnected:
        return 0;
    }
  }

  Color _getColor() {
    switch (widget.quality) {
      case ConnectionQuality.excellent:
        return AppColors.connectionExcellent;
      case ConnectionQuality.good:
        return AppColors.connectionGood;
      case ConnectionQuality.fair:
        return AppColors.connectionFair;
      case ConnectionQuality.poor:
        return AppColors.connectionPoor;
      case ConnectionQuality.disconnected:
        return AppColors.textMuted;
    }
  }

  String _getLabel() {
    switch (widget.quality) {
      case ConnectionQuality.excellent:
        return 'Excelente';
      case ConnectionQuality.good:
        return 'Buena';
      case ConnectionQuality.fair:
        return 'Regular';
      case ConnectionQuality.poor:
        return 'Débil';
      case ConnectionQuality.disconnected:
        return 'Desconectado';
    }
  }
}

/// Listener count badge
class ListenerCountBadge extends StatelessWidget {
  final int count;
  final double size;

  const ListenerCountBadge({
    super.key,
    required this.count,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child: Text(
              count.toString(),
              key: ValueKey(count),
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            count == 1 ? 'oyente' : 'oyentes',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}
