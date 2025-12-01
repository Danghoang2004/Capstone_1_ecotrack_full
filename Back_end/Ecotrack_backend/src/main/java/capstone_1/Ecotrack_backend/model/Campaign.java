package capstone_1.Ecotrack_backend.model;

import com.fasterxml.jackson.annotation.JsonFormat;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalTime;

@Entity
@Table(name = "campaigns")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Campaign {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "campaign_id")
    private Long campaignId;

    // --- QUAN TRỌNG: Liên kết Partner ---
    // Cột trong DB là created_by_partner_id
    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "created_by_partner_id")
    private Partner partner;

    @Column(nullable = false)
    private String title;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(name = "start_date", nullable = false)
    private LocalDate startDate;

    @Column(name = "end_date", nullable = false)
    private LocalDate endDate;

    @Column(name = "start_time")
    private LocalTime startTime;

    @Column(name = "end_time")
    private LocalTime endTime;

    @Column(name = "location_address", nullable = false)
    private String locationAddress;

    @Column(name = "max_participants")
    private Integer maxParticipants;

    @Column(name = "image_url")
    private String imageUrl;

    @Column(name = "reward_points")
    private Integer rewardPoints;

    // --- MỚI: Cột lưu đường dẫn QR Code ---
    @Column(name = "qr_code_url")
    private String qrCodeUrl;
}