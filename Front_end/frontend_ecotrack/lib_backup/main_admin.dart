import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend_ecotrack/core/services/auth_service.dart';
import 'package:frontend_ecotrack/presentation/admin_partner_web/auth_admin/AdminLoginScreen.dart';
import 'package:frontend_ecotrack/presentation/admin_partner_web/dashboard_admin/AdminDashboardScreen.dart';
import 'package:frontend_ecotrack/presentation/admin_partner_web/dashboard_partner/partner_dashboard_screen.dart';

Future<void> main() async {
  // Đảm bảo rằng ứng dụng này được chạy riêng cho Web
  // lệnh chạy: flutter run -d chrome --target=lib/main_admin.dart
  await dotenv.load(fileName: ".env");
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EcoTrack Admin Console',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // Bắt đầu từ màn hình chờ để kiểm tra token và vai trò
      home: const AdminSplashScreen(),
      routes: {
        // CHỈ CÓ CÁC ROUTES CỦA ADMIN và parter
        '/admin_login': (context) => const AdminLoginScreen(),
        '/admin_dashboard': (context) => const AdminDashboardScreen(),
        '/partner_dashboard': (context) => const PartnerDashboardScreen(),
      },
      // Định nghĩa route mặc định
      onGenerateRoute: (settings) {
        if (settings.name == '/') {
          return MaterialPageRoute(
            builder: (context) => const AdminSplashScreen(),
          );
        }
        // Chặn các route khác không tồn tại
        return MaterialPageRoute(builder: (context) => const NotFoundScreen());
      },
    );
  }
}

// Màn hình chờ để kiểm tra trạng thái đăng nhập
class AdminSplashScreen extends StatefulWidget {
  const AdminSplashScreen({super.key});

  @override
  State<AdminSplashScreen> createState() => _AdminSplashScreenState();
}

class _AdminSplashScreenState extends State<AdminSplashScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    await Future.delayed(const Duration(milliseconds: 500));

    final token = await _authService.getToken();

    if (token != null) {
      final isAdmin = await _authService.isAdmin();
      final isPartner = await _authService.isPartner(); // KIỂM TRA ROLE PARTNER

      if (isAdmin) {
        if (mounted)
          Navigator.pushReplacementNamed(context, '/admin_dashboard');
        return;
      }

      if (isPartner) {
        // KIỂM TRA PARTNER SAU ADMIN
        if (mounted)
          Navigator.pushReplacementNamed(context, '/partner_dashboard');
        return;
      }

      // Nếu có token nhưng không phải Admin và cũng không phải Partner (có thể là User), thì đăng xuất
      await _authService.logout();
    }

    // Nếu không có token hoặc không có quyền phù hợp, chuyển đến Login
    if (mounted) Navigator.pushReplacementNamed(context, '/admin_login');
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 10),
            Text(
              "Đang kiểm tra quyền truy cập Admin...",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// Màn hình 404 đơn giản
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(0),
        child: SizedBox(),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber_rounded, size: 80, color: Colors.orange),
            SizedBox(height: 20),
            Text(
              "Lỗi 404 - Trang không tồn tại",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              "Vui lòng truy cập qua /admin_login",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
