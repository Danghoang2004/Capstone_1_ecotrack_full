package capstone_1.Ecotrack_backend.dto.response;

import java.util.List;

public class AdminReportListResponse {
    private Long totalReports;
    private Long pendingCount;
    private Long verifiedCount;
    private Long rejectedCount;
    private Long cleanedCount;
    private List<AdminReportDetailDTO> reports;

    public AdminReportListResponse() {
    }

    public AdminReportListResponse(Long totalReports, Long pendingCount, Long verifiedCount,
            Long rejectedCount, Long cleanedCount, List<AdminReportDetailDTO> reports) {
        this.totalReports = totalReports;
        this.pendingCount = pendingCount;
        this.verifiedCount = verifiedCount;
        this.rejectedCount = rejectedCount;
        this.cleanedCount = cleanedCount;
        this.reports = reports;
    }

    public Long getTotalReports() {
        return totalReports;
    }

    public void setTotalReports(Long totalReports) {
        this.totalReports = totalReports;
    }

    public Long getPendingCount() {
        return pendingCount;
    }

    public void setPendingCount(Long pendingCount) {
        this.pendingCount = pendingCount;
    }

    public Long getVerifiedCount() {
        return verifiedCount;
    }

    public void setVerifiedCount(Long verifiedCount) {
        this.verifiedCount = verifiedCount;
    }

    public Long getRejectedCount() {
        return rejectedCount;
    }

    public void setRejectedCount(Long rejectedCount) {
        this.rejectedCount = rejectedCount;
    }

    public Long getCleanedCount() {
        return cleanedCount;
    }

    public void setCleanedCount(Long cleanedCount) {
        this.cleanedCount = cleanedCount;
    }

    public List<AdminReportDetailDTO> getReports() {
        return reports;
    }

    public void setReports(List<AdminReportDetailDTO> reports) {
        this.reports = reports;
    }
}
