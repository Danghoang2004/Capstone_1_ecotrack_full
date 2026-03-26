package capstone_1.Ecotrack_backend.dto.response;

import java.util.List;
import java.util.Map;

/**
 * Response dự đoán hotspot từ FastAPI.
 */
public class HotspotPredictResponse {

    public static class HotspotZone {
        private Integer cluster_id;
        private Double center_lat;
        private Double center_lng;
        private Double radius_km;
        private Integer report_count;
        private List<Long> report_ids;
        private Double risk_score;
        private Integer predicted_count_7d;

        public Integer getCluster_id() {
            return cluster_id;
        }

        public void setCluster_id(Integer cluster_id) {
            this.cluster_id = cluster_id;
        }

        public Double getCenter_lat() {
            return center_lat;
        }

        public void setCenter_lat(Double center_lat) {
            this.center_lat = center_lat;
        }

        public Double getCenter_lng() {
            return center_lng;
        }

        public void setCenter_lng(Double center_lng) {
            this.center_lng = center_lng;
        }

        public Double getRadius_km() {
            return radius_km;
        }

        public void setRadius_km(Double radius_km) {
            this.radius_km = radius_km;
        }

        public Integer getReport_count() {
            return report_count;
        }

        public void setReport_count(Integer report_count) {
            this.report_count = report_count;
        }

        public List<Long> getReport_ids() {
            return report_ids;
        }

        public void setReport_ids(List<Long> report_ids) {
            this.report_ids = report_ids;
        }

        public Double getRisk_score() {
            return risk_score;
        }

        public void setRisk_score(Double risk_score) {
            this.risk_score = risk_score;
        }

        public Integer getPredicted_count_7d() {
            return predicted_count_7d;
        }

        public void setPredicted_count_7d(Integer predicted_count_7d) {
            this.predicted_count_7d = predicted_count_7d;
        }
    }

    public static class GridRisk {
        private String grid_id;
        private Double center_lat;
        private Double center_lng;
        private Integer predicted_count_7d;
        private Double risk_score;

        public String getGrid_id() {
            return grid_id;
        }

        public void setGrid_id(String grid_id) {
            this.grid_id = grid_id;
        }

        public Double getCenter_lat() {
            return center_lat;
        }

        public void setCenter_lat(Double center_lat) {
            this.center_lat = center_lat;
        }

        public Double getCenter_lng() {
            return center_lng;
        }

        public void setCenter_lng(Double center_lng) {
            this.center_lng = center_lng;
        }

        public Integer getPredicted_count_7d() {
            return predicted_count_7d;
        }

        public void setPredicted_count_7d(Integer predicted_count_7d) {
            this.predicted_count_7d = predicted_count_7d;
        }

        public Double getRisk_score() {
            return risk_score;
        }

        public void setRisk_score(Double risk_score) {
            this.risk_score = risk_score;
        }
    }

    public static class HeatmapPoint {
        private Double lat;
        private Double lng;
        private Double intensity;
        private Integer predicted_count_7d;

        public Double getLat() {
            return lat;
        }

        public void setLat(Double lat) {
            this.lat = lat;
        }

        public Double getLng() {
            return lng;
        }

        public void setLng(Double lng) {
            this.lng = lng;
        }

        public Double getIntensity() {
            return intensity;
        }

        public void setIntensity(Double intensity) {
            this.intensity = intensity;
        }

        public Integer getPredicted_count_7d() {
            return predicted_count_7d;
        }

        public void setPredicted_count_7d(Integer predicted_count_7d) {
            this.predicted_count_7d = predicted_count_7d;
        }
    }

    private Boolean success;
    private List<HotspotZone> predicted_hotspots_7_days;
    private List<GridRisk> risk_score_by_grid;
    private List<HeatmapPoint> heatmap_points;
    private List<GridRisk> top_risk_areas;
    private Map<String, Object> metadata;

    public Boolean getSuccess() {
        return success;
    }

    public void setSuccess(Boolean success) {
        this.success = success;
    }

    public List<HotspotZone> getPredicted_hotspots_7_days() {
        return predicted_hotspots_7_days;
    }

    public void setPredicted_hotspots_7_days(List<HotspotZone> predicted_hotspots_7_days) {
        this.predicted_hotspots_7_days = predicted_hotspots_7_days;
    }

    public List<GridRisk> getRisk_score_by_grid() {
        return risk_score_by_grid;
    }

    public void setRisk_score_by_grid(List<GridRisk> risk_score_by_grid) {
        this.risk_score_by_grid = risk_score_by_grid;
    }

    public List<HeatmapPoint> getHeatmap_points() {
        return heatmap_points;
    }

    public void setHeatmap_points(List<HeatmapPoint> heatmap_points) {
        this.heatmap_points = heatmap_points;
    }

    public List<GridRisk> getTop_risk_areas() {
        return top_risk_areas;
    }

    public void setTop_risk_areas(List<GridRisk> top_risk_areas) {
        this.top_risk_areas = top_risk_areas;
    }

    public Map<String, Object> getMetadata() {
        return metadata;
    }

    public void setMetadata(Map<String, Object> metadata) {
        this.metadata = metadata;
    }
}
