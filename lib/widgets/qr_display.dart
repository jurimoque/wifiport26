import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../core/theme/colors.dart';

/// Widget to display QR code with connection info
class QRDisplay extends StatelessWidget {
  final String data;
  final String? pin;
  final double size;
  final bool showPin;

  const QRDisplay({
    super.key,
    required this.data,
    this.pin,
    this.size = 200,
    this.showPin = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: isDark ? 0.3 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // QR Code
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: QrImageView(
              data: data,
              version: QrVersions.auto,
              size: size,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: AppColors.primaryDark,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: AppColors.primaryDark,
              ),
              embeddedImage: null,
            ),
          ),
          
          if (showPin && pin != null) ...[
            const SizedBox(height: 24),
            
            // Divider with "OR" text
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 1,
                    color: isDark 
                        ? AppColors.textMuted.withValues(alpha: 0.3)
                        : AppColors.textSecondary.withValues(alpha: 0.3),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'O INGRESA EL PIN',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isDark ? AppColors.textMuted : AppColors.textSecondary,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 1,
                    color: isDark 
                        ? AppColors.textMuted.withValues(alpha: 0.3)
                        : AppColors.textSecondary.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // PIN Display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.pin_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _formatPin(pin!),
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 8,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  String _formatPin(String pin) {
    // Format as XXX-XXX for better readability
    if (pin.length == 6) {
      return '${pin.substring(0, 3)}-${pin.substring(3)}';
    }
    return pin;
  }
}
