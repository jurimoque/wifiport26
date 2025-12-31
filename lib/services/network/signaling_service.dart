import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Signaling service for local WebRTC connection establishment
/// Handles SDP offer/answer and ICE candidate exchange
class SignalingService {
  HttpServer? _server;
  final List<WebSocket> _clients = [];
  WebSocket? _speakerConnection;
  
  final _messageController = StreamController<SignalingMessage>.broadcast();
  Stream<SignalingMessage> get onMessage => _messageController.stream;
  
  final _clientCountController = StreamController<int>.broadcast();
  Stream<int> get onClientCountChanged => _clientCountController.stream;
  
  int get clientCount => _clients.length;
  bool get isServerRunning => _server != null;

  /// Start signaling server (Speaker mode)
  Future<int> startServer({int port = 8080}) async {
    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
      print('Signaling server started on port $port');
      
      _server!.listen((HttpRequest request) async {
        if (WebSocketTransformer.isUpgradeRequest(request)) {
          final socket = await WebSocketTransformer.upgrade(request);
          _handleClientConnection(socket);
        } else {
          request.response
            ..statusCode = HttpStatus.ok
            ..write('WiFiPort Signaling Server')
            ..close();
        }
      });
      
      return port;
    } catch (e) {
      print('Failed to start signaling server: $e');
      rethrow;
    }
  }

  void _handleClientConnection(WebSocket socket) {
    _clients.add(socket);
    _clientCountController.add(_clients.length);
    print('Client connected. Total clients: ${_clients.length}');
    
    socket.listen(
      (data) {
        try {
          final message = SignalingMessage.fromJson(jsonDecode(data));
          _messageController.add(message);
          
          // Forward message to all other clients (or to speaker)
          if (message.type == MessageType.offer ||
              message.type == MessageType.answer ||
              message.type == MessageType.candidate) {
            _broadcastToOthers(socket, data);
          }
        } catch (e) {
          print('Error parsing message: $e');
        }
      },
      onDone: () {
        _clients.remove(socket);
        _clientCountController.add(_clients.length);
        print('Client disconnected. Total clients: ${_clients.length}');
      },
      onError: (error) {
        _clients.remove(socket);
        _clientCountController.add(_clients.length);
        print('Client error: $error');
      },
    );
  }

  void _broadcastToOthers(WebSocket sender, dynamic message) {
    for (final client in _clients) {
      if (client != sender && client.readyState == WebSocket.open) {
        client.add(message);
      }
    }
  }

  /// Connect to signaling server (Listener mode)
  Future<void> connectToServer(String host, int port) async {
    try {
      final uri = Uri.parse('ws://$host:$port');
      _speakerConnection = await WebSocket.connect(uri.toString());
      
      _speakerConnection!.listen(
        (data) {
          try {
            final message = SignalingMessage.fromJson(jsonDecode(data));
            _messageController.add(message);
          } catch (e) {
            print('Error parsing message: $e');
          }
        },
        onDone: () {
          print('Disconnected from speaker');
          _speakerConnection = null;
        },
        onError: (error) {
          print('Connection error: $error');
          _speakerConnection = null;
        },
      );
      
      print('Connected to signaling server at $host:$port');
    } catch (e) {
      print('Failed to connect to signaling server: $e');
      rethrow;
    }
  }

  /// Send a signaling message
  void sendMessage(SignalingMessage message) {
    final jsonStr = jsonEncode(message.toJson());
    
    if (_speakerConnection != null && 
        _speakerConnection!.readyState == WebSocket.open) {
      _speakerConnection!.add(jsonStr);
    } else {
      // Broadcast to all connected clients (speaker mode)
      for (final client in _clients) {
        if (client.readyState == WebSocket.open) {
          client.add(jsonStr);
        }
      }
    }
  }

  /// Stop server and disconnect all clients
  Future<void> stop() async {
    for (final client in _clients) {
      await client.close();
    }
    _clients.clear();
    
    await _speakerConnection?.close();
    _speakerConnection = null;
    
    await _server?.close();
    _server = null;
    
    _clientCountController.add(0);
    print('Signaling service stopped');
  }

  void dispose() {
    _messageController.close();
    _clientCountController.close();
    stop();
  }
}

enum MessageType {
  offer,
  answer,
  candidate,
  join,
  leave,
  ready,
}

class SignalingMessage {
  final MessageType type;
  final String? sdp;
  final Map<String, dynamic>? candidate;
  final String? senderId;

  SignalingMessage({
    required this.type,
    this.sdp,
    this.candidate,
    this.senderId,
  });

  factory SignalingMessage.fromJson(Map<String, dynamic> json) {
    return SignalingMessage(
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.ready,
      ),
      sdp: json['sdp'],
      candidate: json['candidate'],
      senderId: json['senderId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      if (sdp != null) 'sdp': sdp,
      if (candidate != null) 'candidate': candidate,
      if (senderId != null) 'senderId': senderId,
    };
  }
}
