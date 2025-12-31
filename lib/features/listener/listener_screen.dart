import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/theme/colors.dart';
import '../../services/session/session_manager.dart';
import '../../widgets/connection_indicator.dart';

class ListenerScreen extends StatefulWidget {
  const ListenerScreen({super.key});

  @override
  State<ListenerScreen> createState() => _ListenerScreenState();
}

class _ListenerScreenState extends State<ListenerScreen> {
  final _pinController = TextEditingController();
  final _ipController = TextEditingController();
  bool _showScanner = true;
  bool _isConnecting = false;
  MobileScannerController? _scannerController;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    _pinController.dispose();
    _ipController.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  Future<void> _connectWithData(String data) async {
    if (_isConnecting || data.isEmpty) return;
    
    setState(() {
      _isConnecting = true;
    });
    
    final session = context.read<SessionManager>();
    final success = await session.connectAsListener(data);
    
    if (mounted) {
      setState(() {
        _isConnecting = false;
      });
      
      if (!success) {
        _showErrorSnackbar(session.error ?? 'Error de conexión');
      }
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionManager>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () async {
            await session.stopSession();
            if (mounted) Navigator.of(context).pop();
          },
        ),
        title: const Text('Oyente'),
        actions: [
          if (session.state == SessionState.connected ||
              session.state == SessionState.streaming)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: ConnectionIndicator(
                quality: ConnectionQuality.excellent,
                showLabel: false,
              ),
            ),
        ],
      ),
      body: session.state == SessionState.connected ||
             session.state == SessionState.streaming
          ? _buildConnectedState(session)
          : _buildScanState(),
    );
  }

  Widget _buildScanState() {
    return Column(
      children: [
        // Scanner / Manual input toggle
        Padding(
          padding: const EdgeInsets.all(16),
          child: _buildToggle(),
        ),
        
        Expanded(
          child: _showScanner
              ? _buildQRScanner()
              : _buildManualInput(),
        ),
        
        if (_isConnecting)
          Container(
            padding: const EdgeInsets.all(24),
            child: const Column(
              children: [
                CircularProgressIndicator(color: AppColors.primary),
                SizedBox(height: 16),
                Text('Conectando...'),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.cardDark
            : AppColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ToggleButton(
              icon: Icons.qr_code_scanner_rounded,
              label: 'Escanear QR',
              isSelected: _showScanner,
              onPressed: () => setState(() => _showScanner = true),
            ),
          ),
          Expanded(
            child: _ToggleButton(
              icon: Icons.edit_rounded,
              label: 'Introducir PIN',
              isSelected: !_showScanner,
              onPressed: () => setState(() => _showScanner = false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRScanner() {
    return Column(
      children: [
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                MobileScanner(
                  controller: _scannerController,
                  onDetect: (capture) {
                    final barcode = capture.barcodes.firstOrNull;
                    if (barcode?.rawValue != null) {
                      _connectWithData(barcode!.rawValue!);
                    }
                  },
                ),
                
                // Scan overlay
                Positioned.fill(
                  child: CustomPaint(
                    painter: _ScanOverlayPainter(),
                  ),
                ),
                
                // Instructions
                Positioned(
                  bottom: 32,
                  left: 0,
                  right: 0,
                  child: Text(
                    'Apunta la cámara al código QR',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      shadows: [
                        const Shadow(
                          color: Colors.black54,
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Camera controls
        Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.flash_auto_rounded),
                onPressed: () => _scannerController?.toggleTorch(),
                tooltip: 'Flash',
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.cameraswitch_rounded),
                onPressed: () => _scannerController?.switchCamera(),
                tooltip: 'Cambiar cámara',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildManualInput() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 32),
          
          // IP Address input
          Text(
            'Dirección IP del emisor',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _ipController,
            keyboardType: TextInputType.text,
            decoration: InputDecoration(
              hintText: '192.168.1.100:8080',
              prefixIcon: const Icon(Icons.wifi_rounded),
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.cardDark
                  : AppColors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // PIN input
          Text(
            'PIN de sesión (opcional)',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: InputDecoration(
              hintText: '123456',
              prefixIcon: const Icon(Icons.pin_outlined),
              counterText: '',
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.cardDark
                  : AppColors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Connect button
          ElevatedButton(
            onPressed: _isConnecting
                ? null
                : () {
                    final ip = _ipController.text.trim();
                    if (ip.isNotEmpty) {
                      _connectWithData(ip);
                    }
                  },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
            ),
            child: _isConnecting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Conectar'),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectedState(SessionManager session) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? AppColors.darkGradient
            : const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.background, Colors.white],
              ),
      ),
      child: Column(
        children: [
          const Spacer(),
          
          // Audio visualization placeholder
          _AudioVisualization(isPlaying: session.state == SessionState.streaming),
          
          const SizedBox(height: 32),
          
          // Connection quality
          const ConnectionIndicator(
            quality: ConnectionQuality.excellent,
          ),
          
          const SizedBox(height: 16),
          
          // Status text
          Text(
            session.state == SessionState.streaming
                ? 'Recibiendo audio...'
                : 'Conectado',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const Spacer(),
          
          // Volume control (placeholder)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Row(
              children: [
                const Icon(Icons.volume_down_rounded, color: AppColors.textSecondary),
                Expanded(
                  child: Slider(
                    value: 0.8,
                    onChanged: (value) {
                      // TODO: Implement volume control
                    },
                    activeColor: AppColors.primary,
                    inactiveColor: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                const Icon(Icons.volume_up_rounded, color: AppColors.textSecondary),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Disconnect button
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  await session.stopSession();
                  if (mounted) Navigator.of(context).pop();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Desconectar'),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onPressed;

  const _ToggleButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black38;
    
    final cutoutSize = size.width * 0.7;
    final cutoutRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: cutoutSize,
      height: cutoutSize,
    );
    
    // Draw semi-transparent overlay
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()
          ..addRRect(RRect.fromRectAndRadius(cutoutRect, const Radius.circular(16))),
      ),
      paint,
    );
    
    // Draw corner accents
    final cornerPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    
    final cornerLength = cutoutSize * 0.15;
    
    // Top-left corner
    canvas.drawLine(
      Offset(cutoutRect.left, cutoutRect.top + 16),
      Offset(cutoutRect.left, cutoutRect.top + 16 + cornerLength),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(cutoutRect.left + 16, cutoutRect.top),
      Offset(cutoutRect.left + 16 + cornerLength, cutoutRect.top),
      cornerPaint,
    );
    
    // Top-right corner
    canvas.drawLine(
      Offset(cutoutRect.right, cutoutRect.top + 16),
      Offset(cutoutRect.right, cutoutRect.top + 16 + cornerLength),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(cutoutRect.right - 16, cutoutRect.top),
      Offset(cutoutRect.right - 16 - cornerLength, cutoutRect.top),
      cornerPaint,
    );
    
    // Bottom-left corner
    canvas.drawLine(
      Offset(cutoutRect.left, cutoutRect.bottom - 16),
      Offset(cutoutRect.left, cutoutRect.bottom - 16 - cornerLength),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(cutoutRect.left + 16, cutoutRect.bottom),
      Offset(cutoutRect.left + 16 + cornerLength, cutoutRect.bottom),
      cornerPaint,
    );
    
    // Bottom-right corner
    canvas.drawLine(
      Offset(cutoutRect.right, cutoutRect.bottom - 16),
      Offset(cutoutRect.right, cutoutRect.bottom - 16 - cornerLength),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(cutoutRect.right - 16, cutoutRect.bottom),
      Offset(cutoutRect.right - 16 - cornerLength, cutoutRect.bottom),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AudioVisualization extends StatefulWidget {
  final bool isPlaying;

  const _AudioVisualization({required this.isPlaying});

  @override
  State<_AudioVisualization> createState() => _AudioVisualizationState();
}

class _AudioVisualizationState extends State<_AudioVisualization>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    if (widget.isPlaying) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_AudioVisualization oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isPlaying && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isPlaying) {
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
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.2),
            AppColors.primary.withValues(alpha: 0.05),
          ],
        ),
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _AudioWavesPainter(
              progress: _controller.value,
              isPlaying: widget.isPlaying,
            ),
          );
        },
      ),
    );
  }
}

class _AudioWavesPainter extends CustomPainter {
  final double progress;
  final bool isPlaying;

  _AudioWavesPainter({required this.progress, required this.isPlaying});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Draw concentric circles
    for (int i = 0; i < 4; i++) {
      final radius = size.width * 0.15 + (i * size.width * 0.1);
      final opacity = isPlaying
          ? 0.3 + (0.3 * ((progress + (i * 0.25)) % 1.0))
          : 0.2;
      
      final paint = Paint()
        ..color = AppColors.primary.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      
      canvas.drawCircle(center, radius, paint);
    }
    
    // Draw center icon
    final iconPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;
    
    // Simple headphone icon representation
    final iconPath = Path();
    final iconSize = size.width * 0.15;
    
    // Arc for headband
    iconPath.addArc(
      Rect.fromCenter(center: center, width: iconSize * 1.8, height: iconSize * 1.4),
      3.14,
      3.14,
    );
    
    canvas.drawPath(iconPath, Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round);
    
    // Ear cups
    canvas.drawCircle(
      Offset(center.dx - iconSize * 0.8, center.dy),
      iconSize * 0.35,
      iconPaint,
    );
    canvas.drawCircle(
      Offset(center.dx + iconSize * 0.8, center.dy),
      iconSize * 0.35,
      iconPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _AudioWavesPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isPlaying != isPlaying;
  }
}
