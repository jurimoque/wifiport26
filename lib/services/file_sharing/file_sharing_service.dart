import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:mime/mime.dart';

/// Represents a shared file
class SharedFile {
  final String id;
  final String name;
  final String mimeType;
  final int size;
  final String? localPath;
  final Uint8List? data;
  final DateTime sharedAt;
  bool isDownloading;
  double downloadProgress;

  SharedFile({
    required this.id,
    required this.name,
    required this.mimeType,
    required this.size,
    this.localPath,
    this.data,
    DateTime? sharedAt,
    this.isDownloading = false,
    this.downloadProgress = 0.0,
  }) : sharedAt = sharedAt ?? DateTime.now();

  bool get isImage => mimeType.startsWith('image/');
  bool get isPdf => mimeType == 'application/pdf';
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'mimeType': mimeType,
    'size': size,
    'sharedAt': sharedAt.toIso8601String(),
  };

  factory SharedFile.fromJson(Map<String, dynamic> json) => SharedFile(
    id: json['id'],
    name: json['name'],
    mimeType: json['mimeType'],
    size: json['size'],
    sharedAt: DateTime.parse(json['sharedAt']),
  );
}

/// Service for sharing files between speaker and listeners
class FileSharingService extends ChangeNotifier {
  HttpServer? _fileServer;
  final List<SharedFile> _sharedFiles = [];
  final List<SharedFile> _receivedFiles = [];
  
  // Callbacks for listener notifications
  final _fileAnnouncedController = StreamController<SharedFile>.broadcast();
  Stream<SharedFile> get onFileAnnounced => _fileAnnouncedController.stream;
  
  List<SharedFile> get sharedFiles => List.unmodifiable(_sharedFiles);
  List<SharedFile> get receivedFiles => List.unmodifiable(_receivedFiles);
  
  int _fileIdCounter = 0;
  
  /// Start the file server (speaker side)
  Future<bool> startServer({int port = 8081}) async {
    try {
      final router = Router();
      
      // List all files
      router.get('/files', (Request request) async {
        final fileList = _sharedFiles.map((f) => f.toJson()).toList();
        return Response.ok(
          jsonEncode({'files': fileList}),
          headers: {'Content-Type': 'application/json'},
        );
      });
      
      // Download a specific file
      router.get('/files/<id>', (Request request, String id) async {
        final file = _sharedFiles.where((f) => f.id == id).firstOrNull;
        if (file == null) {
          return Response.notFound('File not found');
        }
        
        Uint8List data;
        if (file.data != null) {
          data = file.data!;
        } else if (file.localPath != null) {
          data = await File(file.localPath!).readAsBytes();
        } else {
          return Response.internalServerError(body: 'File data not available');
        }
        
        return Response.ok(
          data,
          headers: {
            'Content-Type': file.mimeType,
            'Content-Disposition': 'attachment; filename="${file.name}"',
            'Content-Length': data.length.toString(),
          },
        );
      });
      
      // Get file metadata
      router.get('/files/<id>/info', (Request request, String id) async {
        final file = _sharedFiles.where((f) => f.id == id).firstOrNull;
        if (file == null) {
          return Response.notFound('File not found');
        }
        return Response.ok(
          jsonEncode(file.toJson()),
          headers: {'Content-Type': 'application/json'},
        );
      });
      
      final handler = const Pipeline()
          .addMiddleware(logRequests())
          .addMiddleware(_corsMiddleware())
          .addHandler(router.call);
      
      _fileServer = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
      print('File sharing server started on port $port');
      return true;
    } catch (e) {
      print('Failed to start file server: $e');
      return false;
    }
  }
  
  Middleware _corsMiddleware() {
    return (Handler handler) {
      return (Request request) async {
        if (request.method == 'OPTIONS') {
          return Response.ok('', headers: _corsHeaders);
        }
        final response = await handler(request);
        return response.change(headers: _corsHeaders);
      };
    };
  }
  
  Map<String, String> get _corsHeaders => {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': '*',
  };
  
  /// Stop the file server
  Future<void> stopServer() async {
    await _fileServer?.close(force: true);
    _fileServer = null;
    _sharedFiles.clear();
    notifyListeners();
    print('File sharing server stopped');
  }
  
