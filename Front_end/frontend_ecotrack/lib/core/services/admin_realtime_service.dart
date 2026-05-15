import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend_ecotrack/core/services/api_client.dart';
import 'package:http/http.dart' as http;

class AdminRealtimeEvent {
  final String eventType;
  final int? reportId;
  final int? campaignId;
  final int? participants;
  final int? maxParticipants;
  final String? status;

  const AdminRealtimeEvent({
    required this.eventType,
    this.reportId,
    this.campaignId,
    this.participants,
    this.maxParticipants,
    this.status,
  });

  factory AdminRealtimeEvent.fromMap(Map<String, dynamic> map) {
    return AdminRealtimeEvent(
      eventType: (map['eventType'] ?? '').toString(),
      reportId: map['reportId'] is int
          ? map['reportId'] as int
          : int.tryParse(map['reportId']?.toString() ?? ''),
      campaignId: map['campaignId'] is int
          ? map['campaignId'] as int
          : int.tryParse(map['campaignId']?.toString() ?? ''),
      participants: map['participants'] is int
          ? map['participants'] as int
          : int.tryParse(map['participants']?.toString() ?? ''),
      maxParticipants: map['maxParticipants'] is int
          ? map['maxParticipants'] as int
          : int.tryParse(map['maxParticipants']?.toString() ?? ''),
      status: map['status']?.toString(),
    );
  }

  bool get isReportEvent =>
      eventType == 'REPORT_CREATED' || eventType == 'REPORT_STATUS_UPDATED';

  bool get isCampaignEvent =>
      eventType == 'CAMPAIGN_PARTICIPANT_UPDATED' ||
      eventType == 'CAMPAIGN_UPDATED';
}

class AdminRealtimeService {
  AdminRealtimeService._();

  static final AdminRealtimeService instance = AdminRealtimeService._();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  late final ApiClient _apiClient = ApiClient(storage: _storage);
  final StreamController<AdminRealtimeEvent> _eventController =
      StreamController<AdminRealtimeEvent>.broadcast();

  Stream<AdminRealtimeEvent> get events => _eventController.stream;

  http.Client? _client;
  StreamSubscription<String>? _lineSubscription;
  Timer? _reconnectTimer;
  bool _isRunning = false;
  int _retryAttempt = 0;

  Future<void> start() async {
    if (_isRunning) return;
    _isRunning = true;
    await _connect();
  }

  void stop() {
    _isRunning = false;
    _reconnectTimer?.cancel();
    _lineSubscription?.cancel();
    _lineSubscription = null;
    _client?.close();
    _client = null;
  }

  Future<void> _connect() async {
    if (!_isRunning) return;

    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null || token.isEmpty) {
        _scheduleReconnect();
        return;
      }

      final uri = Uri.parse('${_apiClient.baseUrl}/api/admin/realtime/stream');
      final request = http.Request('GET', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..headers['Accept'] = 'text/event-stream'
        ..headers['Cache-Control'] = 'no-cache';

      _client?.close();
      _client = http.Client();

      final response = await _client!.send(request);
      if (response.statusCode != 200) {
        _scheduleReconnect();
        return;
      }

      _retryAttempt = 0;
      _listenSseLines(response);
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _listenSseLines(http.StreamedResponse response) {
    String? eventName;
    final List<String> dataLines = [];

    _lineSubscription?.cancel();
    _lineSubscription = response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
          (line) {
            if (line.startsWith('event:')) {
              eventName = line.substring(6).trim();
              return;
            }

            if (line.startsWith('data:')) {
              dataLines.add(line.substring(5).trimLeft());
              return;
            }

            if (line.isEmpty) {
              _flushEvent(eventName: eventName, dataLines: dataLines);
              eventName = null;
              dataLines.clear();
            }
          },
          onDone: _scheduleReconnect,
          onError: (_) => _scheduleReconnect(),
          cancelOnError: true,
        );
  }

  void _flushEvent({
    required String? eventName,
    required List<String> dataLines,
  }) {
    if (dataLines.isEmpty) {
      return;
    }

    final rawData = dataLines.join('\n');

    try {
      final decoded = jsonDecode(rawData);
      if (decoded is! Map<String, dynamic>) {
        return;
      }

      final event = AdminRealtimeEvent.fromMap(decoded);
      if (event.eventType.isEmpty &&
          eventName != null &&
          eventName.isNotEmpty) {
        final fallback = AdminRealtimeEvent(
          eventType: eventName,
          reportId: event.reportId,
          status: event.status,
        );
        _eventController.add(fallback);
        return;
      }

      _eventController.add(event);
    } catch (_) {
      if (eventName != null && eventName.isNotEmpty) {
        _eventController.add(AdminRealtimeEvent(eventType: eventName));
      }
    }
  }

  void _scheduleReconnect() {
    if (!_isRunning) return;

    _lineSubscription?.cancel();
    _lineSubscription = null;
    _client?.close();
    _client = null;

    _retryAttempt += 1;
    final delaySeconds = _retryAttempt > 15 ? 15 : _retryAttempt;

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      _connect();
    });
  }
}
