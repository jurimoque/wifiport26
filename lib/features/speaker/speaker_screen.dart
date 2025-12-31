import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/colors.dart';
import '../../services/session/session_manager.dart';
import '../../widgets/microphone_icon.dart';
import '../../widgets/qr_display.dart';
import '../../widgets/connection_indicator.dart';

class SpeakerScreen extends StatefulWidget {
  const SpeakerScreen({super.key});

  @override
  State<SpeakerScreen> createState() => _SpeakerScreenState();
}

class _SpeakerScreenState extends State<SpeakerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _initializeSpeaker();
  }

  Future<void> _initializeSpeaker() async {
    final session = context.read<SessionManager>();
    final success = await session.startAsSpeaker();
    
    if (mounted) {
      setState(() {
        _isInitializing = false;
      });
      
      if (!success) {
        _showErrorDialog(session.error ?? 'Error desconocido');
      }
    }
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Volver'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionManager>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isStreaming = session.state == SessionState.ready ||
                        session.state == SessionState.streaming;
    
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
        title: const Text('Emisor'),
        actions: [
          if (isStreaming)
            ListenerCountBadge(
              count: session.listenerCount,
              size: 48,
            ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isInitializing
          ? _buildLoadingState()
          : session.state == SessionState.error
              ? _buildErrorState(session)
              : _buildStreamingState(session, isStreaming),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppColors.primary,
          ),
          SizedBox(height: 24),
          Text('Iniciando emisión...'),
        ],
      ),
    );
  }

  Widget _buildErrorState(SessionManager session) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 80,
              color: AppColors.error,
            ),
            const SizedBox(height: 24),
            Text(
              'Error',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            Text(
              session.error ?? 'Error desconocido',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                await session.stopSession();
                if (mounted) Navigator.of(context).pop();
              },
              child: const Text('Volver'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreamingState(SessionManager session, bool isStreaming) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Large microphone icon
          AnimatedMicrophoneIcon(
            size: 140,
            isStreaming: isStreaming,
            isMuted: session.isMuted,
          ),
          
          const SizedBox(height: 32),
          
          // Status text
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Text(
                session.isMuted ? 'SILENCIADO' : 'EN VIVO',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: session.isMuted 
                      ? AppColors.textMuted
                      : AppColors.success.withValues(
                          alpha: 0.7 + (0.3 * _pulseController.value),
                        ),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 4,
                ),
              );
            },
          ),
          
          const SizedBox(height: 8),
          
          Text(
            session.listenerCount == 0
                ? 'Esperando oyentes...'
                : '${session.listenerCount} ${session.listenerCount == 1 ? 'oyente conectado' : 'oyentes conectados'}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          
          const SizedBox(height: 40),
          
          // QR Code section
          if (session.connectionUri != null)
            QRDisplay(
              data: session.connectionUri!,
              pin: session.sessionPin,
            ),
          
          const SizedBox(height: 24),
          
          // Connection info
          if (session.localIp != null)
            _buildConnectionInfo(session),
          
          const SizedBox(height: 32),
          
          // Control buttons
          _buildControlButtons(session),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildConnectionInfo(SessionManager session) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.cardDark
            : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.wifi_rounded,
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            '${session.localIp}:8080',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 18),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: session.connectionUri ?? ''));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Copiado al portapapeles'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            tooltip: 'Copiar',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons(SessionManager session) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Mute button
        _ControlButton(
          icon: session.isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
          label: session.isMuted ? 'Activar' : 'Silenciar',
          isActive: !session.isMuted,
          onPressed: session.toggleMute,
        ),
        
        const SizedBox(width: 24),
        
        // Stop button
        _ControlButton(
          icon: Icons.stop_rounded,
          label: 'Detener',
          isDestructive: true,
          onPressed: () async {
            await session.stopSession();
            if (mounted) Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool isDestructive;
  final VoidCallback onPressed;

  const _ControlButton({
    required this.icon,
    required this.label,
    this.isActive = true,
    this.isDestructive = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive 
        ? AppColors.error
        : isActive 
            ? AppColors.primary 
            : AppColors.textMuted;
    
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(28),
            child: Ink(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                icon,
                color: color,
                size: 32,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: color,
          ),
        ),
      ],
    );
  }
}
