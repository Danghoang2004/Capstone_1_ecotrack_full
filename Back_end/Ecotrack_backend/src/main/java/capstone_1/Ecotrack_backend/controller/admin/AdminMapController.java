package capstone_1.Ecotrack_backend.controller.admin;

import capstone_1.Ecotrack_backend.dto.response.WasteClusterResponse;
import capstone_1.Ecotrack_backend.service.MapClusterService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/v1/admin/maps")
@RequiredArgsConstructor
public class AdminMapController {

    private final MapClusterService mapClusterService;

    @GetMapping("/clusters")
    public ResponseEntity<List<WasteClusterResponse>> getWasteClusters() {
        List<WasteClusterResponse> data = mapClusterService.getClusteredHotspots();
        return ResponseEntity.ok(data);
    }
}