  /// Add a file to share (speaker side)
  Future<SharedFile?> shareFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        print('File does not exist: $filePath');
        return null;
      }
      
      final bytes = await file.readAsBytes();
      final fileName = file.path.split(Platform.pathSeparator).last;
      final mimeType = lookupMimeType(fileName) ?? 'application/octet-stream';
      
      final sharedFile = SharedFile(
        id: '${_fileIdCounter++}',
        name: fileName,
        mimeType: mimeType,
        size: bytes.length,
        localPath: filePath,
        data: bytes,
      );
      
      _sharedFiles.add(sharedFile);
      notifyListeners();
      
      print('File shared: ${sharedFile.name} (${sharedFile.size} bytes)');
      return sharedFile;
    } catch (e) {
      print('Failed to share file: $e');
      return null;
    }
  }
  
  /// Share file from bytes (for picked files)
  Future<SharedFile?> shareFileFromBytes(String fileName, Uint8List bytes) async {
    try {
      final mimeType = lookupMimeType(fileName) ?? 'application/octet-stream';
      
      final sharedFile = SharedFile(
        id: '${_fileIdCounter++}',
        name: fileName,
        mimeType: mimeType,
        size: bytes.length,
        data: bytes,
      );
      
      _sharedFiles.add(sharedFile);
      notifyListeners();
      
      print('File shared from bytes: ${sharedFile.name} (${sharedFile.size} bytes)');
      return sharedFile;
    } catch (e) {
      print('Failed to share file: $e');
      return null;
    }
  }
  
  /// Remove a shared file
  void removeSharedFile(String fileId) {
    _sharedFiles.removeWhere((f) => f.id == fileId);
    notifyListeners();
  }
  
  /// Fetch available files from speaker (listener side)
  Future<List<SharedFile>> fetchAvailableFiles(String speakerIp, {int port = 8081}) async {
    try {
      final response = await http.get(
        Uri.parse('http://$speakerIp:$port/files'),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final files = (data['files'] as List)
            .map((f) => SharedFile.fromJson(f))
            .toList();
        return files;
      }
    } catch (e) {
      print('Failed to fetch files: $e');
    }
    return [];
  }
  
  /// Download a file from speaker (listener side)
  Future<SharedFile?> downloadFile(
    String speakerIp,
    SharedFile fileInfo, {
    int port = 8081,
    Function(double)? onProgress,
  }) async {
    try {
      // Mark as downloading
      final index = _receivedFiles.indexWhere((f) => f.id == fileInfo.id);
      if (index >= 0) {
        _receivedFiles[index].isDownloading = true;
        notifyListeners();
      } else {
        final newFile = SharedFile(
          id: fileInfo.id,
          name: fileInfo.name,
          mimeType: fileInfo.mimeType,
          size: fileInfo.size,
          isDownloading: true,
        );
        _receivedFiles.add(newFile);
        notifyListeners();
      }
      
      final response = await http.get(
        Uri.parse('http://$speakerIp:$port/files/${fileInfo.id}'),
      ).timeout(const Duration(minutes: 5));
      
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        
        // Save to local storage
        final dir = await getApplicationDocumentsDirectory();
        final localPath = '${dir.path}/wifiport_files/${fileInfo.name}';
        final localFile = File(localPath);
        await localFile.parent.create(recursive: true);
        await localFile.writeAsBytes(bytes);
        
        final downloadedFile = SharedFile(
          id: fileInfo.id,
          name: fileInfo.name,
          mimeType: fileInfo.mimeType,
          size: bytes.length,
          localPath: localPath,
          data: bytes,
          isDownloading: false,
          downloadProgress: 1.0,
        );
        
        // Update received files
        final idx = _receivedFiles.indexWhere((f) => f.id == fileInfo.id);
        if (idx >= 0) {
          _receivedFiles[idx] = downloadedFile;
        } else {
          _receivedFiles.add(downloadedFile);
        }
        notifyListeners();
        
        print('File downloaded: ${downloadedFile.name}');
        return downloadedFile;
      }
    } catch (e) {
      print('Failed to download file: $e');
      // Mark as not downloading
      final idx = _receivedFiles.indexWhere((f) => f.id == fileInfo.id);
      if (idx >= 0) {
        _receivedFiles[idx].isDownloading = false;
        notifyListeners();
      }
    }
    return null;
  }
  
  /// Clear received files
  void clearReceivedFiles() {
    _receivedFiles.clear();
    notifyListeners();
  }
  
  @override
  void dispose() {
    stopServer();
    _fileAnnouncedController.close();
    super.dispose();
  }
}
