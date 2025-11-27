package capstone_1.Ecotrack_backend.controller.user;

import capstone_1.Ecotrack_backend.dto.response.RankingGroupResponse;
import capstone_1.Ecotrack_backend.dto.response.RankingUserResponse;
import capstone_1.Ecotrack_backend.service.RankingService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/ranking")
@CrossOrigin
@RequiredArgsConstructor
public class RankingController {

    private final RankingService rankingService;

    @GetMapping("/individual")
    public ResponseEntity<List<RankingUserResponse>> getIndividualRankings() {
        List<RankingUserResponse> rankings = rankingService.getIndividualRankings();
        return ResponseEntity.ok(rankings);
    }

    @GetMapping("/group")
    public ResponseEntity<List<RankingGroupResponse>> getGroupRankings() {
        List<RankingGroupResponse> rankings = rankingService.getGroupRankings();
        return ResponseEntity.ok(rankings);
    }
}

