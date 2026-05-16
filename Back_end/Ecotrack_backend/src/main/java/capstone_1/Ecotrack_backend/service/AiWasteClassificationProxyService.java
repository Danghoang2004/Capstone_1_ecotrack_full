package capstone_1.Ecotrack_backend.service;

import capstone_1.Ecotrack_backend.dto.response.AiWasteClassificationResultDto;
import com.fasterxml.jackson.databind.JsonNode;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.FileSystemResource;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.multipart.MultipartFile;

import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

@Service
public class AiWasteClassificationProxyService {

    private final RestTemplate restTemplate = new RestTemplate();

    @Value("${ai.classify-waste-url}")
    private String aiClassifyWasteUrl;

    private String getAiClassifyWasteUrl() {
        return aiClassifyWasteUrl;
    }

    public AiWasteClassificationResultDto classifyWaste(MultipartFile image) {
        if (image == null || image.isEmpty()) {
            throw new IllegalArgumentException("Ảnh tải lên không hợp lệ.");
        }

        Path tempFile = null;
        try {
            String fileName = image.getOriginalFilename() == null ? "upload.jpg" : image.getOriginalFilename();
            tempFile = Files.createTempFile("ai-classify-", "-" + fileName);
            Files.write(tempFile, image.getBytes());

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.MULTIPART_FORM_DATA);

            MultiValueMap<String, Object> body = new LinkedMultiValueMap<>();
            body.add("file", new FileSystemResource(tempFile.toFile()));

            HttpEntity<MultiValueMap<String, Object>> requestEntity = new HttpEntity<>(body, headers);

            ResponseEntity<JsonNode> response = restTemplate.postForEntity(
                    getAiClassifyWasteUrl(),
                    requestEntity,
                    JsonNode.class);

            if (!response.getStatusCode().is2xxSuccessful() || response.getBody() == null) {
                throw new IllegalStateException("AI service trả về phản hồi không hợp lệ.");
            }

            JsonNode root = response.getBody();
            if (!root.path("success").asBoolean(false)) {
                throw new IllegalStateException("AI service xử lý thất bại.");
            }

            JsonNode data = root.path("data");
            if (data.isMissingNode() || data.isNull()) {
                throw new IllegalStateException("AI service không trả dữ liệu phân loại.");
            }

            return mapToResultDto(data);
        } catch (IllegalArgumentException | IllegalStateException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new IllegalStateException("Không thể kết nối AI service: " + ex.getMessage());
        } finally {
            if (tempFile != null) {
                try {
                    Files.deleteIfExists(tempFile);
                } catch (Exception ignored) {
                }
            }
        }
    }

    private AiWasteClassificationResultDto mapToResultDto(JsonNode data) {
        AiWasteClassificationResultDto result = new AiWasteClassificationResultDto();
        boolean trashDetected = data.path("is_waste").asBoolean(
                data.path("is_trash").asBoolean(
                        data.path("trashDetected").asBoolean(false)));
        result.setTrashDetected(trashDetected);
        result.setOverallConfidence(data.path("overall_confidence").asDouble(0.0));
        result.setTotalObjectsDetected(data.path("total_objects_detected").asInt(0));
        result.setWasteTypes(readWasteTypes(data));
        result.setDetections(readDetections(data.path("detections")));

        if (!data.path("output_image").isNull()) {
            result.setAnalyzedImagePath(data.path("output_image").asText(""));
        }

        return result;
    }

    private Map<String, Double> readWasteTypes(JsonNode data) {
        JsonNode wasteTypesNode = data.path("waste_types");
        if (wasteTypesNode.isMissingNode() || wasteTypesNode.isNull() || !wasteTypesNode.isObject()) {
            wasteTypesNode = data.path("type_percentage");
        }

        Map<String, Double> wasteTypes = new HashMap<>();
        if (wasteTypesNode != null && wasteTypesNode.isObject()) {
            Iterator<Map.Entry<String, JsonNode>> iterator = wasteTypesNode.fields();
            while (iterator.hasNext()) {
                Map.Entry<String, JsonNode> entry = iterator.next();
                wasteTypes.put(entry.getKey(), entry.getValue().asDouble(0.0));
            }
        }

        return wasteTypes;
    }

    private List<AiWasteClassificationResultDto.DetectionDto> readDetections(JsonNode detectionsNode) {
        List<AiWasteClassificationResultDto.DetectionDto> detections = new ArrayList<>();
        if (detectionsNode == null || !detectionsNode.isArray()) {
            return detections;
        }

        for (JsonNode node : detectionsNode) {
            AiWasteClassificationResultDto.DetectionDto detection = new AiWasteClassificationResultDto.DetectionDto();
            detection.setClassNameVietnamese(node.path("class_name_vietnamese").asText(""));
            detection.setClassNameRaw(node.path("class_name_raw").asText(""));
            detection.setConfidence(node.path("confidence").asDouble(0.0));
            detections.add(detection);
        }

        return detections;
    }
}
