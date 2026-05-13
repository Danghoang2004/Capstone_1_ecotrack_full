import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'dart:async';

class NotificationMessage {
  final String id;
  final String title;
  final String message;
  final String notificationType;
  final bool read;
  final DateTime createdAt;

  NotificationMessage({
    required this.id,
    required this.title,
    required this.message,
    required this.notificationType,
    required this.read,
    required this.createdAt,
  });

  factory NotificationMessage.fromJson(Map<String, dynamic> json) {
    return NotificationMessage(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      notificationType: json['notificationType'] ?? 'SYSTEM',
      read: json['read'] ?? false,
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}

class RealtimeNotificationService {
  late StompClient _stompClient;
  final String _baseUrl;
  final String _token;

  final StreamController<NotificationMessage> _notificationController =
      StreamController<NotificationMessage>.broadcast();

  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  Stream<NotificationMessage> get notifications =>
      _notificationController.stream;
  Stream<bool> get connectionStatus => _connectionController.stream;

  bool get isConnected => _stompClient.isConnected;

  RealtimeNotificationService({required String baseUrl, required String token})
    : _baseUrl = baseUrl,
      _token = token;

  Future<void> connect(String userId) async {
    _stompClient = StompClient(
      config: StompConfig(
        url: '${_baseUrl.replaceFirst('http', 'ws')}/ws/notifications',
        onConnect: (frame) => _onConnect(frame, userId),
        onStompError: _onStompError,
        onWebSocketError: (error) => _onWebSocketError(error),
        onDisconnect: _onDisconnect,
        heartbeatOutgoing: 20000,
        heartbeatIncoming: 20000,
      ),
    );

    _stompClient.activate();
  }

  void _onConnect(StompFrame frame, String userId) {
    print('✅ WebSocket Connected');
    _connectionController.add(true);

    _stompClient.subscribe(
      destination: '/user/$userId/notifications',
      callback: (frame) {
        try {
          if (frame.body != null) {
            final json = _parseJson(frame.body!);
            final notification = NotificationMessage.fromJson(json);
            _notificationController.add(notification);
            print('📬 New notification: ${notification.title}');
          }
        } catch (e) {
          print('❌ Error parsing notification: $e');
        }
      },
    );
  }

  void _onStompError(StompFrame frame) {
    print('❌ STOMP Error: ${frame.body}');
    _connectionController.add(false);
  }

  void _onWebSocketError(dynamic error) {
    print('❌ WebSocket Error: $error');
    _connectionController.add(false);
  }

  void _onDisconnect(StompFrame frame) {
    print('❌ Disconnected');
    _connectionController.add(false);
  }

  void disconnect() {
    if (_stompClient.isConnected) {
      _stompClient.deactivate();
    }
  }

  void sendPing() {
    if (_stompClient.isConnected) {
      _stompClient.send(destination: '/app/notifications/ping', body: '{}');
    }
  }

  Map<String, dynamic> _parseJson(String body) {
    return jsonDecode(body);
  }

  void dispose() {
    disconnect();
    _notificationController.close();
    _connectionController.close();
  }
}
