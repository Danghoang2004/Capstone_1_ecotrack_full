package capstone_1.Ecotrack_backend.service;

import capstone_1.Ecotrack_backend.dto.request.RegisterRequest;
import capstone_1.Ecotrack_backend.dto.request.UpdateProfileRequest;
import capstone_1.Ecotrack_backend.model.User;

public interface UserService {
    User registerUser(RegisterRequest request);
}
