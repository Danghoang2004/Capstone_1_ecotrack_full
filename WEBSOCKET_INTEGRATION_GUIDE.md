# Real-Time WebSocket Integration Guide

## Backend Implementation ✅ DONE

### 1. Dependencies Added
- `spring-boot-starter-websocket`
- `spring-messaging`

### 2. Configuration
- **File**: `WebSocketConfig.java`
- **Endpoint**: `/ws/notifications`
- **Features**: STOMP broker, SockJS support, message prefixes

### 3. Services
- **NotificationBroadcastService**: Sends real-time notifications to users
- **Updated NotificationService**: Broadcasts when creating notifications

### 4. Controllers
- **WebSocketNotificationController**: Handles STOMP subscriptions

---

## Flutter Implementation Guide

### 1. Add Dependencies to pubspec.yaml

```yaml
dependencies:
  web_socket_channel: ^2.4.0
  stomp_dart_client: ^1.2.6  # Recommended for STOMP protocol
  # OR
  socket_io_client: ^2.0.0
```

### 2. Create WebSocket Service

```dart
// lib/services/websocket_service.dart
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'dart:async';

class WebSocketService {
  late StompClient _stompClient;
  final StreamController<NotificationResponse> _notificationStream =
      StreamController<NotificationResponse>.broadcast();
  
  Stream<NotificationResponse> get notificationStream => _notificationStream.stream;

  void connect(String userId, String jwtToken) {
    _stompClient = StompClient(
      config: StompConfig(
        url: 'ws://localhost:8080/ws/notifications',
        onConnect: _onConnect,
        onStompError: _onStompError,
        onWebSocketError: (dynamic error) => print('Websocket error: $error'),
      ),
    );
    _stompClient.activate();
  }

  void _onConnect(StompFrame connectFrame) {
    print('Connected to WebSocket');
    
    // Subscribe to user notifications
    _stompClient.subscribe(
      destination: '/user/123/notifications', // Replace 123 with userId
      callback: (frame) {
        final notification = NotificationResponse.fromJson(frame.body);
        _notificationStream.add(notification);
      },
    );
  }

  void _onStompError(StompFrame frame) {
    print('STOMP Error: ${frame.body}');
  }

  void disconnect() {
    _stompClient.deactivate();
  }
}
```

### 3. Use in UI

```dart
// Example: Listen to notifications
StreamBuilder<NotificationResponse>(
  stream: webSocketService.notificationStream,
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      final notification = snapshot.data!;
      return NotificationCard(notification: notification);
    }
    return SizedBox.shrink();
  },
)
```

### 4. Handle Reconnection

```dart
Future<void> _startNotificationListener() async {
  try {
    await webSocketService.connect(userId, jwtToken);
  } catch (e) {
    print('Connection failed: $e');
    // Retry after 5 seconds
    Future.delayed(Duration(seconds: 5), _startNotificationListener);
  }
}
```

---

## API Endpoints (Still Available via REST)

```
GET  /api/notifications              - Get all notifications
GET  /api/notifications/unread       - Get unread only
POST /api/notifications/{id}/read    - Mark as read
```

---

## Testing WebSocket Locally

### Using WebSocket Testing Tool:
```
ws://localhost:8080/ws/notifications
```

### STOMP Commands:
```
CONNECT
/

SUBSCRIBE
destination:/user/1/notifications
id:1

```

---

## Next Steps:
1. ✅ Backend WebSocket configured
2. 📝 Implement Flutter WebSocket service
3. 📝 Update UI to listen to real-time notifications
4. 📝 Add reconnection logic
5. 📝 Test with multiple users
