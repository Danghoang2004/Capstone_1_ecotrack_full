package capstone_1.Ecotrack_backend.controller.admin;

import capstone_1.Ecotrack_backend.dto.response.PartnerSimpleDto;
import capstone_1.Ecotrack_backend.repository.PartnerRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/admin/partners")
@PreAuthorize("hasAuthority('ROLE_ADMIN')")
@CrossOrigin("*")
public class AdminPartnerController {

    @Autowired
    private PartnerRepository partnerRepository;

    @GetMapping
    public List<PartnerSimpleDto> getAllPartners() {
        return partnerRepository.findAll()
                .stream()
                .map(p -> new PartnerSimpleDto(
                        p.getPartnerId(),
                        p.getCompanyName()
                ))
                .toList();
    }
}
