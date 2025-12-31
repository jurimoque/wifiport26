import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../network/discovery_service.dart';
import '../network/signaling_service.dart';
import '../network/webrtc_service.dart';

enum SessionMode { none, speaker, listener }

enum SessionState {
  idle,
  initializing,
  ready,
  connecting,
  connected,
  streaming,
  error,
}

/// Manages the audio streaming session
class SessionManager extends ChangeNotifier {
  final DiscoveryService _discoveryService = DiscoveryService();
  late final SignalingService _signalingService;
  late final WebRTCService _webrtcService;
  
  SessionMode _mode = SessionMode.none;
  SessionState _state = SessionState.idle;
  String? _error;
  String? _localIp;
  String? _sessionPin;
  int _listenerCount = 0;
  bool _isMuted = false;
  MediaStream? _remoteStream;
  bool _canBeSpeaker = true;
  
  // Getters
  SessionMode get mode => _mode;
  SessionState get state => _state;
  String? get error => _error;
  String? get localIp => _localIp;
  String? get sessionPin => _sessionPin;
  int get listenerCount => _listenerCount;
  bool get isMuted => _isMuted;
  MediaStream? get remoteStream => _remoteStream;
  bool get canBeSpeaker => _canBeSpeaker;
  
  String? get connectionUri {
    if (_localIp != null && _sessionPin != null) {
      return _discoveryService.generateConnectionUri(_localIp!, 8080, _sessionPin!);
    }
    return null;
  }

  SessionManager() {
    _signalingService = SignalingService();
    _webrtcService = WebRTCService(_signalingService);
    _setupListeners();
    _checkPlatformCapabilities();
  }

  void _setupListeners() {
    _signalingService.onClientCountChanged.listen((count) {
      _listenerCount = count;
      notifyListeners();
    });
    
    _webrtcService.onRemoteStream.listen((stream) {
      _remoteStream = stream;
      _state = SessionState.streaming;
      notifyListeners();
    });
    
    _webrtcService.onConnectionState.listen((state) {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        _state = SessionState.connected;
      } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
                 state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        _state = SessionState.error;
        _error = 'Connection lost';
      }
      notifyListeners();
    });
  }

  Future<void> _checkPlatformCapabilities() async {
    // Check if device can be a speaker (Android only in MVP)
    if (!kIsWeb) {
      if (Platform.isIOS) {
        _canBeSpeaker = false;
      } else if (Platform.isAndroid) {
        _canBeSpeaker = true;
      }
    }
    notifyListeners();
  }

  /// Get device platform info
  Future<String> getPlatformInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    
    if (kIsWeb) {
      return 'Web';
    } else if (Platform.isAndroid) {
      final info = await deviceInfo.androidInfo;
      return 'Android ${info.version.release}';
    } else if (Platform.isIOS) {
      final info = await deviceInfo.iosInfo;
      return 'iOS ${info.systemVersion}';
    }
    
    return 'Unknown';
  }

  /// Start as speaker (broadcaster)
  Future<bool> startAsSpeaker() async {
    if (!_canBeSpeaker) {
      _error = 'This device cannot be a speaker. Only Android devices can broadcast.';
      _state = SessionState.error;
      notifyListeners();
      return false;
    }

    try {
      _mode = SessionMode.speaker;
      _state = SessionState.initializing;
      _error = null;
      notifyListeners();
      
      // Get local IP
      _localIp = await _discoveryService.getLocalIpAddress();
      if (_localIp == null) {
        throw Exception('Could not determine local IP address. Make sure you are connected to WiFi or have a hotspot active.');
      }
      
      // Generate session PIN
      _sessionPin = _discoveryService.generateSessionPin();
      
      // Start signaling server
      await _signalingService.startServer();
      
      // Initialize WebRTC as speaker
      await _webrtcService.initAsSpeaker();
      
      // Keep screen awake
      await WakelockPlus.enable();
      
      _state = SessionState.ready;
      notifyListeners();
      
      print('Speaker session started: $_localIp:8080 PIN: $_sessionPin');
      return true;
    } catch (e) {
      _error = e.toString();
      _state = SessionState.error;
      notifyListeners();
      return false;
    }
  }

  /// Connect as listener
  Future<bool> connectAsListener(String connectionData) async {
    try {
      _mode = SessionMode.listener;
      _state = SessionState.connecting;
      _error = null;
      notifyListeners();
      
      // Parse connection info
      final info = _discoveryService.parseConnectionUri(connectionData);
      if (info == null) {
        throw Exception('Invalid connection data. Please try again.');
      }
      
      // Connect to signaling server
      await _signalingService.connectToServer(info.ip, info.port);
      
      // Initialize WebRTC as listener
      await _webrtcService.initAsListener();
      
      // Keep screen awake
      await WakelockPlus.enable();
      
      _state = SessionState.connected;
      notifyListeners();
      
      print('Connected to speaker at ${info.ip}:${info.port}');
      return true;
    } catch (e) {
      _error = e.toString();
      _state = SessionState.error;
      notifyListeners();
      return false;
    }
  }

  /// Toggle microphone mute (speaker only)
  void toggleMute() {
    if (_mode != SessionMode.speaker) return;
    
    _isMuted = !_isMuted;
    _webrtcService.setMicrophoneMuted(_isMuted);
    notifyListeners();
  }

  /// Stop current session
  Future<void> stopSession() async {
    await _webrtcService.dispose();
    await _signalingService.stop();
    await WakelockPlus.disable();
    
    _mode = SessionMode.none;
    _state = SessionState.idle;
    _error = null;
    _localIp = null;
    _sessionPin = null;
    _listenerCount = 0;
    _isMuted = false;
    _remoteStream = null;
    
    notifyListeners();
    print('Session stopped');
  }

  @override
  void dispose() {
    stopSession();
    super.dispose();
  }
}
