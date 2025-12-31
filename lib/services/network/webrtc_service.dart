import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart' hide MessageType;
import 'signaling_service.dart';

/// WebRTC service for real-time audio streaming
class WebRTCService {
  final SignalingService _signalingService;
  
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  
  final _remoteStreamController = StreamController<MediaStream>.broadcast();
  Stream<MediaStream> get onRemoteStream => _remoteStreamController.stream;
  
  final _connectionStateController = StreamController<RTCPeerConnectionState>.broadcast();
  Stream<RTCPeerConnectionState> get onConnectionState => _connectionStateController.stream;
  
  bool get isConnected => _peerConnection?.connectionState == RTCPeerConnectionState.RTCPeerConnectionStateConnected;
  
  // WebRTC configuration for local network only (no STUN/TURN needed)
  static final Map<String, dynamic> _configuration = {
    'iceServers': [], // No ICE servers needed for local network
    'sdpSemantics': 'unified-plan',
  };
  
  // Audio constraints optimized for low latency
  static final Map<String, dynamic> _audioConstraints = {
    'audio': {
      'echoCancellation': true,
      'noiseSuppression': true,
      'autoGainControl': true,
      'googEchoCancellation': true,
      'googAutoGainControl': true,
      'googNoiseSuppression': true,
      'googHighpassFilter': true,
      'channelCount': 1, // Mono for lower bandwidth
      'sampleRate': 48000,
    },
    'video': false,
  };

  WebRTCService(this._signalingService) {
    _setupSignalingListeners();
  }

  void _setupSignalingListeners() {
    _signalingService.onMessage.listen((message) async {
      switch (message.type) {
        case MessageType.offer:
          await _handleOffer(message);
          break;
        case MessageType.answer:
          await _handleAnswer(message);
          break;
        case MessageType.candidate:
          await _handleCandidate(message);
          break;
        case MessageType.join:
          // New listener joined, create offer for them
          if (_localStream != null) {
            await _createOffer();
          }
          break;
        default:
          break;
      }
    });
  }

  /// Initialize as speaker (broadcaster)
  Future<void> initAsSpeaker() async {
    await _createPeerConnection();
    
    // Get local audio stream
    _localStream = await navigator.mediaDevices.getUserMedia(_audioConstraints);
    
    // Add audio tracks to peer connection
    for (final track in _localStream!.getAudioTracks()) {
      await _peerConnection!.addTrack(track, _localStream!);
    }
    
    print('Speaker initialized with local audio stream');
  }

  /// Initialize as listener (receiver)
  Future<void> initAsListener() async {
    await _createPeerConnection();
    
    // Signal that we're ready to receive
    _signalingService.sendMessage(SignalingMessage(type: MessageType.join));
    
    print('Listener initialized, waiting for audio stream');
  }

  Future<void> _createPeerConnection() async {
    _peerConnection = await createPeerConnection(_configuration);
    
    _peerConnection!.onIceCandidate = (candidate) {
      if (candidate.candidate != null) {
        _signalingService.sendMessage(SignalingMessage(
          type: MessageType.candidate,
          candidate: candidate.toMap(),
        ));
      }
    };
    
    _peerConnection!.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        _remoteStreamController.add(event.streams[0]);
        print('Received remote stream');
      }
    };
    
    _peerConnection!.onConnectionState = (state) {
      _connectionStateController.add(state);
      print('Connection state: $state');
    };
    
    _peerConnection!.onIceConnectionState = (state) {
      print('ICE connection state: $state');
    };
  }

  Future<void> _createOffer() async {
    if (_peerConnection == null) return;
    
    try {
      final offer = await _peerConnection!.createOffer({
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': false,
      });
      
      // Modify SDP for Opus optimization
      offer.sdp = _optimizeSdpForOpus(offer.sdp!);
      
      await _peerConnection!.setLocalDescription(offer);
      
      _signalingService.sendMessage(SignalingMessage(
        type: MessageType.offer,
        sdp: offer.sdp,
      ));
      
      print('Offer created and sent');
    } catch (e) {
      print('Error creating offer: $e');
    }
  }

  Future<void> _handleOffer(SignalingMessage message) async {
    if (_peerConnection == null || message.sdp == null) return;
    
    try {
      await _peerConnection!.setRemoteDescription(
        RTCSessionDescription(message.sdp!, 'offer'),
      );
      
      final answer = await _peerConnection!.createAnswer();
      
      // Modify SDP for Opus optimization
      answer.sdp = _optimizeSdpForOpus(answer.sdp!);
      
      await _peerConnection!.setLocalDescription(answer);
      
      _signalingService.sendMessage(SignalingMessage(
        type: MessageType.answer,
        sdp: answer.sdp,
      ));
      
      print('Answer created and sent');
    } catch (e) {
      print('Error handling offer: $e');
    }
  }

  Future<void> _handleAnswer(SignalingMessage message) async {
    if (_peerConnection == null || message.sdp == null) return;
    
    try {
      await _peerConnection!.setRemoteDescription(
        RTCSessionDescription(message.sdp!, 'answer'),
      );
      print('Answer received and set');
    } catch (e) {
      print('Error handling answer: $e');
    }
  }

  Future<void> _handleCandidate(SignalingMessage message) async {
    if (_peerConnection == null || message.candidate == null) return;
    
    try {
      final candidate = RTCIceCandidate(
        message.candidate!['candidate'],
        message.candidate!['sdpMid'],
        message.candidate!['sdpMLineIndex'],
      );
      await _peerConnection!.addCandidate(candidate);
      print('ICE candidate added');
    } catch (e) {
      print('Error adding ICE candidate: $e');
    }
  }

  /// Optimize SDP for Opus codec with low latency settings
  String _optimizeSdpForOpus(String sdp) {
    // Set Opus as preferred codec with specific parameters
    // stereo=0 (mono), cbr=0 (VBR), useinbandfec=1 (error correction)
    // maxaveragebitrate=64000 (64 kbps), maxplaybackrate=48000
    
    final lines = sdp.split('\n');
    final modifiedLines = <String>[];
    
    for (var line in lines) {
      if (line.startsWith('a=fmtp:111')) {
        // Opus is typically payload type 111
        line = 'a=fmtp:111 minptime=10;useinbandfec=1;stereo=0;'
               'maxaveragebitrate=64000;maxplaybackrate=48000';
      }
      modifiedLines.add(line);
    }
    
    return modifiedLines.join('\n');
  }

  /// Mute/unmute local audio
  void setMicrophoneMuted(bool muted) {
    if (_localStream != null) {
      for (final track in _localStream!.getAudioTracks()) {
        track.enabled = !muted;
      }
    }
  }

  /// Get audio level (for visualization)
  Future<double> getAudioLevel() async {
    // This would require platform-specific implementation
    // For now, return a placeholder
    return 0.0;
  }

  /// Stop and cleanup
  Future<void> dispose() async {
    await _localStream?.dispose();
    await _peerConnection?.close();
    
    _remoteStreamController.close();
    _connectionStateController.close();
    
    _localStream = null;
    _peerConnection = null;
    
    print('WebRTC service disposed');
  }
}
