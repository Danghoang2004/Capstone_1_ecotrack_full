package capstone_1.Ecotrack_backend.controller.user;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import capstone_1.Ecotrack_backend.model.WasteReport;
import capstone_1.Ecotrack_backend.repository.WasteReportRepository;

@RestController
@RequestMapping("/api/public")
public class PublicReportController {

    @Autowired
    private WasteReportRepository repo;

    @GetMapping("/reports")
    public List<WasteReport> getAll() {
        return repo.findAll();
    }
}
