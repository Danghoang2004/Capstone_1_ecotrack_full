import 'goong_map_bridge.dart';

class _GoongMapBridgeStub implements GoongMapBridge {
  @override
  void registerViewFactory(String viewType) {}

  @override
  Object? findContainer(String viewType) => null;

  @override
  bool isContainerReady(Object? container) => false;

  @override
  bool get hasInitFunction => false;

  @override
  void initMap({
    required Object container,
    required String styleUrl,
    required double lng,
    required double lat,
    required double zoom,
  }) {}

  @override
  bool isMapReady() => false;

  @override
  void setMode(String mode) {}

  @override
  void setReports(String json) {}

  @override
  void setHeatPoints(String json) {}

  @override
  void zoomIn() {}

  @override
  void zoomOut() {}

  @override
  void disposeMap() {}
}

GoongMapBridge createGoongMapBridge() => _GoongMapBridgeStub();
