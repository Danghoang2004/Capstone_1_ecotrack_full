package capstone_1.Ecotrack_backend.service;

import com.google.zxing.BarcodeFormat;
import com.google.zxing.client.j2se.MatrixToImageWriter;
import com.google.zxing.common.BitMatrix;
import com.google.zxing.qrcode.QRCodeWriter;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.nio.file.FileSystems;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

@Service
public class QRCodeService {


    private static final String UPLOAD_DIR = "D:/project_Capstone_1_full/Back_end/Ecotrack_backend/uploads/";
    private static final String QR_SUB_DIR = "campaign_qrs/"; // Thư mục con cho gọn

    public String generateAndSaveQRCode(Long campaignId, String content, int width, int height) throws Exception {
        // 1. Tạo thư mục nếu chưa tồn tại
        Path uploadPath = Paths.get(UPLOAD_DIR + QR_SUB_DIR);
        if (!Files.exists(uploadPath)) {
            Files.createDirectories(uploadPath);
        }

        // 2. Tạo tên file duy nhất
        String fileName = "campaign_qr_" + campaignId + ".png";
        Path filePath = uploadPath.resolve(fileName);

        // 3. Tạo QR Code BitMatrix
        QRCodeWriter qrCodeWriter = new QRCodeWriter();
        BitMatrix bitMatrix = qrCodeWriter.encode(content, BarcodeFormat.QR_CODE, width, height);

        // 4. Ghi file ra ổ cứng
        MatrixToImageWriter.writeToPath(bitMatrix, "PNG", filePath);

        // 5. Trả về đường dẫn Web (tương ứng với cấu hình addResourceHandlers)
        // Kết quả sẽ là: /uploads/campaign_qrs/campaign_qr_1.png
        return "/uploads/" + QR_SUB_DIR + fileName;
    }
}