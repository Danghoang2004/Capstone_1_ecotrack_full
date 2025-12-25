import 'dart:io';
import 'package:flutter/material.dart';
import 'package:frontend_ecotrack/core/services/user_service.dart';
import 'package:frontend_ecotrack/data/models/ProfileView.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  final ProfileView currentProfile;

  const EditProfileScreen({super.key, required this.currentProfile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final UserService _userService = UserService();
  bool _isLoading = false;

  // --- PHẦN MỚI THÊM CHO ẢNH ---
  File? _selectedImageFile; // Biến lưu ảnh người dùng vừa chọn
  final ImagePicker _picker = ImagePicker(); // Instance chọn ảnh
  // -----------------------------

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;

  final TextEditingController _currentPassController = TextEditingController();
  final TextEditingController _newPassController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.currentProfile.fullName ?? "",
    );
    _emailController = TextEditingController(
      text: widget.currentProfile.email ?? "",
    );
    _phoneController = TextEditingController(
      text: widget.currentProfile.phoneNumber ?? "",
    );
    _addressController = TextEditingController(
      text: widget.currentProfile.location ?? "",
    );
  }

  String? get _avatarNetworkUrl {
    final avatar = widget.currentProfile.avatarUrl;

    if (avatar.isEmpty) return null;

    // Nếu backend sau này trả full URL thì không bị lỗi
    if (avatar.startsWith('http')) return avatar;

    final baseUrl = dotenv.env['API_BASE_URL']!;
    return '$baseUrl$avatar';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _currentPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  // --- HÀM LOGIC CHỌN ẢNH ---
  Future<void> _pickImage() async {
    // Hiển thị popup cho user chọn nguồn ảnh
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Chọn từ thư viện'),
              onTap: () async {
                Navigator.of(ctx).pop();
                final XFile? image = await _picker.pickImage(
                  source: ImageSource.gallery,
                );
                if (image != null) {
                  setState(() => _selectedImageFile = File(image.path));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Chụp ảnh mới'),
              onTap: () async {
                Navigator.of(ctx).pop();
                final XFile? image = await _picker.pickImage(
                  source: ImageSource.camera,
                );
                if (image != null) {
                  setState(() => _selectedImageFile = File(image.path));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await _userService.updateProfileFull(
        fullName: _nameController.text.trim(),
        location: _addressController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        currentPassword: _currentPassController.text.isNotEmpty
            ? _currentPassController.text
            : null,
        newPassword: _newPassController.text.isNotEmpty
            ? _newPassController.text
            : null,
        confirmPassword: _confirmPassController.text.isNotEmpty
            ? _confirmPassController.text
            : null,

        // Truyền file ảnh vào service để upload
        avatarFile: _selectedImageFile,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lưu thay đổi thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll("Exception:", "").trim()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen = Color(0xFF2E7D32);
    const Color bgGrey = Color(0xFFF5F5F5);

    return Scaffold(
      backgroundColor: bgGrey,
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Chỉnh Sửa Hồ Sơ",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text(
                "Cập nhật thông tin cá nhân của bạn",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),

              // === AVATAR SECTION (ĐÃ SỬA) ===
              // Bọc GestureDetector để bắt sự kiện click
              GestureDetector(
                onTap: _pickImage, // Gọi hàm chọn ảnh khi bấm vào vùng này
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.grey[200],
                            // Logic hiển thị ảnh: Ưu tiên ảnh vừa chọn từ máy -> sau đó mới đến ảnh cũ từ server
                            backgroundImage: _selectedImageFile != null
                                ? FileImage(_selectedImageFile!)
                                : (_avatarNetworkUrl != null
                                      ? NetworkImage(_avatarNetworkUrl!)
                                      : null),

                            // Nếu không có cả 2 loại ảnh thì hiện icon mặc định
                            child:
                                (_selectedImageFile == null &&
                                    _avatarNetworkUrl == null)
                                ? const Icon(
                                    Icons.person,
                                    size: 40,
                                    color: primaryGreen,
                                  )
                                : null,
                          ),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: primaryGreen,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Nhấp để thay đổi ảnh đại diện",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ... (Phần UI form bên dưới giữ nguyên) ...

              // === INFO SECTION ===
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Thông tin cá nhân",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildLabel("Họ và Tên"),
                    _buildInput(_nameController, "Nguyễn Văn A"),
                    const SizedBox(height: 12),
                    _buildLabel("Email"),
                    _buildInput(
                      _emailController,
                      "email@example.com",
                      readOnly: true,
                      isEmailLink: true,
                    ),
                    const SizedBox(height: 12),
                    _buildLabel("Số Điện Thoại"),
                    _buildInput(_phoneController, "+84 123456789"),
                    const SizedBox(height: 12),
                    _buildLabel("Địa chỉ"),
                    _buildInput(_addressController, "123 nguyen van linh..."),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // === PASSWORD SECTION ===
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Đổi Mật Khẩu",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildLabel("Mật khẩu hiện tại"),
                    _buildInput(
                      _currentPassController,
                      "Nhập mật khẩu hiện tại",
                      isPassword: true,
                    ),
                    const SizedBox(height: 12),
                    _buildLabel("Mật khẩu mới"),
                    _buildInput(
                      _newPassController,
                      "Nhập mật khẩu mới",
                      isPassword: true,
                    ),
                    const SizedBox(height: 12),
                    _buildLabel("Xác nhận mật khẩu mới"),
                    _buildInput(
                      _confirmPassController,
                      "Xác nhận mật khẩu mới",
                      isPassword: true,
                      validator: (val) {
                        if (val != null &&
                            val.isNotEmpty &&
                            val != _newPassController.text) {
                          return "Mật khẩu không khớp";
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              // === BUTTON ===
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _handleUpdate,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.save_outlined, color: Colors.white),
                  label: Text(
                    _isLoading ? "ĐANG XỬ LÝ..." : "Lưu thay đổi",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helpers Widgets ---
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, color: Colors.black87),
      ),
    );
  }

  Widget _buildInput(
    TextEditingController controller,
    String hint, {
    bool isPassword = false,
    bool readOnly = false,
    bool isEmailLink = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      readOnly: readOnly,
      validator: validator,
      style: TextStyle(
        color: isEmailLink ? Colors.blue[700] : Colors.black,
        decoration: isEmailLink
            ? TextDecoration.underline
            : TextDecoration.none,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFE0E0E0).withOpacity(0.6),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.green, width: 1),
        ),
      ),
    );
  }
}
