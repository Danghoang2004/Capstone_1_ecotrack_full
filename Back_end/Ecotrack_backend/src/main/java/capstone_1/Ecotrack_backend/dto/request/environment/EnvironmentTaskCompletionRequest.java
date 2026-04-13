package capstone_1.Ecotrack_backend.dto.request.environment;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;

public class EnvironmentTaskCompletionRequest {

    @NotBlank(message = "afterImageUrl is required")
    private String afterImageUrl;

    @NotNull(message = "gpsLat is required")
    private BigDecimal gpsLat;

    @NotNull(message = "gpsLong is required")
    private BigDecimal gpsLong;

    @NotBlank(message = "completionNote is required")
    private String completionNote;

    public String getAfterImageUrl() {
        return afterImageUrl;
    }

    public void setAfterImageUrl(String afterImageUrl) {
        this.afterImageUrl = afterImageUrl;
    }

    public BigDecimal getGpsLat() {
        return gpsLat;
    }

    public void setGpsLat(BigDecimal gpsLat) {
        this.gpsLat = gpsLat;
    }

    public BigDecimal getGpsLong() {
        return gpsLong;
    }

    public void setGpsLong(BigDecimal gpsLong) {
        this.gpsLong = gpsLong;
    }

    public String getCompletionNote() {
        return completionNote;
    }

    public void setCompletionNote(String completionNote) {
        this.completionNote = completionNote;
    }
}
