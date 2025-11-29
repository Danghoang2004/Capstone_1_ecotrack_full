package capstone_1.Ecotrack_backend.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "partners")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Partner {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "partner_id")
    private Long partnerId;

    @OneToOne
    @JoinColumn(name = "user_id", referencedColumnName = "user_id", nullable = false)
    private User user; // Liên kết với bảng users (tài khoản đại diện)

    @Column(name = "company_name", nullable = false)
    private String companyName;

    @Column(name = "website")
    private String website;

    @Column(name = "logo_url")
    private String logoUrl;
}