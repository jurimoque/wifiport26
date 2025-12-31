import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/colors.dart';
import '../services/file_sharing/file_sharing_service.dart';

/// Widget to display and download shared files on listener side
class ReceivedFilesViewer extends StatefulWidget {
  final String speakerIp;
  
  const ReceivedFilesViewer({
    super.key,
    required this.speakerIp,
  });

  @override
  State<ReceivedFilesViewer> createState() => _ReceivedFilesViewerState();
}

class _ReceivedFilesViewerState extends State<ReceivedFilesViewer> {
  List<SharedFile> _availableFiles = [];
  bool _isLoading = true;
  bool _hasError = false;
  
  @override
  void initState() {
    super.initState();
    _refreshFiles();
  }
  
  Future<void> _refreshFiles() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    
    try {
      final fileService = context.read<FileSharingService>();
      final files = await fileService.fetchAvailableFiles(widget.speakerIp);
      if (mounted) {
        setState(() {
          _availableFiles = files;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
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
                  Icons.download_rounded,
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
                      'Archivos Disponibles',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Del emisor',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: _refreshFiles,
                color: AppColors.primary,
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Content
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_hasError)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.cloud_off_rounded,
                      size: 48,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No se pudo conectar',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _refreshFiles,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            )
          else if (_availableFiles.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.folder_open_rounded,
                      size: 48,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Sin archivos compartidos',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._availableFiles.map((file) => _AvailableFileItem(
              file: file,
              speakerIp: widget.speakerIp,
            )),
        ],
      ),
    );
  }
}

class _AvailableFileItem extends StatelessWidget {
  final SharedFile file;
  final String speakerIp;

  const _AvailableFileItem({
    required this.file,
    required this.speakerIp,
  });

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Consumer<FileSharingService>(
      builder: (context, fileService, _) {
        final receivedFile = fileService.receivedFiles
            .where((f) => f.id == file.id)
            .firstOrNull;
        final isDownloading = receivedFile?.isDownloading ?? false;
        final isDownloaded = receivedFile?.localPath != null;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark 
                ? AppColors.backgroundDark.withValues(alpha: 0.5) 
                : AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: isDownloaded ? Border.all(
              color: AppColors.success.withValues(alpha: 0.5),
              width: 1.5,
            ) : null,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: file.isImage 
                      ? AppColors.success.withValues(alpha: 0.2)
                      : AppColors.error.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: isDownloaded && file.isImage && receivedFile?.data != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(
                          receivedFile!.data!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Icon(
                        file.isImage ? Icons.image_rounded : Icons.picture_as_pdf_rounded,
                        color: file.isImage ? AppColors.success : AppColors.error,
                        size: 22,
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
                    Row(
                      children: [
                        Text(
                          _formatSize(file.size),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (isDownloaded) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.check_circle_rounded,
                            size: 14,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Descargado',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isDownloading)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (isDownloaded)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.visibility_rounded),
                      onPressed: () => _viewFile(context, receivedFile!),
                      color: AppColors.primary,
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Ver',
                    ),
                  ],
                )
              else
                IconButton(
                  icon: const Icon(Icons.download_rounded),
                  onPressed: () => _downloadFile(context),
                  color: AppColors.primary,
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Descargar',
                ),
            ],
          ),
        );
      },
    );
  }
  
  Future<void> _downloadFile(BuildContext context) async {
    final fileService = context.read<FileSharingService>();
    await fileService.downloadFile(speakerIp, file);
  }
  
  void _viewFile(BuildContext context, SharedFile file) {
    if (file.isImage && file.data != null) {
      // Show image in full screen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => _ImageViewer(file: file),
        ),
      );
    } else if (file.isPdf) {
      // For PDF we just show a message - could integrate a PDF viewer
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF guardado en: ${file.localPath}'),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {},
          ),
        ),
      );
    }
  }
}

/// Full screen image viewer
class _ImageViewer extends StatelessWidget {
  final SharedFile file;

  const _ImageViewer({required this.file});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          file.name,
          style: const TextStyle(fontSize: 16),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: file.data != null
              ? Image.memory(file.data!)
              : file.localPath != null
                  ? Image.file(File(file.localPath!))
                  : const Icon(Icons.broken_image, size: 64, color: Colors.white54),
        ),
      ),
    );
  }
}
