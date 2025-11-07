import 'dart:io';
import 'package:image_picker/image_picker.dart';

class UploadController {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;

  File? get selectedImage => _selectedImage;

  /// Chọn ảnh từ camera
  Future<void> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (image != null) {
        _selectedImage = File(image.path);
      }
    } catch (e) {
      print('Error picking image from camera: $e');
      rethrow;
    }
  }

  /// Chọn ảnh từ thư viện
  Future<void> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image != null) {
        _selectedImage = File(image.path);
      }
    } catch (e) {
      print('Error picking image from gallery: $e');
      rethrow;
    }
  }

  /// Hiển thị dialog cho user chọn camera hoặc gallery
  Future<void> showImageSourceDialog(Function(ImageSource) onSelected) async {
    // Function này sẽ được gọi từ UI để hiển thị dialog
    // UI sẽ tự xử lý dialog và gọi pickImageFromCamera hoặc pickImageFromGallery
    onSelected(ImageSource.camera);
  }

  /// Upload ảnh lên server (sẽ implement sau khi có API)
  Future<void> uploadImage() async {
    if (_selectedImage == null) {
      throw Exception('No image selected');
    }
    // TODO: Implement API call để upload ảnh
    print('Uploading image: ${_selectedImage!.path}');
  }

  /// Reset selected image
  void clearImage() {
    _selectedImage = null;
  }
}
