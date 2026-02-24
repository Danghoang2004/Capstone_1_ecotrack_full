# 🌿 Ecotrack Backend

Backend của dự án Ecotrack — API REST được triển khai bằng Spring Boot (Java 17).

**Mục tiêu README này:** hướng dẫn cài đặt môi trường, cấu hình phụ thuộc / biến môi trường và cách chạy ứng dụng trên máy phát triển (Windows / macOS / Linux).

**Tóm tắt kỹ thuật:**
- Java 17
- Spring Boot 3.5.x
- Maven (có wrapper `mvnw` / `mvnw.cmd` trong repo)
- MySQL (schema mẫu trong `data.mysql`)
- Thư viện chính: Spring Web, Spring Data JPA, Spring Security, jjwt, Lombok, Apache POI, ZXing, Spring Mail

**Lưu ý quan trọng về bảo mật:** không lưu thông tin nhạy cảm (mật khẩu DB, token, mật khẩu email) trong mã nguồn. Sử dụng biến môi trường hoặc công cụ secrets.

---

**1) Chuẩn bị (Prerequisites)**

- Java 17: cài JDK 17 và thiết lập `JAVA_HOME`.
  - Windows (choco):
    ```powershell
    choco install temurin17
    ```
  - macOS (brew):
    ```bash
    brew install --cask temurin17
    ```
  - Linux (Ubuntu):
    ```bash
    sudo apt update
    sudo apt install openjdk-17-jdk
    ```

- Maven: không bắt buộc nếu dùng wrapper `mvnw` (Windows: `mvnw.cmd`). Nếu muốn cài Maven:
  - Windows (choco): `choco install maven`
  - macOS (brew): `brew install maven`

- MySQL: cài MySQL 8.x hoặc tương thích.
  - Tạo database và import schema mẫu (tham khảo phần bên dưới).

---

**2) Những tệp & cấu hình quan trọng**

- `pom.xml` — dependencies và Java version (pom dùng Java 17, Spring Boot 3.5.7).
- `src/main/resources/application.properties` — cấu hình mặc định (DB, JWT, Email, port).
  - Current file contains example values (DB `ecotrack_demo2`, user/password `spring/spring`) — KHÔNG để thông tin này trên repo công khai.
  - Trong repo có `data.mysql` — file SQL tạo schema và dữ liệu mẫu (lưu ý: `data.mysql` tạo database `ecotrack_demo1`).
  - Main class: `src/main/java/capstone_1/Ecotrack_backend/EcotrackBackendApplication.java`.

---

**3) Thiết lập database (MySQL)**

1. Khởi động MySQL server.
2. Tạo database (ví dụ `ecotrack_demo1` hoặc `ecotrack_demo2`). Ví dụ import `data.mysql`:

```bash
mysql -u root -p < Back_end/Ecotrack_backend/data.mysql
```

3. Hoặc tạo thủ công và chạy nội dung file SQL nếu cần chỉnh tên DB.

4. Cập nhật `application.properties` hoặc dùng biến môi trường (xem phần biến môi trường bên dưới) để trỏ tới database đúng tên.

---

**4) Biến môi trường được đề xuất (không ghi vào mã nguồn)**

Bạn có thể ghi đè các giá trị trong `application.properties` bằng biến môi trường hoặc tham số dòng lệnh Spring Boot. Các biến thường cần thiết:

- `SPRING_DATASOURCE_URL` — ví dụ `jdbc:mysql://localhost:3306/ecotrack_demo1?useSSL=false&serverTimezone=UTC`
- `SPRING_DATASOURCE_USERNAME` — DB username
- `SPRING_DATASOURCE_PASSWORD` — DB password
- `APP_JWT_SECRET` — secret cho JWT (thay thế `app.jwt.secret` trong properties)
- `APP_JWT_EXPIRATION_MS` — thời gian hết hạn token
- `SPRING_MAIL_USERNAME` và `SPRING_MAIL_PASSWORD` — nếu dùng tính năng gửi email
- `SERVER_PORT` — thay đổi cổng nếu cần

Ví dụ (Windows PowerShell):
```powershell
$env:SPRING_DATASOURCE_URL='jdbc:mysql://localhost:3306/ecotrack_demo1?useSSL=false&serverTimezone=UTC'
$env:SPRING_DATASOURCE_USERNAME='myuser'
$env:SPRING_DATASOURCE_PASSWORD='mypassword'
$env:APP_JWT_SECRET='replace_with_secure_random_value'
```

Hoặc khởi động với tham số dòng lệnh:
```bash
./mvnw spring-boot:run -Dspring-boot.run.arguments="--spring.datasource.url=jdbc:... --spring.datasource.username=..."
```

---

**5) Chạy ứng dụng**

- Dùng Maven wrapper (khuyên dùng, không cần cài Maven toàn cục):
  - Windows:
    ```powershell
    cd Back_end/Ecotrack_backend
    .\mvnw.cmd clean package
    .\mvnw.cmd spring-boot:run
    ```
  - macOS / Linux:
    ```bash
    cd Back_end/Ecotrack_backend
    ./mvnw clean package
    ./mvnw spring-boot:run
    ```

- Hoặc build jar và chạy:
  ```bash
  ./mvnw -DskipTests package
  java -jar target/Ecotrack_backend-0.0.1-SNAPSHOT.jar
  ```

Ứng dụng mặc định chạy trên `server.port` trong `application.properties` (mặc định `8080`), hoặc nếu `SERVER_PORT`/`server.port` được override.

---

**6) Ghi chú về cấu hình hiện tại và điểm cần chỉnh**

- `src/main/resources/application.properties` hiện có:
  - `spring.datasource.url=jdbc:mysql://localhost:3306/ecotrack_demo2` — nhưng `data.mysql` tạo `ecotrack_demo1`. Hãy đồng bộ tên DB hoặc sửa `application.properties`.
  - File chứa thông tin email (username/password) và JWT secret mẫu. Thay bằng biến môi trường và đừng commit thông tin thật.

**7) Mẹo phát triển**

- Sử dụng `spring.jpa.hibernate.ddl-auto=update` chỉ trên môi trường dev nếu muốn để JPA tự tạo/điều chỉnh schema. Hiện project để `validate`.
- Bật `spring.mail.properties.mail.debug` chỉ trên môi trường dev.
- Đối với Lombok, IDE cần plugin Lombok (IntelliJ/Eclipse) để hiển thị code generated.

---

**8) Triển khai & Docker (tùy chọn)**

- Có thể đóng gói jar và dùng Dockerfile (tự tạo) hoặc dùng `spring-boot:build-image` để tạo image OCI.

---

**9) Vấn đề thường gặp & Troubleshooting**

- Lỗi kết nối DB: kiểm tra `spring.datasource.url`, user, password, và rằng MySQL chấp nhận kết nối từ host.
- Lỗi phiên bản Java: đảm bảo `java -version` là 17.
- Lỗi Lombok: cài plugin Lombok cho IDE và enable annotation processing.

---

Nếu bạn muốn, tôi có thể:
- Tạo file `application-dev.properties` mẫu sử dụng biến môi trường.
- Thay thế các giá trị nhạy cảm trong `application.properties` bằng placeholders và hướng dẫn cụ thể từng hệ điều hành để cấu hình biến môi trường.

----

File SQL mẫu: `data.mysql` (đã có trong repo) — import vào MySQL trước khi chạy.

Main application class: `src/main/java/capstone_1/Ecotrack_backend/EcotrackBackendApplication.java`.
