package capstone_1.Ecotrack_backend.service;

import capstone_1.Ecotrack_backend.dto.response.UserHistoryResponse;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

public interface UserHistoryService {

    Page<UserHistoryResponse> getPointHistory(Long userId, Pageable pageable);

    Page<UserHistoryResponse> getReportHistory(Long userId, Pageable pageable);

    Page<UserHistoryResponse> getQuizHistory(Long userId, Pageable pageable);
}