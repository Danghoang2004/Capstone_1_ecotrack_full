import 'goong_map_bridge_stub.dart'
    if (dart.library.html) 'goong_map_bridge_web.dart';

abstract class GoongMapBridge {
  static final GoongMapBridge instance = createGoongMapBridge();

  void registerViewFactory(String viewType);
  Object? findContainer(String viewType);
  bool isContainerReady(Object? container);
  bool get hasInitFunction;

  void initMap({
    required Object container,
    required String styleUrl,
    required double lng,
    required double lat,
    required double zoom,
  });

  bool isMapReady();
  void setMode(String mode);
  void setReports(String json);
  void setHeatPoints(String json);
  void zoomIn();
  void zoomOut();
  void disposeMap();
}
