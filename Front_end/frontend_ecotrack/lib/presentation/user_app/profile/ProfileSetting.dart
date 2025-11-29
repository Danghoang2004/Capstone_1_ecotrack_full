import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

void main() {
  runApp(const ProfileEditApp());
}

/* 1. MODEL USER – DỮ LIỆU NHẬP RA / LẤY TỪ DATABASE */
class UserModel {
  String fullName;
  String email;
  String phone;
  String address;
  String? avatarPath;

  UserModel({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.address,
    this.avatarPath,
  });
}

class ProfileEditApp extends StatelessWidget {
  const ProfileEditApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Chỉnh Sửa Hồ Sơ',
      theme: ThemeData(fontFamily: 'Arial', primaryColor: Colors.green),
      home: const ProfileEditPage(),
    );
  }
}

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  File? _selectedImage;

  // CONTROLLERS ĐỂ KẾT NỐI DATABASE
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  final TextEditingController _oldPass = TextEditingController();
  final TextEditingController _newPass = TextEditingController();
  final TextEditingController _confirmPass = TextEditingController();

  // ẨN HIỆN PASSWORD
  bool _showOldPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  // ------------------ USER MODEL ------------------
  UserModel user = UserModel(fullName: "", email: "", phone: "", address: "");

  void loadUserData() {
    user = UserModel(
      fullName: "Nguyễn Văn A",
      email: "nguyenvana@gmail.com",
      phone: "0901234567",
      address: "123 Đường ABC",
      avatarPath: null,
    );

    // Đổ vào TextField
    _nameController.text = user.fullName;
    _emailController.text = user.email;
    _phoneController.text = user.phone;
    _addressController.text = user.address;
  }

  /* 3. SAVE DATA GỬI LÊN API / DATABASE */
  void saveUserData() {
    user.fullName = _nameController.text;
    user.email = _emailController.text;
    user.phone = _phoneController.text;
    user.address = _addressController.text;
    user.avatarPath = _selectedImage?.path;

    // Api.updateUser(user);
    // hoặc
    // UPDATE User SET fullName = '...', email = '...' WHERE id = ...
  }

  /* 4. EMAIL & PASSWORD VALIDATION*/
  bool isValidEmail(String email) {
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return regex.hasMatch(email);
  }

  bool isValidPassword(String pass) {
    return pass.length >= 6;
  }

  /*PICK IMAGE*/
  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      final filePath = result.files.single.path;
      if (filePath != null) {
        setState(() {
          _selectedImage = File(filePath);
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(
      fontSize: 13,
      color: Colors.grey[700],
      fontWeight: FontWeight.w400,
    );

    final textFieldDecoration = InputDecoration(
      filled: true,
      fillColor: const Color(0xfff5f5f5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Column(
          children: [
            const Text(
              'Chỉnh Sửa Hồ Sơ',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              'Cập nhật thông tin cá nhân của bạn',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ],
        ),
      ),

      // ======================== BODY ================================
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ------------------ AVATAR --------------------
            const SizedBox(height: 10),
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 110,
                      width: 110,
                      decoration: BoxDecoration(
                        color: const Color(0xfff5f5f5),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.green, width: 2),
                        image: _selectedImage != null
                            ? DecorationImage(
                                image: FileImage(_selectedImage!),
                                fit: BoxFit.cover,
                              )
                            : (user.avatarPath != null
                                  ? DecorationImage(
                                      image: FileImage(File(user.avatarPath!)),
                                      fit: BoxFit.cover,
                                    )
                                  : null),
                      ),
                      child: _selectedImage == null && user.avatarPath == null
                          ? const Icon(
                              Icons.person_outline,
                              size: 60,
                              color: Colors.green,
                            )
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 5,
                    right: 10,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 18,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Nhấp để thay đổi ảnh đại diện",
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 25),

            // ------------------ THÔNG TIN CÁ NHÂN --------------------
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Thông tin cá nhân",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  const SizedBox(height: 12),

                  Text("Họ và Tên", style: labelStyle),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _nameController,
                    decoration: textFieldDecoration,
                  ),

                  const SizedBox(height: 12),
                  Text("Email", style: labelStyle),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _emailController,
                    decoration: textFieldDecoration.copyWith(
                      errorText:
                          _emailController.text.isNotEmpty &&
                              !isValidEmail(_emailController.text)
                          ? "Email không hợp lệ"
                          : null,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),

                  const SizedBox(height: 12),
                  Text("Số Điện Thoại", style: labelStyle),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _phoneController,
                    decoration: textFieldDecoration,
                  ),

                  const SizedBox(height: 12),
                  Text("Địa Chỉ", style: labelStyle),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _addressController,
                    decoration: textFieldDecoration,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // ------------------ ĐỔI MẬT KHẨU --------------------
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Đổi Mật Khẩu",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  const SizedBox(height: 12),

                  Text("Mật Khẩu Hiện Tại", style: labelStyle),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _oldPass,
                    obscureText: !_showOldPassword,
                    decoration: textFieldDecoration.copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showOldPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.grey,
                        ),
                        onPressed: () => setState(
                          () => _showOldPassword = !_showOldPassword,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  Text("Mật Khẩu Mới", style: labelStyle),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _newPass,
                    obscureText: !_showNewPassword,
                    decoration: textFieldDecoration.copyWith(
                      errorText:
                          _newPass.text.isNotEmpty &&
                              !isValidPassword(_newPass.text)
                          ? "Mật khẩu phải từ 6 ký tự trở lên"
                          : null,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showNewPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.grey,
                        ),
                        onPressed: () => setState(
                          () => _showNewPassword = !_showNewPassword,
                        ),
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),

                  const SizedBox(height: 12),
                  Text("Xác Nhận Mật Khẩu Mới", style: labelStyle),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _confirmPass,
                    obscureText: !_showConfirmPassword,
                    decoration: textFieldDecoration.copyWith(
                      errorText:
                          _confirmPass.text.isNotEmpty &&
                              _confirmPass.text != _newPass.text
                          ? "Mật khẩu không trùng khớp"
                          : null,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showConfirmPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.grey,
                        ),
                        onPressed: () => setState(
                          () => _showConfirmPassword = !_showConfirmPassword,
                        ),
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // ------------------ LƯU THAY ĐỔI --------------------
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  if (!isValidEmail(_emailController.text)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Email không hợp lệ")),
                    );
                    return;
                  }

                  if (_newPass.text.isNotEmpty &&
                      !isValidPassword(_newPass.text)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Mật khẩu phải từ 6 ký tự trở lên"),
                      ),
                    );
                    return;
                  }

                  saveUserData();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Lưu thay đổi thành công! 🎉"),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Lưu thay đổi',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
