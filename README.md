# EcoTrack Project

## 📋 Tổng quan
Dự án EcoTrack là một ứng dụng quản lý môi trường với 3 phần chính:
- **User App**: Ứng dụng mobile/web cho người dùng
- **Admin Dashboard**: Bảng điều khiển quản lý cho admin
- **Partner Portal**: Cổng thông tin cho đối tác

## 🚀 Hướng dẫn Setup

### Backend (Spring Boot)

1. **Cài đặt Database:**
   ```bash
   cd Back_end/Ecotrack_backend
   mysql -u spring -p < data.mysql
   ```

   **Lưu ý quan trọng:**
   - File `data.mysql` sẽ **tự động tạo database `ecotrack_demo1`** và tất cả các bảng cần thiết
   - File này cũng chứa dữ liệu mẫu (admin, partner accounts)
   - **KHÔNG cần tạo database thủ công**, chỉ cần chạy lệnh trên là đủ

2. **Cấu hình Backend:**
   - File `application.properties` đã được cấu hình với `server.address=127.0.0.1`
   - Điều này giúp team làm việc dễ dàng hơn, không cần thay đổi IP mỗi người
   - Backend sẽ chạy tại: `http://127.0.0.1:8080`

3. **Chạy Backend:**
   ```bash
   cd Back_end/Ecotrack_backend
   ./mvnw spring-boot:run
   ```

### Frontend (Flutter)

1. **Setup Environment:**
   ```bash
   cd Front_end/frontend_ecotrack
   cp .env.example .env
   ```
   Sau đó chỉnh sửa file `.env` với API_BASE_URL của bạn.

2. **Cài đặt dependencies:**
   ```bash
   flutter pub get
   ```

3. **Chạy ứng dụng:**

   **User App:**
   ```bash
   flutter run -d chrome --target=lib/main.dart
   # hoặc
   flutter run
   ```

   **Admin Dashboard:**
   ```bash
   flutter run -d chrome --target=lib/main_admin.dart
   ```

   **Partner Portal:**
   ```bash
   flutter run -d chrome --target=lib/main_partner.dart
   ```

   **Test Voucher Screen:**
   ```bash
   flutter run -d chrome --target=test/voucher_test/main_test_voucher.dart
   ```

### Android Emulator Setup

Nếu chạy trên Android emulator, cần forward port:
```bash
C:\Users\vanloc\AppData\Local\Android\Sdk\platform-tools\adb.exe reverse tcp:8080 tcp:8080
```

## 🔐 Tài khoản mặc định

### Admin
- **Email:** `admin@gmail.com`
- **Password:** `password`

### Partner
- **Email:** `partner@gmail.com`
- **Password:** `password`

## 📁 Cấu trúc Project

```
Capstone_1_ecotrack_full/
├── Back_end/
│   └── Ecotrack_backend/          # Spring Boot Backend
│       ├── data.mysql            # Database schema & initial data
│       └── src/
│           └── main/java/...     # Backend source code
│
└── Front_end/
    └── frontend_ecotrack/         # Flutter Frontend
        ├── lib/
        │   ├── main.dart         # User App entry point
        │   ├── main_admin.dart   # Admin Dashboard entry point
        │   ├── main_partner.dart # Partner Portal entry point
        │   └── presentation/     # UI screens & widgets
        ├── test/
        │   └── voucher_test/    # Test voucher screen
        │       ├── main_test_voucher.dart
        │       ├── test_voucher_screen.dart
        │       └── widgets/
        │           └── user_login_widget.dart
        ├── .env.example          # Environment variables template
        └── .env                  # Environment variables (không commit)
```

## 🆕 Tính năng đã hoàn thành (Hôm nay)

### 1. Cải thiện Configuration
- ✅ Sửa `application.properties`: đổi `server.address` thành `127.0.0.1` (thay vì IP cụ thể)
- ✅ Lý do: Tiện lợi hơn cho team, không cần mỗi người phải sửa IP riêng
- ✅ Tạo `.env.example` để quản lý `API_BASE_URL` linh hoạt
- ✅ Lợi ích: Dễ dàng chuyển từ local sang production, không cần sửa code

### 2. Test Voucher Screen
- ✅ Tạo màn hình test voucher với đầy đủ chức năng
- ✅ Hiển thị danh sách voucher có sẵn
- ✅ Áp dụng voucher và tính toán giá sau giảm
- ✅ Lịch sử mua hàng và voucher đã sử dụng
- ✅ Tổ chức code chuyên nghiệp: tách widget login riêng, đặt trong `test/voucher_test/`

### 4. Code Organization
- ✅ Refactor test voucher code vào `test/voucher_test/`
- ✅ Tách `UserLoginWidget` thành widget riêng để tái sử dụng
- ✅ Cấu trúc code rõ ràng, dễ bảo trì

## 📝 Lưu ý cho Team

1. **Environment Variables:**
   - Luôn copy `.env.example` để tạo file `.env` của riêng bạn
   - **KHÔNG** commit file `.env` lên git (đã có trong `.gitignore`)
   - Chỉ commit `.env.example` để team biết cần config gì
   - **Lý do sử dụng `.env`:**
     - Thay vì hardcode IP trong code, sử dụng `.env` để quản lý `API_BASE_URL`
     - Dễ dàng thay đổi từ local (`http://127.0.0.1:8080`) sang production khi deploy
     - Mỗi developer có thể config IP riêng nếu cần (ví dụ: test với backend trên máy khác)
     - Không cần sửa code, chỉ cần thay đổi file `.env`

2. **Database:**
   - **Cách setup:** Chỉ cần chạy file `data.mysql` vào MySQL, nó sẽ tự động:
     - Tạo database `ecotrack_demo1`
     - Tạo tất cả các bảng cần thiết
     - Insert dữ liệu mẫu (admin, partner accounts)
   - **Quy tắc làm việc với `data.mysql`:**
     - ✅ **ĐƯỢC:** Thêm dữ liệu mẫu mới vào cuối file (INSERT statements)
     - ✅ **ĐƯỢC:** Thêm bảng mới nếu cần (CREATE TABLE statements)
     - ❌ **KHÔNG ĐƯỢC:** Sửa đổi phần code/dữ liệu của người khác đã làm
     - ❌ **KHÔNG ĐƯỢC:** Xóa hoặc thay đổi các bảng/dữ liệu đã có
     - **Mục đích:** Tránh conflict và đảm bảo mọi người có cùng database structure
   - File `data.mysql` hiện tại đã bao gồm:
     - Schema các bảng
     - Tài khoản admin: `admin@gmail.com` / `password`
     - Tài khoản partner: `partner@gmail.com` / `password`

3. **Test Voucher:**
   - Màn hình test voucher nằm trong `test/voucher_test/`
   - Cần đăng nhập với tài khoản USER trước khi test
   - Chạy bằng: `flutter run -d chrome --target=test/voucher_test/main_test_voucher.dart`

4. **Git Workflow:**
   - Luôn pull trước khi làm việc
   - Commit message rõ ràng, mô tả những gì đã làm
   - Không commit file `.env`, `node_modules`, hoặc các file build



