import 'package:frontend_ecotrack/core/services/user_service.dart';
import 'package:frontend_ecotrack/data/models/ProfileView.dart';

class ProfileController {
  final UserService _userService = UserService();
  ProfileView? _profile;
  bool _isLoading = false;
  String? _error;

  ProfileView? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  String get imageUrl {
    if (_profile == null) return '';
    final url = _profile!.avatarUrl.trim();
    if (url == null || url.isEmpty) return '';
    return url;
  }

  Future<void> loadProfile() async {
    _isLoading = true;
    _error = null;
    try {
      _profile = await _userService.getProfileView();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
    }
  }
}
