package capstone_1.Ecotrack_backend.service;

import capstone_1.Ecotrack_backend.dto.response.UserCouponResponse;
import capstone_1.Ecotrack_backend.repository.UserCouponRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class UserCouponService {

    private final UserCouponRepository userCouponReponsitory;

    public List<UserCouponResponse> getMyCoupons(Long userId) {
        return userCouponReponsitory.findByUserId(userId);
    }
}
