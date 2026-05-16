import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:frontend_ecotrack/data/models/hotspot_models.dart';

class HotspotAlertNotificationService {
  HotspotAlertNotificationService._();

  static final HotspotAlertNotificationService instance =
      HotspotAlertNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _permissionRequested = false;

  Future<void> initialize() async {
    if (kIsWeb || _initialized) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(android: android, iOS: ios);
    await _plugin.initialize(settings);
    _initialized = true;
  }

  Future<void> requestPermissionIfNeeded() async {
    if (kIsWeb || _permissionRequested) return;

    await initialize();
    _permissionRequested = true;

    if (defaultTargetPlatform == TargetPlatform.android) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      return;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      await _plugin
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  Future<void> showHotspotAlert(NearbyHotspot hotspot) async {
    if (kIsWeb) return;

    await requestPermissionIfNeeded();

    const androidDetails = AndroidNotificationDetails(
      'hotspot_alerts',
      'Hotspot alerts',
      channelDescription: 'Alerts when you are near a waste hotspot.',
      importance: Importance.high,
      priority: Priority.high,
      color: Color(0xFF2E7D32),
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: iosDetails,
    );

    final title = 'Bạn gần một điểm rác!';

    // Determine whether to show the dominant waste type.
    final displayType = wasteTypeVietnamese(hotspot.dominantWasteType);
    final hideType = hotspot.dominantWasteType == null ||
      hotspot.dominantWasteType.isEmpty ||
      hotspot.dominantWasteType.contains('_') ||
      displayType.toUpperCase() == hotspot.dominantWasteType.toUpperCase();

    final mainSegment = hideType ? '' : ' Chủ yếu: $displayType.';

    final body =
      'Có ${hotspot.reportCount} báo cáo ở đây.$mainSegment Giúp dọn dẹp?';

    await _plugin.show(
      hotspot.clusterId,
      title,
      body,
      details,
      payload: 'hotspot:${hotspot.clusterId}',
    );
  }
}

String wasteTypeVietnamese(String type) {
  switch (type.toUpperCase()) {
    case 'PLASTIC':
      return 'Rác nhựa';

    case 'PAPER':
      return 'Rác giấy';

    case 'METAL':
      return 'Rác kim loại';

    case 'ORGANIC':
      return 'Rác hữu cơ';

    case 'CONSTRUCTION':
      return 'Rác xây dựng';

    case 'ELECTRONIC':
      return 'Rác điện tử';

    case 'MIXED':
      return 'Rác hỗn hợp';

    case 'GLASS':
      return 'Rác thủy tinh';

    default:
      return type;
  }
}
