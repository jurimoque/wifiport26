import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:network_info_plus/network_info_plus.dart';

/// Service for discovering devices and getting network information
class DiscoveryService {
  final NetworkInfo _networkInfo = NetworkInfo();
  
  String? _localIp;
  String? get localIp => _localIp;

  /// Get the device's local IP address
  Future<String?> getLocalIpAddress() async {
    try {
      // Try to get WiFi IP first
      _localIp = await _networkInfo.getWifiIP();
      
      if (_localIp == null || _localIp == '0.0.0.0') {
        // Fallback: iterate through network interfaces
        final interfaces = await NetworkInterface.list(
          type: InternetAddressType.IPv4,
          includeLinkLocal: false,
        );
        
        for (var interface in interfaces) {
          if (interface.name.toLowerCase().contains('wlan') ||
              interface.name.toLowerCase().contains('wifi') ||
              interface.name.toLowerCase().contains('en0') ||
              interface.name.toLowerCase().contains('eth')) {
            for (var addr in interface.addresses) {
              if (!addr.isLoopback) {
                _localIp = addr.address;
                break;
              }
            }
          }
          if (_localIp != null) break;
        }
        
        // Last resort: get any non-loopback IPv4
        if (_localIp == null) {
          for (var interface in interfaces) {
            for (var addr in interface.addresses) {
              if (!addr.isLoopback) {
                _localIp = addr.address;
                break;
              }
            }
            if (_localIp != null) break;
          }
        }
      }
      
      print('Local IP address: $_localIp');
      return _localIp;
    } catch (e) {
      print('Error getting local IP: $e');
      return null;
    }
  }

  /// Get network name (SSID)
  Future<String?> getNetworkName() async {
    try {
      return await _networkInfo.getWifiName();
    } catch (e) {
      print('Error getting network name: $e');
      return null;
    }
  }

  /// Generate a random 6-digit PIN for connection
  String generateSessionPin() {
    final random = Random.secure();
    final pin = random.nextInt(900000) + 100000; // 100000-999999
    return pin.toString();
  }

  /// Generate connection data for QR code
  /// Format: wifiport://IP:PORT/PIN
  String generateConnectionUri(String ip, int port, String pin) {
    return 'wifiport://$ip:$port/$pin';
  }

  /// Parse connection URI from QR code
  ConnectionInfo? parseConnectionUri(String uri) {
    try {
      // Support both full URI and simple formats
      String cleanUri = uri.trim();
      
      // Format: wifiport://IP:PORT/PIN
      if (cleanUri.startsWith('wifiport://')) {
        cleanUri = cleanUri.substring(11);
        final parts = cleanUri.split('/');
        if (parts.length >= 2) {
          final hostPort = parts[0].split(':');
          if (hostPort.length >= 2) {
            return ConnectionInfo(
              ip: hostPort[0],
              port: int.parse(hostPort[1]),
              pin: parts[1],
            );
          }
        }
      }
      
      // Format: IP:PORT (PIN optional)
      if (cleanUri.contains(':')) {
        final parts = cleanUri.split(':');
        return ConnectionInfo(
          ip: parts[0],
          port: int.parse(parts[1]),
          pin: '',
        );
      }
      
      return null;
    } catch (e) {
      print('Error parsing connection URI: $e');
      return null;
    }
  }

  /// Check if we have network connectivity
  Future<bool> hasNetworkConnectivity() async {
    try {
      final ip = await getLocalIpAddress();
      return ip != null && ip != '0.0.0.0';
    } catch (e) {
      return false;
    }
  }
}

class ConnectionInfo {
  final String ip;
  final int port;
  final String pin;

  ConnectionInfo({
    required this.ip,
    required this.port,
    required this.pin,
  });

  @override
  String toString() => '$ip:$port (PIN: $pin)';
}
