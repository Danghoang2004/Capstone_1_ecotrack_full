package capstone_1.Ecotrack_backend.dto.response;

import java.util.List;
import java.util.Map;

public class HotspotNearbyResponse {
    private Boolean success;
    private Boolean alert;
    private NearbyHotspot nearestHotspot;
    private List<NearbyHotspot> hotspots;

    public Boolean getSuccess() {
        return success;
    }

    public void setSuccess(Boolean success) {
        this.success = success;
    }

    public Boolean getAlert() {
        return alert;
    }

    public void setAlert(Boolean alert) {
        this.alert = alert;
    }

    public NearbyHotspot getNearestHotspot() {
        return nearestHotspot;
    }

    public void setNearestHotspot(NearbyHotspot nearestHotspot) {
        this.nearestHotspot = nearestHotspot;
    }

    public List<NearbyHotspot> getHotspots() {
        return hotspots;
    }

    public void setHotspots(List<NearbyHotspot> hotspots) {
        this.hotspots = hotspots;
    }

    public static class NearbyHotspot {
        private Integer clusterId;
        private Double centerLat;
        private Double centerLng;
        private Double radiusKm;
        private Integer reportCount;
        private Double distanceMeters;
        private Map<String, Long> categoryCounts;
        private String dominantWasteType;
        private RecyclingSuggestion recyclingSuggestion;

        public Integer getClusterId() {
            return clusterId;
        }

        public void setClusterId(Integer clusterId) {
            this.clusterId = clusterId;
        }

        public Double getCenterLat() {
            return centerLat;
        }

        public void setCenterLat(Double centerLat) {
            this.centerLat = centerLat;
        }

        public Double getCenterLng() {
            return centerLng;
        }

        public void setCenterLng(Double centerLng) {
            this.centerLng = centerLng;
        }

        public Double getRadiusKm() {
            return radiusKm;
        }

        public void setRadiusKm(Double radiusKm) {
            this.radiusKm = radiusKm;
        }

        public Integer getReportCount() {
            return reportCount;
        }

        public void setReportCount(Integer reportCount) {
            this.reportCount = reportCount;
        }

        public Double getDistanceMeters() {
            return distanceMeters;
        }

        public void setDistanceMeters(Double distanceMeters) {
            this.distanceMeters = distanceMeters;
        }

        public Map<String, Long> getCategoryCounts() {
            return categoryCounts;
        }

        public void setCategoryCounts(Map<String, Long> categoryCounts) {
            this.categoryCounts = categoryCounts;
        }

        public String getDominantWasteType() {
            return dominantWasteType;
        }

        public void setDominantWasteType(String dominantWasteType) {
            this.dominantWasteType = dominantWasteType;
        }

        public RecyclingSuggestion getRecyclingSuggestion() {
            return recyclingSuggestion;
        }

        public void setRecyclingSuggestion(RecyclingSuggestion recyclingSuggestion) {
            this.recyclingSuggestion = recyclingSuggestion;
        }
    }

    public static class RecyclingSuggestion {
        private String title;
        private List<String> steps;

        public RecyclingSuggestion() {
        }

        public RecyclingSuggestion(String title, List<String> steps) {
            this.title = title;
            this.steps = steps;
        }

        public String getTitle() {
            return title;
        }

        public void setTitle(String title) {
            this.title = title;
        }

        public List<String> getSteps() {
            return steps;
        }

        public void setSteps(List<String> steps) {
            this.steps = steps;
        }
    }
}
