# WiFiPort

**Real-time audio streaming over local network**

WiFiPort is a cross-platform mobile application that enables real-time audio transmission between devices on the same local network (WiFi or hotspot) without requiring external servers or internet connectivity.

## 🎯 Features

### MVP Features
- **Speaker Mode (Android only)**: Broadcast audio from microphone to connected listeners
- **Listener Mode (iOS & Android)**: Receive and play audio from a speaker
- **QR Code Connection**: Quick connection via QR code scanning
- **PIN Connection**: Manual connection using 6-digit PIN
- **Real-time Streaming**: Low-latency audio using WebRTC with Opus codec
- **Connection Status**: Visual indicators for connection quality
- **Dark Mode**: Full support for light and dark themes

### Platform Limitations
- **iOS devices**: Can only act as **Listeners**
- **Android devices**: Can act as both **Speakers** and **Listeners**
- Hotspot creation must be done manually through system settings

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Speaker Device (Android)                  │
├─────────────────────────────────────────────────────────────┤
│ Microphone → Audio Processing → Opus Encoder → WebRTC Peer  │
│                                                              │
│ Signaling Server (WebSocket) ← QR/PIN Generator             │
└─────────────────────────────────────────────────────────────┘
                              │
                    Local WiFi Network
                              │
┌─────────────────────────────────────────────────────────────┐
│                 Listener Device (iOS/Android)                │
├─────────────────────────────────────────────────────────────┤
│ QR Scanner/PIN Input → Signaling Client → WebRTC Peer       │
│                                                              │
│              Opus Decoder → Audio Playback → Speaker         │
└─────────────────────────────────────────────────────────────┘
```

### Technology Stack
| Component | Technology |
|-----------|------------|
| Framework | Flutter 3.x |
| Audio Streaming | WebRTC + Opus |
| Signaling | WebSocket (local) |
| QR Code | qr_flutter + mobile_scanner |
| Security | DTLS-SRTP (WebRTC built-in) |

## 📦 Project Structure

```
wifiport/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── core/
│   │   └── theme/                   # Colors, typography, theme
│   ├── services/
│   │   ├── audio/                   # Audio capture/playback
│   │   ├── network/                 # Signaling, WebRTC, discovery
│   │   └── session/                 # Session management
│   ├── features/
│   │   ├── home/                    # Home screen
│   │   ├── speaker/                 # Speaker mode UI
│   │   └── listener/                # Listener mode UI
│   └── widgets/                     # Reusable widgets
├── assets/
│   └── images/                      # Logo and icons
├── android/                         # Android configuration
└── ios/                             # iOS configuration
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.8.1 or later
- Android Studio or Xcode
- Physical devices for testing (emulators may not work for local network discovery)

### Installation

1. **Clone the repository**
   ```bash
   cd "c:\DEVELOPER\WIFIPORT ANTIGRAVITY\wifiport"
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run on Android**
   ```bash
   flutter run -d android
   ```

4. **Run on iOS** (macOS required)
   ```bash
   cd ios && pod install && cd ..
   flutter run -d ios
   ```

### Building for Release

**Android APK**
```bash
flutter build apk --release
```
APK location: `build/app/outputs/flutter-apk/app-release.apk`

**Android App Bundle (Play Store)**
```bash
flutter build appbundle --release
```

**iOS (macOS required)**
```bash
flutter build ios --release
```

## 📱 Usage

### As a Speaker (Android)
1. Open WiFiPort
2. Tap "Emitir Audio"
3. Grant microphone permission when prompted
4. Share the QR code or PIN with listeners
5. Speak into the microphone - listeners will hear you in real-time
6. Tap "Detener" to end the session

### As a Listener (iOS/Android)
1. Open WiFiPort
2. Tap "Escuchar Audio"
3. Either:
   - Scan the speaker's QR code, OR
   - Enter the speaker's IP:PORT manually
4. Audio will start playing automatically
5. Tap "Desconectar" to leave the session

### Network Setup
- Both devices must be on the **same WiFi network**
- Alternatively, the Android (speaker) device can create a **mobile hotspot** and listeners can connect to it

## 🎨 Branding

### Colors
| Name | Hex | Usage |
|------|-----|-------|
| Primary Dark | `#004A54` | Verde petróleo - Main brand color |
| Primary | `#33C4B4` | Verde agua - Accent color |
| White | `#FFFFFF` | Backgrounds, text |
| Black | `#000000` | Text, icons |

### Typography
- **Headings**: Montserrat (600, 700)
- **Body**: Open Sans (400, 600)

## ⚙️ Technical Details

### Audio Configuration
- **Codec**: Opus
- **Sample Rate**: 48 kHz
- **Channels**: Mono
- **Bitrate**: 32-64 kbps (adaptive)
- **Target Latency**: <150ms

### Audio Processing
- Echo cancellation: Enabled
- Noise suppression: Enabled
- Auto gain control: Enabled

### Security
- All WebRTC audio streams are encrypted using DTLS-SRTP
- No data is stored or transmitted to external servers
- All communication happens within the local network

## 🔮 Future Features (Post-MVP)

- [ ] **Push-to-Talk**: Allow listeners to momentarily speak
- [ ] **Multiple Channels**: Support for 4+ simultaneous audio channels (e.g., languages)
- [ ] **Web Dashboard**: Control panel for speakers
- [ ] **System Audio**: Broadcast music/system audio, not just microphone
- [ ] **End-to-end Encryption**: Additional encryption layer

## 🐛 Troubleshooting

### "Cannot find speaker"
- Ensure both devices are on the same WiFi network
- Check that the speaker's firewall isn't blocking port 8080
- Try entering the IP address manually

### "No audio"
- Check microphone permissions on the speaker device
- Ensure the speaker is not muted
- Verify volume on the listener device

### "High latency"
- Move closer to the WiFi router
- Reduce network congestion
- Try using a 5GHz WiFi network instead of 2.4GHz

## 📄 Dependencies

```yaml
dependencies:
  flutter_webrtc: ^0.12.6       # WebRTC for audio streaming
  web_socket_channel: ^3.0.2    # Local signaling
  qr_flutter: ^4.1.0            # QR code generation
  mobile_scanner: ^7.0.0        # QR code scanning
  permission_handler: ^11.3.1   # Runtime permissions
  google_fonts: ^6.2.1          # Typography
  provider: ^6.1.2              # State management
  network_info_plus: ^6.1.3     # Network utilities
  wakelock_plus: ^1.2.10        # Keep screen awake
  device_info_plus: ^11.2.1     # Platform detection
```

## 📜 License

This project is proprietary software developed for ASTI / 3AV.events.

## 👥 Credits

- Developed by the WiFiPort Team
- Icons and branding by ASTI
