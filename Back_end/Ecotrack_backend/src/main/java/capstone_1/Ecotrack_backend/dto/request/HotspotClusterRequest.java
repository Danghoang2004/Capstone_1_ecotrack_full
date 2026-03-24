package capstone_1.Ecotrack_backend.dto.request;

import java.util.List;

/**
 * Request gửi sang FastAPI để gom nhóm báo cáo thành hotspot
 */
public class HotspotClusterRequest {

    public static class ReportCoordinate {
        private Long id;
        private Double lat;
        private Double lng;

        public ReportCoordinate() {
        }

        public ReportCoordinate(Long id, Double lat, Double lng) {
            this.id = id;
            this.lat = lat;
            this.lng = lng;
        }

        // Getters & Setters
        public Long getId() {
            return id;
        }

        public void setId(Long id) {
            this.id = id;
        }

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
    }

    private List<ReportCoordinate> reports;
    private Double eps_km;
    private Integer min_samples;

    public HotspotClusterRequest() {
    }

    public HotspotClusterRequest(List<ReportCoordinate> reports, Double eps_km, Integer min_samples) {
        this.reports = reports;
        this.eps_km = eps_km;
        this.min_samples = min_samples;
    }

    // Getters & Setters
    public List<ReportCoordinate> getReports() {
        return reports;
    }

    public void setReports(List<ReportCoordinate> reports) {
        this.reports = reports;
    }

    public Double getEps_km() {
        return eps_km;
    }

    public void setEps_km(Double eps_km) {
        this.eps_km = eps_km;
    }

    public Integer getMin_samples() {
        return min_samples;
    }

    public void setMin_samples(Integer min_samples) {
        this.min_samples = min_samples;
    }
}
