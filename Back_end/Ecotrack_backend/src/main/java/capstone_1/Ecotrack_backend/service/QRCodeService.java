package capstone_1.Ecotrack_backend.service;

import com.cloudinary.Cloudinary;
import com.cloudinary.utils.ObjectUtils;
import com.google.zxing.BarcodeFormat;
import com.google.zxing.WriterException;
import com.google.zxing.client.j2se.MatrixToImageWriter;
import com.google.zxing.common.BitMatrix;
import com.google.zxing.qrcode.QRCodeWriter;
import org.springframework.stereotype.Service;

import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.Map;

@Service
public class QRCodeService {

    private final Cloudinary cloudinary;

    public QRCodeService(Cloudinary cloudinary) {
        this.cloudinary = cloudinary;
    }

    public String generateAndSaveQRCode(Long campaignId, String content, int width, int height) throws Exception {
        byte[] qrImageBytes = generateQrImageBytes(content, width, height);

        @SuppressWarnings("unchecked")
        Map<String, Object> uploadResult = cloudinary.uploader().upload(
                qrImageBytes,
                ObjectUtils.asMap(
                        "folder", "ecotrack/campaign_qrs",
                        "public_id", "campaign_qr_" + campaignId,
                        "overwrite", true,
                        "resource_type", "image",
                        "format", "png"));

        return uploadResult.get("secure_url").toString();
    }

    private byte[] generateQrImageBytes(String content, int width, int height) throws WriterException, IOException {
        QRCodeWriter qrCodeWriter = new QRCodeWriter();
        BitMatrix bitMatrix = qrCodeWriter.encode(content, BarcodeFormat.QR_CODE, width, height);
        BufferedImage bufferedImage = MatrixToImageWriter.toBufferedImage(bitMatrix);

        try (ByteArrayOutputStream outputStream = new ByteArrayOutputStream()) {
            javax.imageio.ImageIO.write(bufferedImage, "PNG", outputStream);
            return outputStream.toByteArray();
        }
    }
}