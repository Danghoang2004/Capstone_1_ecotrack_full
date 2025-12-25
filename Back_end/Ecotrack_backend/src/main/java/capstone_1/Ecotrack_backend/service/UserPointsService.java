package capstone_1.Ecotrack_backend.service;



import capstone_1.Ecotrack_backend.model.UserPoints;
import capstone_1.Ecotrack_backend.repository.UserPointsRepository;
import org.springframework.stereotype.Service;

@Service
public class UserPointsService {

    private final UserPointsRepository userPointsRepository;

    public UserPointsService(UserPointsRepository userPointsRepository) {
        this.userPointsRepository = userPointsRepository;
    }

    public int getUserPoints(Long userId) {
    UserPoints up = userPointsRepository.findById(userId)
            .orElseGet(() -> {
                UserPoints newUp = new UserPoints();
                newUp.setUserId(userId);
                newUp.setPoints(0);
                return userPointsRepository.save(newUp);
            });

    return up.getPoints();
}

}
