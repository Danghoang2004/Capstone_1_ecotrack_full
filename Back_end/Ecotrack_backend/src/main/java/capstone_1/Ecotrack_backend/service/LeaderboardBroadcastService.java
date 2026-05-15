package capstone_1.Ecotrack_backend.service;

import capstone_1.Ecotrack_backend.dto.response.RankingUserResponse;
import capstone_1.Ecotrack_backend.dto.response.RankingGroupResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class LeaderboardBroadcastService {

    private final RankingService rankingService;
    private final NotificationBroadcastService broadcastService;

    public void broadcastIndividualLeaderboardUpdate() {
        try {
            List<RankingUserResponse> rankings = rankingService.getIndividualRankings();
            broadcastService.broadcastToTopic("leaderboard/individual", rankings);
            System.out.println(" Broadcasted individual leaderboard update");
        } catch (Exception e) {
            System.err.println(" Error broadcasting leaderboard: " + e.getMessage());
        }
    }

    public void broadcastGroupLeaderboardUpdate() {
        try {
            List<RankingGroupResponse> rankings = rankingService.getGroupRankings();
            broadcastService.broadcastToTopic("leaderboard/group", rankings);
            System.out.println(" Broadcasted group leaderboard update");
        } catch (Exception e) {
            System.err.println(" Error broadcasting group leaderboard: " + e.getMessage());
        }
    }
}
