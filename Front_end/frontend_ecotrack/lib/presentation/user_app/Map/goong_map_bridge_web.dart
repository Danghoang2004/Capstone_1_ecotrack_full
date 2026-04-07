// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:js' as js;
import 'dart:html' as html;
import 'dart:ui_web' as ui;

import 'goong_map_bridge.dart';

class _GoongMapBridgeWeb implements GoongMapBridge {
  @override
  void registerViewFactory(String viewType) {
    ui.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
      final container = html.DivElement()
        ..id = viewType
        ..className = 'goong-map-host'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.position = 'absolute'
        ..style.top = '0'
        ..style.right = '0'
        ..style.bottom = '0'
        ..style.left = '0';
      return container;
    });
  }

  @override
  Object? findContainer(String viewType) =>
      html.document.getElementById(viewType);

  @override
  bool isContainerReady(Object? container) {
    if (container is! html.Element) {
      return false;
    }
    final width = container.clientWidth;
    final height = container.clientHeight;
    return container.isConnected == true && width > 0 && height > 0;
  }

  @override
  bool get hasInitFunction => js.context['goongAdminMapInit'] != null;

  @override
  void initMap({
    required Object container,
    required String styleUrl,
    required double lng,
    required double lat,
    required double zoom,
  }) {
    js.context.callMethod('goongAdminMapInit', [
      container,
      styleUrl,
      lng,
      lat,
      zoom,
    ]);
  }

  @override
  bool isMapReady() =>
      js.context.callMethod('goongAdminMapIsReady', const []) == true;

  @override
  void setMode(String mode) {
    js.context.callMethod('goongAdminMapSetMode', [mode]);
  }

  @override
  void setReports(String json) {
    js.context.callMethod('goongAdminMapSetReports', [json]);
  }

  @override
  void setHeatPoints(String json) {
    js.context.callMethod('goongAdminMapSetHeatPoints', [json]);
  }

  @override
  void zoomIn() {
    js.context.callMethod('goongAdminMapZoomIn', const []);
  }

  @override
  void zoomOut() {
    js.context.callMethod('goongAdminMapZoomOut', const []);
  }

  @override
  void disposeMap() {
    if (js.context['goongAdminMapDispose'] != null) {
      js.context.callMethod('goongAdminMapDispose', const []);
    }
  }
}

GoongMapBridge createGoongMapBridge() => _GoongMapBridgeWeb();
