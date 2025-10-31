backend/
│
├── src/
│   ├── main/
│   │   ├── java/com/ecotrack/
│   │   │   ├── controller/         # Xử lý request từ frontend (API)
│   │   │   │   ├── auth/           # API đăng nhập, đăng ký, JWT
│   │   │   │   ├── user/           # API dành cho người dùng (App)
│   │   │   │   ├── admin/          # API dành cho quản trị viên (Web)
│   │   │   │   ├── partner/        # API dành cho đối tác (Web)
│   │   │   │   └── common/         # API dùng chung (public map, stats)
│   │   │   ├── service/            # Xử lý logic nghiệp vụ
│   │   │   │   ├── impl/           # Triển khai chi tiết các service
│   │   │   │   └── interface/      # Khai báo interface service
│   │   │   ├── repository/         # Tầng giao tiếp cơ sở dữ liệu (JPA)
│   │   │   ├── model/              # Các Entity ánh xạ sang bảng DB
│   │   │   ├── dto/                # Dữ liệu trao đổi giữa API và client
│   │   │   │   ├── request/        # Dữ liệu client gửi lên
│   │   │   │   └── response/       # Dữ liệu trả về cho client
│   │   │   ├── security/           # Cấu hình bảo mật, JWT, phân quyền
│   │   │   ├── config/             # Cấu hình chung (DB, CORS, Swagger)
│   │   │   ├── exception/          # Xử lý lỗi và ngoại lệ toàn hệ thống
│   │   │   └── EcotrackApplication.java # File main khởi chạy ứng dụng
│   │   └── resources/
│   │       ├── application.properties   # Cấu hình hệ thống (port, DB, token)
│   │       └── static/             # (Tùy chọn) file tĩnh nếu cần
│   └── test/                       # Unit test, integration test
│
├── pom.xml                         # Khai báo dependency Maven thư viện 