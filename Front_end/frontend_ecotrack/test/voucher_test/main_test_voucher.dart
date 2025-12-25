import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'test_voucher_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env file - đơn giản như main.dart
  await dotenv.load(fileName: ".env");

  runApp(const TestVoucherApp());
}

class TestVoucherApp extends StatelessWidget {
  const TestVoucherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Test Voucher',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const TestVoucherScreen(),
    );
  }
}
