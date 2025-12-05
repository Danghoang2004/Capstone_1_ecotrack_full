import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend_ecotrack/core/services/auth_service.dart';
import 'package:frontend_ecotrack/presentation/partner_web/auth_partner/PartnerLoginScreen.dart';
import 'package:frontend_ecotrack/presentation/partner_web/dashboard_partner/PartnerDashboardScreen.dart';

Future<void> main() async {
  // Đảm bảo rằng ứng dụng này được chạy riêng cho Web
  // lệnh chạy: flutter run -d chrome --target=lib/main_partner.dart
  await dotenv.load(fileName: ".env");
  runApp(const PartnerApp());
}

class PartnerApp extends StatelessWidget {
  const PartnerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EcoTrack Partner Portal',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // Thêm locale support cho DatePicker
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', 'US'), Locale('vi', 'VN')],
      locale: const Locale('vi', 'VN'),
      // Bắt đầu từ màn hình chờ để kiểm tra token và vai trò
      home: const PartnerSplashScreen(),
      routes: {
        // CHỈ CÓ CÁC ROUTES CỦA PARTNER
        '/partner_login': (context) => const PartnerLoginScreen(),
        '/partner_dashboard': (context) => const PartnerDashboardScreen(),
      },
      // Định nghĩa route mặc định
      onGenerateRoute: (settings) {
        if (settings.name == '/') {
          return MaterialPageRoute(
            builder: (context) => const PartnerSplashScreen(),
          );
        }
        // Chặn các route khác không tồn tại
        return MaterialPageRoute(builder: (context) => const NotFoundScreen());
      },
    );
  }
}

// Màn hình chờ để kiểm tra trạng thái đăng nhập
class PartnerSplashScreen extends StatefulWidget {
  const PartnerSplashScreen({super.key});

  @override
  State<PartnerSplashScreen> createState() => _PartnerSplashScreenState();
}

class _PartnerSplashScreenState extends State<PartnerSplashScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // Độ trễ nhẹ để trải nghiệm tốt hơn
    await Future.delayed(const Duration(milliseconds: 500));

    final token = await _authService.getToken();

    if (token != null) {
      final isPartner = await _authService.isPartner();

      if (isPartner) {
        // Có token và là Partner -> Dashboard
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/partner_dashboard');
        }
        return;
      } else {
        // Có token nhưng không phải Partner -> Bắt buộc đăng xuất
        await _authService.logout();
      }
    }

    // Không có token hoặc không phải Partner -> Login Partner
    if (mounted) Navigator.pushReplacementNamed(context, '/partner_login');
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
              "Đang kiểm tra quyền truy cập Partner...",
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
              "Vui lòng truy cập qua /partner_login",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
