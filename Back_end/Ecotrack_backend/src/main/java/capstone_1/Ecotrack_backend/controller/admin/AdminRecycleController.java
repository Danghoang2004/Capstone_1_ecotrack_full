package capstone_1.Ecotrack_backend.controller.admin;

import capstone_1.Ecotrack_backend.cloudinaryconfig.CloudinaryService;
import capstone_1.Ecotrack_backend.dto.request.AdminRecycleGuideUpsertRequest;
import capstone_1.Ecotrack_backend.dto.response.AdminRecycleGuideResponse;
import capstone_1.Ecotrack_backend.service.RecycleGuideService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.net.URI;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/admin/recycle")
public class AdminRecycleController {

    @Autowired
    private RecycleGuideService service;

    @Autowired
    private CloudinaryService cloudinaryService;

    @GetMapping("/guides")
    @PreAuthorize("hasAuthority('ROLE_ADMIN')")
    public List<AdminRecycleGuideResponse> listGuides() {
        return service.listAll();
    }

    @PostMapping("/guides")
    @PreAuthorize("hasAuthority('ROLE_ADMIN')")
    public ResponseEntity<AdminRecycleGuideResponse> createGuide(@RequestBody AdminRecycleGuideUpsertRequest guide) {
        AdminRecycleGuideResponse created = service.create(guide);
        return ResponseEntity.created(URI.create("/api/admin/recycle/guides/" + created.getGuideId())).body(created);
    }

    @GetMapping("/guides/{id}")
    @PreAuthorize("hasAuthority('ROLE_ADMIN')")
    public ResponseEntity<AdminRecycleGuideResponse> getGuide(@PathVariable Long id) {
        return service.findById(id).map(ResponseEntity::ok).orElseGet(() -> ResponseEntity.notFound().build());
    }

    @PutMapping("/guides/{id}")
    @PreAuthorize("hasAuthority('ROLE_ADMIN')")
    public ResponseEntity<AdminRecycleGuideResponse> updateGuide(@PathVariable Long id, @RequestBody AdminRecycleGuideUpsertRequest guide) {
        AdminRecycleGuideResponse updated = service.update(id, guide);
        return ResponseEntity.ok(updated);
    }

    @DeleteMapping("/guides/{id}")
    @PreAuthorize("hasAuthority('ROLE_ADMIN')")
    public ResponseEntity<Void> deleteGuide(@PathVariable Long id) {
        service.delete(id);
        return ResponseEntity.noContent().build();
    }

    @PostMapping(value = "/upload-media", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @PreAuthorize("hasAuthority('ROLE_ADMIN')")
    public ResponseEntity<Map<String, Object>> uploadMedia(
            @RequestPart("file") MultipartFile file,
            @RequestParam(value = "folder", required = false, defaultValue = "ecotrack/recycle") String folder) {
        try {
            if (file == null || file.isEmpty()) {
                return ResponseEntity.badRequest().body(Map.of(
                        "success", false,
                        "message", "File upload rỗng."));
            }
            Map<String, Object> uploadResult = cloudinaryService.uploadFile(file, folder);
            String url = uploadResult.get("secure_url") == null ? "" : uploadResult.get("secure_url").toString();
            return ResponseEntity.ok(Map.of(
                    "success", true,
                    "url", url,
                    "message", "Upload thành công"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of(
                    "success", false,
                    "message", e.getMessage()));
        }
    }
}
