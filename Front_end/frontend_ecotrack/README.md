# frontend_ecotrack

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

# chú thích
```
frontend_flutter/
│
├── lib/
│   ├── main.dart              # Điểm khởi chạy, xác định web/app
│   │
│   ├── core/                  # Cấu hình chung toàn hệ thống
│   │   ├── config/            # Router, Theme, App Settings
│   │   ├── constants/         # Biến tĩnh: API_URL, role, màu sắc
│   │   ├── utils/             # Hàm tiện ích: validator, date format,...
│   │   └── services/          # Gọi API, AuthService, Location, Upload
│   │
│   ├── data/                  # Quản lý dữ liệu ứng dụng
│   │   ├── models/            # Định nghĩa lớp: User, Report, Campaign,...
│   │   ├── dto/               # Kiểu dữ liệu trao đổi với API
│   │   └── repositories/      # Tầng kết nối API backend
│   │
│   ├── presentation/          # Giao diện UI chia theo vai trò
│   │   ├── auth/              # Màn hình đăng nhập / đăng ký
│   │   ├── user_app/          # Giao diện ứng dụng di động (USER)
│   │   │   ├── home/          # Trang chính
│   │   │   ├── report/        # Gửi ảnh rác
│   │   │   ├── map/           # Bản đồ rác cộng đồng
│   │   │   ├── campaign/      # Chiến dịch xanh, QR check-in
│   │   │   ├── reward/        # Điểm thưởng, badge
│   │   │   ├── quiz/          # Trò chơi môi trường
│   │   │   └── profile/       # Hồ sơ cá nhân
│   │   ├── admin_web/         # Giao diện quản trị (ADMIN - Web)
│   │   │   ├── dashboard/     # Tổng quan thống kê
│   │   │   ├── reports/       # Duyệt / xoá báo cáo
│   │   │   ├── users/         # Quản lý người dùng
│   │   │   ├── campaigns/     # Quản lý chiến dịch
│   │   │   └── vouchers/      # Quản lý phiếu thưởng
│   │   ├── partner/       # Giao diện đối tác (PARTNER )
│   │   │   ├── dashboard/     # Tổng quan chiến dịch và voucher
│   │   │   ├── vouchers/      # Tạo / cập nhật voucher
│   │   │   └── statistics/    # Thống kê kết quả
│   │   ├── common/            # Widget dùng chung (button, card,...)
│   │   ├── router.dart        # Điều hướng và xác định route theo vai trò
│   │   └── app_entry.dart     # Entry point app/web tùy role
│   │
│   ├── providers/             # State management (Riverpod / Bloc)
│   └── main_app.dart          # Cấu hình MaterialApp, Theme
│
├── assets/
│   ├── icons/                 # Icon tùy chỉnh
│   ├── images/                # Ảnh hiển thị trong app/web
│   └── lottie/                # Animation (tuỳ chọn)
│
├── web/                       # File cấu hình Flutter Web
│   ├── index.html
│   └── manifest.json
└── pubspec.yaml               # Khai báo thư viện Flutter

```