package capstone_1.Ecotrack_backend.dto.response;

import java.util.List;

/**
 * Response từ FastAPI sau khi gom nhóm báo cáo thành hotspot
 */
public class HotspotClusterResponse {

    public static class Hotspot {
        private Integer cluster_id;
        private Double center_lat;
        private Double center_lng;
        private Double radius_km;
        private Integer report_count;
        private List<Long> report_ids;

        public Hotspot() {
        }

        // Getters & Setters
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
    }

    private Boolean success;
    private List<Hotspot> hotspots;
    private Integer total_clusters;
    private Integer noise_points;

    public HotspotClusterResponse() {
    }

    // Getters & Setters
    public Boolean getSuccess() {
        return success;
    }

    public void setSuccess(Boolean success) {
        this.success = success;
    }

    public List<Hotspot> getHotspots() {
        return hotspots;
    }

    public void setHotspots(List<Hotspot> hotspots) {
        this.hotspots = hotspots;
    }

    public Integer getTotal_clusters() {
        return total_clusters;
    }

    public void setTotal_clusters(Integer total_clusters) {
        this.total_clusters = total_clusters;
    }

    public Integer getNoise_points() {
        return noise_points;
    }

    public void setNoise_points(Integer noise_points) {
        this.noise_points = noise_points;
    }
}
