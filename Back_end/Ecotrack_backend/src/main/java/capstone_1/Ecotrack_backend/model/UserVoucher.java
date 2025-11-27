package capstone_1.Ecotrack_backend.model;

import jakarta.persistence.*;

@Entity
@Table(name = "user_vouchers")
public class UserVoucher {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "user_voucher_id")
    private Long userVoucherId;

    @Column(name = "user_id")
    private Long userId;

    @Column(name = "voucher_id")
    private Long voucherId;

    // getter & setter
    public Long getUserVoucherId() { return userVoucherId; }
    public void setUserVoucherId(Long userVoucherId) { this.userVoucherId = userVoucherId; }

    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }

    public Long getVoucherId() { return voucherId; }
    public void setVoucherId(Long voucherId) { this.voucherId = voucherId; }
}
