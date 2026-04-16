import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  XFile? _selectedAvatarFile;
  Uint8List? _selectedAvatarBytes;
  String? _selectedAvatarFilename;
  final ImagePicker _picker = ImagePicker();

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
    if (avatar.startsWith('http')) return avatar;
    final baseUrl = dotenv.env['API_BASE_URL']!;
    return '$baseUrl$avatar';
  }

  ImageProvider? get _avatarProvider {
    if (_selectedAvatarBytes != null) {
      return MemoryImage(_selectedAvatarBytes!);
    }
    final avatarNetworkUrl = _avatarNetworkUrl;
    if (avatarNetworkUrl != null) {
      return NetworkImage(avatarNetworkUrl);
    }
    return null;
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

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: Color(0xFF1F8F53),
                ),
                title: const Text('Chọn từ thư viện'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await _handlePickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF1F8F53)),
                title: const Text('Chụp ảnh mới'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await _handlePickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handlePickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 85,
    );
    if (image == null) return;

    final bytes = await image.readAsBytes();
    if (!mounted) return;

    setState(() {
      _selectedAvatarFile = image;
      _selectedAvatarBytes = bytes;
      _selectedAvatarFilename = image.name.isNotEmpty
          ? image.name
          : 'avatar.jpg';
    });
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
        avatarBytes: _selectedAvatarBytes,
        avatarFilename: _selectedAvatarFilename,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lưu thay đổi thành công!'),
            backgroundColor: Color(0xFF2E7D32),
            duration: Duration(seconds: 2),
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
    const Color primaryGreen = Color(0xFF1F8F53);
    const Color bgLight = Color(0xFFF2F7F4);

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Chỉnh sửa hồ sơ',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: 0.2,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarBrightness: Brightness.light,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFF2F7F4), Color(0xFFEAF3ED)],
                ),
              ),
            ),
          ),
          Positioned(
            top: -90,
            right: -70,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryGreen.withOpacity(0.10),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -90,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFBDEFD0).withOpacity(0.24),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeroCard(primaryGreen),
                    const SizedBox(height: 16),
                    _buildCardSection(
                      title: 'Thông tin cá nhân',
                      subtitle: 'Cập nhật dữ liệu hiển thị trên hồ sơ của bạn',
                      child: Column(
                        children: [
                          _buildFormField(
                            'Họ và tên',
                            _nameController,
                            'Nhập họ và tên',
                          ),
                          const SizedBox(height: 12),
                          _buildFormField(
                            'Email',
                            _emailController,
                            'email@example.com',
                            readOnly: true,
                          ),
                          const SizedBox(height: 12),
                          _buildFormField(
                            'Số điện thoại',
                            _phoneController,
                            '+84 123456789',
                          ),
                          const SizedBox(height: 12),
                          _buildFormField(
                            'Địa chỉ',
                            _addressController,
                            'Nhập địa chỉ',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildCardSection(
                      title: 'Đổi mật khẩu',
                      subtitle: 'Để trống nếu bạn không muốn thay đổi mật khẩu',
                      child: Column(
                        children: [
                          _buildFormField(
                            'Mật khẩu hiện tại',
                            _currentPassController,
                            'Nhập mật khẩu hiện tại',
                            isPassword: true,
                          ),
                          const SizedBox(height: 12),
                          _buildFormField(
                            'Mật khẩu mới',
                            _newPassController,
                            'Nhập mật khẩu mới',
                            isPassword: true,
                          ),
                          const SizedBox(height: 12),
                          _buildFormField(
                            'Xác nhận mật khẩu',
                            _confirmPassController,
                            'Xác nhận mật khẩu mới',
                            isPassword: true,
                            validator: (val) {
                              if (val != null &&
                                  val.isNotEmpty &&
                                  val != _newPassController.text) {
                                return 'Mật khẩu không khớp';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _handleUpdate,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Icon(
                                Icons.save_outlined,
                                color: Colors.white,
                                size: 20,
                              ),
                        label: Text(
                          _isLoading ? 'ĐANG XỬ LÝ...' : 'Lưu thay đổi',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(Color primaryGreen) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1F8F53),
            const Color(0xFF1F8F53).withOpacity(0.84),
            const Color(0xFF0F6A3B),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.45),
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor: Colors.white,
                    backgroundImage: _avatarProvider,
                    child: _avatarProvider == null
                        ? const Icon(Icons.person, size: 48, color: Colors.grey)
                        : null,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.14),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Color(0xFF1F8F53),
                    size: 17,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            widget.currentProfile.fullName?.isNotEmpty == true
                ? widget.currentProfile.fullName!
                : (widget.currentProfile.username.isNotEmpty
                      ? widget.currentProfile.username
                      : 'Người dùng'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            widget.currentProfile.location?.isNotEmpty == true
                ? widget.currentProfile.location!
                : 'Chưa cập nhật địa chỉ',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.88),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withOpacity(0.20)),
            ),
            child: Text(
              'Nhấn ảnh để thay đổi avatar',
              style: TextStyle(
                color: Colors.white.withOpacity(0.96),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardSection({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE0ECE3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildFormField(
    String label,
    TextEditingController controller,
    String hint, {
    bool isPassword = false,
    bool readOnly = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          readOnly: readOnly,
          validator:
              validator ??
              (val) {
                if (val == null || val.isEmpty) {
                  return "Vui lòng nhập $label";
                }
                return null;
              },
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
            filled: true,
            fillColor: const Color(0xFFF8FBF9),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 15,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFF1F8F53),
                width: 1.6,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
          ),
        ),
      ],
    );
  }
}
