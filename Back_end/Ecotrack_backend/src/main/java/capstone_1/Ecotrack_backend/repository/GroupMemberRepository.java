package capstone_1.Ecotrack_backend.repository;

import capstone_1.Ecotrack_backend.model.GroupMember;
import capstone_1.Ecotrack_backend.model.GroupMemberId;
import org.springframework.data.jpa.repository.JpaRepository;

public interface GroupMemberRepository extends JpaRepository<GroupMember, GroupMemberId> {
    Long countByUserId(Long userId);
    void deleteByUserId(Long userId);
}
