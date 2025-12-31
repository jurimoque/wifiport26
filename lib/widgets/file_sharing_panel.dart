import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../core/theme/colors.dart';
import '../services/file_sharing/file_sharing_service.dart';

/// Panel for the speaker to share files
class FileSharingPanel extends StatefulWidget {
  const FileSharingPanel({super.key});

  @override
  State<FileSharingPanel> createState() => _FileSharingPanelState();
}

class _FileSharingPanelState extends State<FileSharingPanel> {
  bool _isLoading = false;

  Future<void> _pickAndShareFile({required bool imagesOnly}) async {
    setState(() => _isLoading = true);
    
    try {
      FilePickerResult? result;
      
      if (imagesOnly) {
        result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: true,
          withData: true,
        );
      } else {
        result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
          allowMultiple: true,
          withData: true,
        );
      }
      
      if (result != null && mounted) {
        final fileService = context.read<FileSharingService>();
        
        for (final file in result.files) {
          if (file.bytes != null && file.name.isNotEmpty) {
            await fileService.shareFileFromBytes(file.name, file.bytes!);
          }
        }
        
        if (result.files.isNotEmpty && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result.files.length == 1 
                  ? 'Archivo compartido: ${result.files.first.name}'
                  : '${result.files.length} archivos compartidos',
              ),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al compartir: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FileSharingService>(
      builder: (context, fileService, _) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.cardDark
                : AppColors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primaryDark,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.folder_shared_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Compartir Archivos',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'PDFs e imágenes para tus oyentes',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Share buttons
              Row(
                children: [
                  Expanded(
                    child: _ShareButton(
                      icon: Icons.image_rounded,
                      label: 'Fotos',
                      color: AppColors.success,
                      isLoading: _isLoading,
                      onPressed: () => _pickAndShareFile(imagesOnly: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ShareButton(
                      icon: Icons.picture_as_pdf_rounded,
                      label: 'PDF',
                      color: AppColors.error,
                      isLoading: _isLoading,
                      onPressed: () => _pickAndShareFile(imagesOnly: false),
                    ),
                  ),
                ],
              ),
              
              // Shared files list
              if (fileService.sharedFiles.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Archivos compartidos (${fileService.sharedFiles.length})',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                ...fileService.sharedFiles.map((file) => _SharedFileItem(
                  file: file,
                  onRemove: () => fileService.removeSharedFile(file.id),
                )),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ShareButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isLoading;
  final VoidCallback onPressed;

  const _ShareButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                )
              else
                Icon(icon, color: color, size: 22),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SharedFileItem extends StatelessWidget {
  final SharedFile file;
  final VoidCallback onRemove;

  const _SharedFileItem({
    required this.file,
    required this.onRemove,
  });

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark 
            ? AppColors.backgroundDark.withValues(alpha: 0.5) 
            : AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: file.isImage 
                  ? AppColors.success.withValues(alpha: 0.2)
                  : AppColors.error.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              file.isImage ? Icons.image_rounded : Icons.picture_as_pdf_rounded,
              color: file.isImage ? AppColors.success : AppColors.error,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _formatSize(file.size),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20),
            onPressed: onRemove,
            color: AppColors.textMuted,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
